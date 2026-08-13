import 'dart:async';
import 'package:project/utils/order_number.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project/models/invoice_model.dart';
import 'package:intl/intl.dart';

class BluetoothPrinterService {
  static BluetoothInfo? _connectedDevice;
  static bool _isConnected = false;

  /// Request Bluetooth permissions (required for Android 12+)
  static Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // For Android 12+ (API 31+), we need BLUETOOTH_SCAN and BLUETOOTH_CONNECT
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();

      if (bluetoothScan.isDenied || bluetoothConnect.isDenied) {
        debugPrint('Bluetooth permissions denied');
        return false;
      }

      if (bluetoothScan.isPermanentlyDenied || bluetoothConnect.isPermanentlyDenied) {
        debugPrint('Bluetooth permissions permanently denied');
        return false;
      }

      return bluetoothScan.isGranted && bluetoothConnect.isGranted;
    }
    return true; // iOS handles permissions differently
  }

  /// Check if Bluetooth is available
  static Future<bool> isBluetoothAvailable() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  /// Check if connected to a printer
  static bool get isConnected => _isConnected;

  /// Get connected device
  static BluetoothInfo? get connectedDevice => _connectedDevice;

  /// Get paired Bluetooth devices
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  /// Connect to a device
  static Future<bool> connect(BluetoothInfo device) async {
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAdress,
      );
      if (result) {
        _connectedDevice = device;
        _isConnected = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error connecting to Bluetooth device: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Disconnect from device
  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      _connectedDevice = null;
      _isConnected = false;
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Check connection status
  static Future<bool> checkConnection() async {
    _isConnected = await PrintBluetoothThermal.connectionStatus;
    return _isConnected;
  }

  /// Print invoice receipt
  static Future<bool> printInvoice(InvoiceData invoice) async {
    if (!await checkConnection()) {
      debugPrint('No printer connected');
      return false;
    }

    try {
      List<int> bytes = _generateReceiptBytes(invoice);
      final result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      debugPrint('Error printing: $e');
      return false;
    }
  }

  /// Generate ESC/POS receipt bytes for thermal printer
  static List<int> _generateReceiptBytes(InvoiceData invoice) {
    List<int> bytes = [];

    // ESC/POS commands
    const List<int> ESC_INIT = [0x1B, 0x40]; // Initialize printer
    const List<int> ESC_ALIGN_CENTER = [0x1B, 0x61, 0x01]; // Center align
    const List<int> ESC_ALIGN_LEFT = [0x1B, 0x61, 0x00]; // Left align
    const List<int> ESC_BOLD_ON = [0x1B, 0x45, 0x01]; // Bold on
    const List<int> ESC_BOLD_OFF = [0x1B, 0x45, 0x00]; // Bold off
    const List<int> ESC_DOUBLE_HEIGHT = [0x1B, 0x21, 0x10]; // Double height
    const List<int> ESC_NORMAL = [0x1B, 0x21, 0x00]; // Normal size
    const List<int> ESC_CUT = [0x1D, 0x56, 0x00]; // Full cut
    const List<int> LF = [0x0A]; // Line feed

    // Initialize printer
    bytes.addAll(ESC_INIT);

    // Format date
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(invoice.orderInfo.orderDate);
      formattedDate = DateFormat('dd/MM/yy hh:mm a').format(dateTime);
    } catch (e) {
      formattedDate = invoice.orderInfo.orderDate;
    }

    // Store Name (centered, bold, large)
    bytes.addAll(ESC_ALIGN_CENTER);
    bytes.addAll(ESC_BOLD_ON);
    bytes.addAll(ESC_DOUBLE_HEIGHT);
    bytes.addAll(_textToBytes(invoice.store.storeName.toUpperCase()));
    bytes.addAll(LF);
    bytes.addAll(ESC_NORMAL);
    bytes.addAll(ESC_BOLD_OFF);

    // Store Address
    if (invoice.store.address.isNotEmpty && invoice.store.address != 'N/A') {
      bytes.addAll(_textToBytes(invoice.store.address));
      bytes.addAll(LF);
    }

    // Store Phone
    bytes.addAll(_textToBytes('Ph: ${invoice.store.sellerMobile}'));
    bytes.addAll(LF);

    // Dashed line
    bytes.addAll(_textToBytes('--------------------------------'));
    bytes.addAll(LF);

    // Order Info (center aligned)
    bytes.addAll(ESC_BOLD_ON);
    bytes.addAll(_textToBytes('Order ${formatOrderNumber(invoice.orderInfo.orderId)}'));
    bytes.addAll(LF);
    bytes.addAll(ESC_BOLD_OFF);

    bytes.addAll(_textToBytes(formattedDate));
    bytes.addAll(LF);

    bytes.addAll(_textToBytes('Pay: ${invoice.orderInfo.paymentMethod}'));
    bytes.addAll(LF);

    // Dashed line
    bytes.addAll(_textToBytes('--------------------------------'));
    bytes.addAll(LF);

    // Customer Info (center aligned, 60% width = ~19 chars)
    const int maxWidth = 19; // 60% of 32 characters

    bytes.addAll(ESC_BOLD_ON);
    String customerName = invoice.customer.name;
    if (customerName.length > maxWidth) {
      customerName = '${customerName.substring(0, maxWidth - 2)}..';
    }
    bytes.addAll(_textToBytes('Customer: $customerName'));
    bytes.addAll(LF);
    bytes.addAll(ESC_BOLD_OFF);

    bytes.addAll(_textToBytes('Ph: ${invoice.customer.mobile}'));
    bytes.addAll(LF);

    if (invoice.customer.address.isNotEmpty) {
      // Wrap address to 60% width
      String address = invoice.customer.address;
      while (address.isNotEmpty) {
        if (address.length <= maxWidth) {
          bytes.addAll(_textToBytes(address));
          bytes.addAll(LF);
          break;
        } else {
          // Find last space within maxWidth to break at word boundary
          int breakPoint = address.lastIndexOf(' ', maxWidth);
          if (breakPoint == -1) breakPoint = maxWidth;
          bytes.addAll(_textToBytes(address.substring(0, breakPoint)));
          bytes.addAll(LF);
          address = address.substring(breakPoint).trimLeft();
        }
      }
    }

    // Order Note (if available)
    if (invoice.notes.orderNote.isNotEmpty) {
      bytes.addAll(_textToBytes('--------------------------------'));
      bytes.addAll(LF);

      bytes.addAll(ESC_BOLD_ON);
      bytes.addAll(_textToBytes('Order Note:'));
      bytes.addAll(LF);
      bytes.addAll(ESC_BOLD_OFF);

      // Wrap order note to fit paper width (32 chars)
      String note = invoice.notes.orderNote;
      const int noteMaxWidth = 32;
      int lineCount = 0;
      while (note.isNotEmpty && lineCount < 4) {
        if (note.length <= noteMaxWidth) {
          bytes.addAll(_textToBytes(note));
          bytes.addAll(LF);
          break;
        } else {
          int breakPoint = note.lastIndexOf(' ', noteMaxWidth);
          if (breakPoint == -1) breakPoint = noteMaxWidth;
          bytes.addAll(_textToBytes(note.substring(0, breakPoint)));
          bytes.addAll(LF);
          note = note.substring(breakPoint).trimLeft();
          lineCount++;
        }
      }
    }

    // Dashed line
    bytes.addAll(_textToBytes('--------------------------------'));
    bytes.addAll(LF);

    // Items Header
    bytes.addAll(ESC_BOLD_ON);
    bytes.addAll(_textToBytes('ITEM              QTY    AMT'));
    bytes.addAll(LF);
    bytes.addAll(ESC_BOLD_OFF);

    // Items
    for (var item in invoice.items) {
      String itemName = item.productName;
      if (itemName.length > 16) {
        itemName = '${itemName.substring(0, 14)}..';
      }

      String qty = item.quantity.toString().padLeft(3);
      String amount = 'Rs.${item.subTotal.toStringAsFixed(2)}';

      bytes.addAll(_textToBytes(itemName.padRight(16) + qty.padLeft(4) + amount.padLeft(10)));
      bytes.addAll(LF);

      if (item.variantName.isNotEmpty) {
        bytes.addAll(_textToBytes('  ${item.variantName}'));
        bytes.addAll(LF);
      }
    }

    // Dashed line
    bytes.addAll(_textToBytes('--------------------------------'));
    bytes.addAll(LF);

    // Totals - customer-facing: just sub total and grand total from items
    double subTotal = 0;
    for (final item in invoice.items) {
      subTotal += item.subTotal;
    }
    bytes.addAll(_buildTotalLineBytes('Sub Total', subTotal));

    // Double line
    bytes.addAll(_textToBytes('================================'));
    bytes.addAll(LF);

    // Grand Total
    bytes.addAll(ESC_BOLD_ON);
    bytes.addAll(_textToBytes('GRAND TOTAL'.padRight(20) + 'Rs.${subTotal.toStringAsFixed(2)}'.padLeft(12)));
    bytes.addAll(LF);
    bytes.addAll(ESC_BOLD_OFF);

    // Double line
    bytes.addAll(_textToBytes('================================'));
    bytes.addAll(LF);

    // Footer
    bytes.addAll(ESC_ALIGN_CENTER);
    if (invoice.footer.message.isNotEmpty) {
      bytes.addAll(ESC_BOLD_ON);
      bytes.addAll(_textToBytes(invoice.footer.message));
      bytes.addAll(LF);
      bytes.addAll(ESC_BOLD_OFF);
    }

    if (invoice.footer.tagline.isNotEmpty) {
      bytes.addAll(_textToBytes(invoice.footer.tagline));
      bytes.addAll(LF);
    }

    // App name
    bytes.addAll(_textToBytes('--- ${invoice.store.appName} ---'));
    bytes.addAll(LF);

    // Feed paper
    bytes.addAll(LF);
    bytes.addAll(LF);
    bytes.addAll(LF);

    // Cut paper (if supported)
    bytes.addAll(ESC_CUT);

    return bytes;
  }

  static List<int> _textToBytes(String text) {
    return text.codeUnits;
  }

  static List<int> _buildTotalLineBytes(String label, double amount) {
    final isNegative = amount < 0;
    final amountStr = '${isNegative ? "-" : ""}Rs.${amount.abs().toStringAsFixed(2)}';
    List<int> bytes = [];
    bytes.addAll(_textToBytes(label.padRight(20) + amountStr.padLeft(12)));
    bytes.addAll([0x0A]); // LF
    return bytes;
  }

  /// Show Bluetooth printer selection dialog
  static Future<bool> showPrinterSelectionAndPrint(
    BuildContext context,
    InvoiceData invoice,
  ) async {
    // Request Bluetooth permissions first
    final hasPermissions = await requestBluetoothPermissions();
    if (!hasPermissions) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions required. Please enable in Settings.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        // Open app settings so user can grant permissions
        await openAppSettings();
      }
      return false;
    }

    // Check Bluetooth availability
    if (!await isBluetoothAvailable()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on Bluetooth'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    // If already connected, print directly
    if (await checkConnection()) {
      final result = await printInvoice(invoice);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ? 'Invoice printed successfully' : 'Failed to print invoice'),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
      return result;
    }

    // Show device selection dialog
    if (context.mounted) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _BluetoothDeviceSelector(
          onDeviceSelected: (device) async {
            final connected = await connect(device);
            if (connected) {
              final printed = await printInvoice(invoice);
              if (context.mounted) {
                Navigator.pop(context, printed);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(printed ? 'Invoice printed successfully' : 'Failed to print invoice'),
                    backgroundColor: printed ? Colors.green : Colors.red,
                  ),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to connect to printer'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
      return result ?? false;
    }

    return false;
  }
}

