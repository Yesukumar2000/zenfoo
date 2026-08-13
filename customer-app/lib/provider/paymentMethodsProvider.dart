import 'package:project/helper/utils/generalImports.dart';

// Enhanced Payment Methods Provider with saved cards and wallet support
class PaymentMethodsProvider extends ChangeNotifier {
  PaymentMethodsState paymentMethodsState = PaymentMethodsState.loading;

  //Payment methods variables
  PaymentMethods? paymentMethods;
  PaymentMethodsData? paymentMethodsData;
  String selectedPaymentMethod = "";
  String isCodAllowed = "1";
  String message = "";

  // Saved Cards & UPI
  List<SavedCard> savedCards = [];
  List<SavedUPI> savedUPIs = [];
  String selectedCardId = "";
  String selectedUPIId = "";

  // Wallet balance
  double walletBalance = 0.0;
  bool useWallet = false;

  Future getPaymentMethods({
    required BuildContext context,
    required String from,
  }) async {
    try {
      Map<String, dynamic> getPaymentMethodsSettings =
          (await getPaymentMethodsSettingsApi(context: context, params: {}));

      if (getPaymentMethodsSettings[ApiAndParams.status].toString() == "1") {
        List<int> decodedBytes = base64
            .decode(getPaymentMethodsSettings[ApiAndParams.data].toString());
        String decodedString = utf8.decode(decodedBytes);
        Map<String, dynamic> map = json.decode(decodedString);
        getPaymentMethodsSettings[ApiAndParams.data] = map;

        paymentMethods = PaymentMethods.fromJson(getPaymentMethodsSettings);
        paymentMethodsData = paymentMethods?.data;

        log("paymentMethodsData: ${paymentMethodsData?.toJson()}");

        // Set default payment method
        if (paymentMethodsData?.codPaymentMethod.toString() == "1" &&
            isCodAllowed == "1") {
          setSelectedPaymentMethod("COD");
        } else if (paymentMethodsData?.razorpayPaymentMethod.toString() ==
            "1") {
          // Don't auto-select Razorpay, let user choose UPI app
        } else if (paymentMethodsData?.stripePaymentMethod.toString() == "1") {
          setSelectedPaymentMethod("Stripe");
        }

        paymentMethodsState = PaymentMethodsState.loaded;

        // Fetch installed UPI apps for Razorpay
        if (paymentMethodsData?.razorpayPaymentMethod.toString() == "1") {
          await fetchInstalledUpiApps();
          await fetchSavedPaymentMethods();
        }

        notifyListeners();
      } else {
        showMessage(context, message, MessageType.warning);
        paymentMethodsState = PaymentMethodsState.error;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      showMessage(context, message, MessageType.warning);
      paymentMethodsState = PaymentMethodsState.error;
      notifyListeners();
    }
  }

  String selectedUpiApp = "";

  // PhonePe SDK specific variables
  String selectedPhonePeUpiApp = "";
  bool isPhonePeSDKInitialized = false;

  // Known UPI app package names with display names
  final Map<String, String> knownUpiApps = {
    'com.google.android.apps.nbu.paisa.user': 'Google Pay',
    'com.phonepe.app': 'PhonePe',
    'net.one97.paytm': 'Paytm',
    'in.org.npci.upiapp': 'BHIM',
    'com.dreamplug.androidapp': 'CRED',
    'in.amazon.mShop.android.shopping': 'Amazon Pay',
    'com.whatsapp': 'WhatsApp',
    'com.freecharge.android': 'Freecharge',
    'com.mobikwik_new': 'MobiKwik',
  };

  List<UpiAppInfo> upiApps = [];

  Future<void> fetchInstalledUpiApps() async {
    log("Attempting to fetch installed UPI apps.");
    notifyListeners();

    try {
      // dynamic installedApps = await Razorpay().getAppsWhichSupportUpi();
      dynamic installedApps = {}; // Disabled Razorpay
      // log("Raw installed apps response: $installedApps");

      upiApps = [];

      if (installedApps is Map) {
        installedApps.forEach((packageName, appName) {
          final String pkgName = packageName.toString();
          final String name = appName.toString();

          if (knownUpiApps.containsKey(pkgName)) {
            upiApps.add(UpiAppInfo(
              packageName: pkgName,
              name: knownUpiApps[pkgName]!,
            ));
            log("Found known UPI app: ${knownUpiApps[pkgName]} ($pkgName)");
          } else {
            upiApps.add(UpiAppInfo(
              packageName: pkgName,
              name: name,
            ));
            log("Found UPI app: $name ($pkgName)");
          }
        });
      } else if (installedApps is List) {
        for (var app in installedApps) {
          String packageName = "";
          String appName = "";

          if (app is Map) {
            packageName = app['packageName']?.toString() ?? "";
            appName = app['name']?.toString() ?? "";
          } else if (app is String) {
            packageName = app;
            appName = knownUpiApps[app] ?? app;
          }

          if (packageName.isNotEmpty) {
            upiApps.add(UpiAppInfo(
              packageName: packageName,
              name: appName,
            ));
            log("Found UPI app: $appName ($packageName)");
          }
        }
      }

      // Sort by priority
      upiApps.sort((a, b) {
        const priority = [
          'com.google.android.apps.nbu.paisa.user',
          'com.phonepe.app',
          'net.one97.paytm',
          'in.org.npci.upiapp',
        ];

        int aIndex = priority.indexOf(a.packageName);
        int bIndex = priority.indexOf(b.packageName);

        if (aIndex == -1) aIndex = 999;
        if (bIndex == -1) bIndex = 999;

        return aIndex.compareTo(bIndex);
      });

      log("Successfully identified ${upiApps.length} UPI apps.");
    } catch (e) {
      log("Error fetching UPI apps: $e");
    } finally {
      notifyListeners();
    }
  }

  // Detect installed UPI apps using canLaunchUrl (no PhonePe SDK needed)
  Future<void> fetchPhonePeUpiApps() async {
    debugPrint("📱 [UPI] fetchPhonePeUpiApps() - detecting via canLaunchUrl");

    // Known UPI apps with their URI schemes for detection
    const List<Map<String, String>> _knownUpiAppSchemes = [
      {'packageName': 'com.google.android.apps.nbu.paisa.user', 'scheme': 'tez://upi/pay', 'name': 'Google Pay'},
      {'packageName': 'com.phonepe.app', 'scheme': 'phonepe://pay', 'name': 'PhonePe'},
      {'packageName': 'net.one97.paytm', 'scheme': 'paytmmp://pay', 'name': 'Paytm'},
      {'packageName': 'in.org.npci.upiapp', 'scheme': 'upi://pay', 'name': 'BHIM'},
      {'packageName': 'com.dreamplug.androidapp', 'scheme': 'credpay://upi/pay', 'name': 'CRED'},
      {'packageName': 'in.amazon.mShop.android.shopping', 'scheme': 'upi://pay', 'name': 'Amazon Pay'},
    ];

    final List<UpiAppInfo> detectedApps = [];

    for (final appInfo in _knownUpiAppSchemes) {
      try {
        final uri = Uri.tryParse(appInfo['scheme']!);
        if (uri != null && await canLaunchUrl(uri)) {
          detectedApps.add(UpiAppInfo(
            packageName: appInfo['packageName']!,
            name: appInfo['name']!,
          ));
          log("✅ UPI app detected: ${appInfo['name']} (${appInfo['packageName']})");
        }
      } catch (_) {}
    }

    if (detectedApps.isNotEmpty) {
      upiApps = detectedApps;
    }
    // If nothing detected, leave upiApps empty → widget will use fallback list

    log("UPI apps detected: ${upiApps.length}");
    notifyListeners();
  }

  // Fetch saved payment methods (cards, UPI IDs)
  Future<void> fetchSavedPaymentMethods() async {
    // Mock data - replace with actual API call
    savedUPIs = [
      // SavedUPI(id: "1", upiId: "loremipsum@okicic"),
      // SavedUPI(id: "2", upiId: "96465457458@okicic"),
    ];

    savedCards = [
      // SavedCard(id: "1", last4: "4242", brand: "Visa"),
      // SavedCard(id: "2", last4: "5555", brand: "Mastercard"),
    ];

    // Mock wallet balance - replace with actual API
    walletBalance = 500.0;

    notifyListeners();
  }

  Future setSelectedPaymentMethod(String method) async {
    selectedPaymentMethod = method;
    // Clear other selections
    if (method != "Razorpay") {
      selectedUpiApp = "";
    }
    if (method != "SavedCard") {
      selectedCardId = "";
    }
    if (method != "SavedUPI") {
      selectedUPIId = "";
    }
    notifyListeners();
  }

  void setSelectedUpiApp(String appPackage) {
    selectedUpiApp = appPackage;
    selectedPaymentMethod = "Razorpay";
    notifyListeners();
  }

  void setSelectedPhonePeUpiApp(String appPackage) {
    selectedPhonePeUpiApp = appPackage;
    selectedPaymentMethod = "Phonepe";
    notifyListeners();
  }

  void setSelectedCard(String cardId) {
    selectedCardId = cardId;
    selectedPaymentMethod = "SavedCard";
    notifyListeners();
  }

  void setSelectedUPI(String upiId) {
    selectedUPIId = upiId;
    selectedPaymentMethod = "SavedUPI";
    notifyListeners();
  }

  void toggleWallet(bool value) {
    useWallet = value;
    notifyListeners();
  }

  // Show add UPI dialog
  Future<void> showAddUPIDialog(BuildContext context) async {
    final TextEditingController upiController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add UPI ID'),
        content: TextField(
          controller: upiController,
          decoration: InputDecoration(
            hintText: 'Enter UPI ID (e.g., user@paytm)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (upiController.text.isNotEmpty) {
                savedUPIs.add(SavedUPI(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  upiId: upiController.text,
                ));
                notifyListeners();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // Show add card dialog
  Future<void> showAddCardDialog(BuildContext context) async {
    // This would typically open a Razorpay card entry form
    // For now, show a placeholder
    showMessage(
        context, "Card entry form would open here", MessageType.success);
  }

  // Show netbanking list
  Future<void> showNetbankingOptions(BuildContext context) async {
    final banks = [
      'HDFC Bank',
      'ICICI Bank',
      'SBI',
      'Axis Bank',
      'Kotak Bank',
      'Punjab National Bank',
      'Bank of Baroda',
      'Canara Bank'
    ];

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Your Bank',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            ...banks
                .map((bank) => ListTile(
                      leading: Icon(Icons.account_balance),
                      title: Text(bank),
                      onTap: () {
                        setSelectedPaymentMethod("Netbanking_$bank");
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}

// Models
class SavedCard {
  final String id;
  final String last4;
  final String brand;

  SavedCard({required this.id, required this.last4, required this.brand});
}

class SavedUPI {
  final String id;
  final String upiId;

  SavedUPI({required this.id, required this.upiId});
}

// import 'package:project/helper/utils/generalImports.dart';

enum PaymentMethodsState {
  loading,
  loaded,
  empty,
  error,
}

// // Simple UPI app model
class UpiAppInfo {
  final String packageName;
  final String name;
  final Uint8List? icon;

  UpiAppInfo({
    required this.packageName,
    required this.name,
    this.icon,
  });
}

// class PaymentMethodsProvider extends ChangeNotifier {
//   PaymentMethodsState paymentMethodsState = PaymentMethodsState.loading;

//   //Payment methods variables
//   PaymentMethods? paymentMethods;
//   PaymentMethodsData? paymentMethodsData;
//   String selectedPaymentMethod = "";
//   String isCodAllowed = "1";
//   String message = "";

//   Future getPaymentMethods({
//     required BuildContext context,
//     required String from,
//   }) async {
//     try {
//       Map<String, dynamic> getPaymentMethodsSettings =
//           (await getPaymentMethodsSettingsApi(context: context, params: {}));

//       if (getPaymentMethodsSettings[ApiAndParams.status].toString() == "1") {
//         List<int> decodedBytes = base64
//             .decode(getPaymentMethodsSettings[ApiAndParams.data].toString());
//         String decodedString = utf8.decode(decodedBytes);
//         Map<String, dynamic> map = json.decode(decodedString);
//         getPaymentMethodsSettings[ApiAndParams.data] = map;

//         paymentMethods = PaymentMethods.fromJson(getPaymentMethodsSettings);
//         paymentMethodsData = paymentMethods?.data;

//         log("paymentMethodsData: ${paymentMethodsData?.toJson()}");

//         if (paymentMethodsData?.codPaymentMethod.toString() == "1" &&
//             isCodAllowed == "1") {
//           setSelectedPaymentMethod("COD");
//         } else if (paymentMethodsData?.paytabsPaymentMethod.toString() == "1") {
//           setSelectedPaymentMethod("Paytabs");
//         } else if (paymentMethodsData?.midtransPaymentMethod.toString() ==
//             "1") {
//           setSelectedPaymentMethod("Midtrans");
//         } else if (paymentMethodsData?.cashfreePaymentMethod.toString() ==
//             "1") {
//           setSelectedPaymentMethod("Cashfree");
//         } else if (paymentMethodsData?.phonePePaymentMethod.toString() == "1") {
//           setSelectedPaymentMethod("Phonepe");
//         } else if (paymentMethodsData?.razorpayPaymentMethod.toString() ==
//             "1") {
//           setSelectedPaymentMethod("Razorpay");
//         } else if (paymentMethodsData?.paystackPaymentMethod.toString() ==
//             "1") {
//           setSelectedPaymentMethod("Paystack");
//         } else if (paymentMethodsData?.stripePaymentMethod.toString() == "1") {
//           setSelectedPaymentMethod("Stripe");
//         } else if (paymentMethodsData?.paytmPaymentMethod.toString() == "1") {
//           setSelectedPaymentMethod("Paytm");
//         } else if (paymentMethodsData?.paypalPaymentMethod.toString() == "1") {
//           setSelectedPaymentMethod("Paypal");
//         }

//         paymentMethodsState = PaymentMethodsState.loaded;

//         // Fetch installed UPI apps for Razorpay
//         if (paymentMethodsData?.razorpayPaymentMethod.toString() == "1") {
//           fetchInstalledUpiApps();
//         }

//         notifyListeners();
//       } else {
//         showMessage(
//           context,
//           message,
//           MessageType.warning,
//         );
//         paymentMethodsState = PaymentMethodsState.error;
//         notifyListeners();
//       }
//     } catch (e) {
//       message = e.toString();
//       showMessage(
//         context,
//         message,
//         MessageType.warning,
//       );
//       paymentMethodsState = PaymentMethodsState.error;
//       notifyListeners();
//     }
//   }

//   String selectedUpiApp = "";

//   // Known UPI app package names with display names
//   final Map<String, String> knownUpiApps = {
//     'com.google.android.apps.nbu.paisa.user': 'Google Pay',
//     'com.phonepe.app': 'PhonePe',
//     'net.one97.paytm': 'Paytm',
//     'in.org.npci.upiapp': 'BHIM',
//     'com.dreamplug.androidapp': 'CRED',
//     'in.amazon.mShop.android.shopping': 'Amazon Pay',
//     'com.whatsapp': 'WhatsApp',
//     'com.freecharge.android': 'Freecharge',
//     'com.mobikwik_new': 'MobiKwik',
//   };

//   List<UpiAppInfo> upiApps = [];

//   Future<void> fetchInstalledUpiApps() async {
//     log("Attempting to fetch installed UPI apps.");
//     // isLoading = true;
//     notifyListeners();

//     try {
//       dynamic installedApps = await Razorpay().getAppsWhichSupportUpi();
//       log("Raw installed apps response: $installedApps");

//       upiApps = [];

//       // Handle Map response format (your case)
//       if (installedApps is Map) {
//         installedApps.forEach((packageName, appName) {
//           final String pkgName = packageName.toString();
//           final String name = appName.toString();

//           // Check if it's a known UPI app
//           if (knownUpiApps.containsKey(pkgName)) {
//             upiApps.add(UpiAppInfo(
//               packageName: pkgName,
//               name: knownUpiApps[pkgName]!,
//             ));
//             log("Found known UPI app: ${knownUpiApps[pkgName]} ($pkgName)");
//           } else {
//             // Add unknown apps as well
//             upiApps.add(UpiAppInfo(
//               packageName: pkgName,
//               name: name,
//             ));
//             log("Found UPI app: $name ($pkgName)");
//           }
//         });
//       }
//       // Handle List response format (alternative)
//       else if (installedApps is List) {
//         for (var app in installedApps) {
//           String packageName = "";
//           String appName = "";

//           if (app is Map) {
//             packageName = app['packageName']?.toString() ?? "";
//             appName = app['name']?.toString() ?? "";
//           } else if (app is String) {
//             packageName = app;
//             appName = knownUpiApps[app] ?? app;
//           }

//           if (packageName.isNotEmpty) {
//             upiApps.add(UpiAppInfo(
//               packageName: packageName,
//               name: appName,
//             ));
//             log("Found UPI app: $appName ($packageName)");
//           }
//         }
//       }

//       // Sort by priority (Google Pay, PhonePe first)
//       upiApps.sort((a, b) {
//         const priority = [
//           'com.google.android.apps.nbu.paisa.user',
//           'com.phonepe.app',
//           'net.one97.paytm',
//           'in.org.npci.upiapp',
//         ];

//         int aIndex = priority.indexOf(a.packageName);
//         int bIndex = priority.indexOf(b.packageName);

//         if (aIndex == -1) aIndex = 999;
//         if (bIndex == -1) bIndex = 999;

//         return aIndex.compareTo(bIndex);
//       });

//       log("Successfully identified ${upiApps.length} UPI apps.");
//     } catch (e) {
//       log("Error fetching UPI apps: $e");
//     } finally {
//       // isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future setSelectedPaymentMethod(String method) async {
//     selectedPaymentMethod = method;
//     notifyListeners();
//   }

//   void setSelectedUpiApp(String appPackage) {
//     selectedUpiApp = appPackage;
//     notifyListeners();
//   }
// }
