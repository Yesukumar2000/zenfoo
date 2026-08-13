import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/delivery_boy_locations_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class DeliveryBoysMapScreen extends StatefulWidget {
  const DeliveryBoysMapScreen({super.key});

  @override
  State<DeliveryBoysMapScreen> createState() => _DeliveryBoysMapScreenState();
}

class _DeliveryBoysMapScreenState extends State<DeliveryBoysMapScreen> {
  late DeliveryBoyLocationsProvider _locationsProvider;

  @override
  void initState() {
    super.initState();
    _locationsProvider =
        Provider.of<DeliveryBoyLocationsProvider>(context, listen: false);

    // Start listening to delivery boy locations
    _locationsProvider.startListeningToLocations();
  }

  @override
  void dispose() {
    _locationsProvider.stopListening();
    super.dispose();
  }

  void _showDeliveryBoyDetails(dynamic location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Boy Details',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ID', location.deliveryBoyId.toString()),
            _buildDetailRow('Name', location.name),
            _buildDetailRow('Phone', location.phone ?? 'N/A'),
            _buildDetailRow('Status', location.status ?? 'Unknown'),
            _buildDetailRow(
              'Location',
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            ),
            _buildDetailRow(
              'Last Updated',
              _formatTime(location.updatedAt),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Boys Map'),
        elevation: 0,
      ),
      body: Consumer<DeliveryBoyLocationsProvider>(
        builder: (context, locationsProvider, _) {
          if (locationsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (locationsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${locationsProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        locationsProvider.startListeningToLocations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (locationsProvider.deliveryBoyLocations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off,
                      color: Colors.grey[400], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No delivery boys with active locations',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${locationsProvider.deliveryBoyLocations.length} Delivery Boys Active',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // List of delivery boys
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      locationsProvider.deliveryBoyLocations.length,
                  itemBuilder: (context, index) {
                    final location =
                        locationsProvider.deliveryBoyLocations[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        location.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: Chip(
                        label: Text(
                          location.status ?? 'Unknown',
                          style: GoogleFonts.inter(fontSize: 10),
                        ),
                      ),
                      onTap: () => _showDeliveryBoyDetails(location),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