/// Bluetooth device selection widget
class _BluetoothDeviceSelector extends StatefulWidget {
  final Function(BluetoothInfo) onDeviceSelected;

  const _BluetoothDeviceSelector({required this.onDeviceSelected});

  @override
  State<_BluetoothDeviceSelector> createState() => _BluetoothDeviceSelectorState();
}

class _BluetoothDeviceSelectorState extends State<_BluetoothDeviceSelector> {
  List<BluetoothInfo> _devices = [];
  bool _isLoading = true;
  String? _connectingDeviceMac; // Track which specific device is connecting

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
  }

  void _loadPairedDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devices = await BluetoothPrinterService.getPairedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading paired devices: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Bluetooth Printer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadPairedDevices,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Info text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Make sure your printer is paired in Bluetooth settings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Device list
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLoading
                              ? 'Loading paired devices...'
                              : 'No paired printers found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (!_isLoading) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Pair your printer in Bluetooth settings first',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _loadPairedDevices,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isThisDeviceConnecting = _connectingDeviceMac == device.macAdress;
                      final isAnyDeviceConnecting = _connectingDeviceMac != null;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isAnyDeviceConnecting
                              ? null
                              : () async {
                                  setState(() {
                                    _connectingDeviceMac = device.macAdress;
                                  });
                                  widget.onDeviceSelected(device);
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.print,
                                  color: const Color(0xFF9AC444),
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  device.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  device.macAdress,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isThisDeviceConnecting) ...[
                                  const SizedBox(height: 8),
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
