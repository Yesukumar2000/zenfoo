import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/screens/location_picker_screen.dart';

class PersonalDetailsStep extends StatefulWidget {
  final Function(Future<bool> Function())? onSaveCallback;

  const PersonalDetailsStep({
    super.key,
    this.onSaveCallback,
  });

  @override
  State<PersonalDetailsStep> createState() => _PersonalDetailsStepState();
}

class _PersonalDetailsStepState extends State<PersonalDetailsStep> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();

  // Location data
  double? latitude;
  double? longitude;
  String? city;
  String? state;
  String? pincode;
  String? buildingName;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Pass the save function to parent
    widget.onSaveCallback?.call(savePersonalDetails);
  }

  Future<void> _loadUserData() async {
    final userData = await LocalStorage.getUserData();
    final deliveryBoyData = await LocalStorage.getDeliveryBoyData();

    if (mounted) {
      setState(() {
        // Load mobile from user data
        mobileController.text = userData?['mobile']?.toString() ?? '';

        // Load existing delivery boy data if available
        if (deliveryBoyData != null) {
          final name = deliveryBoyData['name']?.toString() ?? '';
          // Only set name if it's not the mobile number
          if (name != mobileController.text) {
            nameController.text = name;
          }
          emailController.text = deliveryBoyData['email']?.toString() ?? '';
          dobController.text = deliveryBoyData['dob']?.toString() ?? '';
          addressController.text = deliveryBoyData['address']?.toString() ?? '';

          final lat = deliveryBoyData['latitude'];
          final lng = deliveryBoyData['longitude'];
          debugPrint('🔍 Loading from storage - lat: $lat, lng: $lng');
          if (lat != null) {
            latitude = double.tryParse(lat.toString());
            debugPrint('📍 Loaded latitude: $latitude');
          }
          if (lng != null) {
            longitude = double.tryParse(lng.toString());
            debugPrint('📍 Loaded longitude: $longitude');
          }
        }
      });
    }
  }

  Future<bool> savePersonalDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    final authProvider = context.read<AuthProvider>();

    // Convert DOB from DD/MM/YYYY to YYYY-MM-DD
    String? formattedDob;
    if (dobController.text.isNotEmpty) {
      try {
        final parts = dobController.text.split('/');
        if (parts.length == 3) {
          formattedDob =
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      } catch (e) {
        debugPrint('Error formatting DOB: $e');
      }
    }

    debugPrint(
        '💾 Saving personal details with lat: $latitude, lng: $longitude');

    await authProvider.updatePersonalDetails(
      name: nameController.text.trim(),
      email: emailController.text.trim().isEmpty
          ? null
          : emailController.text.trim(),
      dob: formattedDob,
      address: addressController.text.trim(),
      latitude: latitude,
      longitude: longitude,
    );

    return isStatusSuccess(authProvider.updatePersonalDetailsState.status);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    mobileController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// INFO TEXT
            Text(
              "Please fill your basic details.",
              style: textTheme.headlineSmall,
            ),

            const SizedBox(height: AppDimensions.marginLarge),

            CustomTextFormField(
              title: "Name",
              hintText: "Enter name",
              controller: nameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.marginMedium),

            CustomTextFormField(
              title: "Email Address",
              hintText: "Enter email address",
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.marginMedium),

            CustomTextFormField(
              title: "Date of Birth",
              hintText: "DD / MM / YYYY",
              controller: dobController,
              readOnly: true,
              suffixIcon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar01),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  initialDate: DateTime(2000, 1, 1),
                );

                if (pickedDate != null) {
                  dobController.text =
                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                }
              },
            ),

            const SizedBox(height: AppDimensions.marginMedium),

            CustomTextFormField(
              title: "Mobile Number",
              hintText: "Enter mobile number",
              controller: mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedCall),
              readOnly: true,
              enabled: false,
            ),

            const SizedBox(height: AppDimensions.marginMedium),

            CustomTextFormField(
              title: "Address",
              hintText: "Select address",
              controller: addressController,
              readOnly: true,
              suffixIcon: HugeIcon(icon: HugeIcons.strokeRoundedLocation01),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select an address';
                }
                return null;
              },
              onTap: () async {
                // Open map / address picker
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationPickerScreen(),
                  ),
                );

                if (result != null && mounted) {
                  setState(() {
                    latitude = result['latitude'];
                    longitude = result['longitude'];
                    addressController.text = result['address'] ?? '';
                    city = result['city'];
                    state = result['state'];
                    pincode = result['pincode'];
                    buildingName = result['building_name'];
                  });

                  debugPrint('Selected Location:');
                  debugPrint('Lat: $latitude, Lng: $longitude');
                  debugPrint('Address: ${addressController.text}');
                  debugPrint('City: $city, State: $state, Pincode: $pincode');
                  debugPrint('Building: $buildingName');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
