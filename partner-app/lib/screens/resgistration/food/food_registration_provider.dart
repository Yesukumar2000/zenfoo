import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:project/helper/utils/generalImports.dart' hide log;
import 'package:project/screens/mainScreen/bottom_nav_provider.dart';
import 'package:project/screens/mainScreen/main_tab_scaffold.dart';
import 'package:project/screens/resgistration/food/signature_canvas.dart';

class FoodRegistrationProvider extends ChangeNotifier {
  final BuildContext context;
  final String? storeId;

  FoodRegistrationProvider(this.context, {this.storeId}) {
    fetchSellerData(storeId: storeId);
    // Categories will be fetched from the store type in fetchCategoriesFromStoreType
    if (storeId != null && storeId!.isNotEmpty) {
      fetchCategoriesFromStoreType(storeId!);
    }
  }

  // Loading state
  bool isLoading = false;
  String errorMessage = '';

  // Error tracking
  bool hasError = false;

  // Seller's actual store ID from the registration API (null for new users)
  String? sellerStoreId;

  // Image URLs from server
  String? aadharImageUrl;
  String? panImageUrl;
  String? fssaiImageUrl;
  String? logoImageUrl;
  List<String> storeImageUrls = [];

  // Agreement
  int agreementStatus = 0;
  String? agreementPdfUrl;
  bool isDownloadingAgreement = false;
  bool isUploadingAgreement = false;

  // Vendor GST applicable to this seller (admin-configured per store category)
  double? vendorGstPercent;
  String? vendorGstCategory;

  // Vendor commission applicable to this seller (admin-configured per store category)
  double? vendorCommissionPercent;
  String? vendorCommissionCategory;

  // Drives the "Sign Digitally" canvas. Custom DrawingController (see
  // signature_canvas.dart) instead of the `signature` package so we can
  // offer a pen, an eraser, variable thickness and undo/redo. White
  // background because the signed agreement is rendered on white.
  final DrawingController signatureController = DrawingController(
    penColor: Colors.black,
    penWidth: 2.5,
    eraserWidth: 22,
    backgroundColor: Colors.white,
  );

  // True only after the user submits a signature in the current session.
  // Used to gate the "View Signed Agreement" button so it stays disabled
  // on initial load and lights up after a successful submission.
  bool justSubmittedSignature = false;

  /// True once the user has drawn at least one stroke. Drives the live
  /// enabled-state of the Clear / Undo / Submit buttons.
  bool get hasSignature => signatureController.isNotEmpty;

  void clearSignature() {
    signatureController.clear();
    notifyListeners();
  }

  /// Removes only the most recent stroke so a small slip doesn't force the
  /// user to start the whole signature over.
  void undoSignature() {
    signatureController.undo();
    notifyListeners();
  }

  /// Restores the last undone stroke.
  void redoSignature() {
    signatureController.redo();
    notifyListeners();
  }

  /// Switches between the pen and the eraser.
  void setSignatureTool(DrawTool tool) {
    signatureController.setTool(tool);
    notifyListeners();
  }

  /// Sets the pen thickness (thin / medium / bold).
  void setSignaturePenWidth(double width) {
    signatureController.setPenWidth(width);
    notifyListeners();
  }

  DrawTool get signatureTool => signatureController.tool;

  Future<void> submitSignatureAsAgreement(BuildContext context) async {
    if (signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please draw your signature first'), backgroundColor: Colors.red),
      );
      return;
    }
    isUploadingAgreement = true;
    notifyListeners();
    try {
      final Uint8List? pngBytes = await signatureController.toPngBytes();
      if (pngBytes == null) {
        throw Exception('Could not capture signature');
      }

      // Server re-renders the official agreement template with the
      // signature embedded in the seller signature box. We only need to
      // send the raw PNG.
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signatureFile = File('${dir.path}/signature_$timestamp.png');
      await signatureFile.writeAsBytes(pngBytes);

      await uploadSignature(context, signatureFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      isUploadingAgreement = false;
      notifyListeners();
    }
  }

  Future<void> uploadSignature(BuildContext context, File signatureFile) async {
    final response = await sendApiMultiPartRequest(
      apiName: 'agreement/upload',
      params: {},
      filesMap: {'agreement_signature': signatureFile},
    );
    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No response from server'), backgroundColor: Colors.red),
      );
      return;
    }
    Map<String, dynamic> data;
    if (response is String) {
      data = json.decode(response);
    } else {
      data = response as Map<String, dynamic>;
    }
    if (data['success'] == true || data['status'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Agreement signed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      final responseData = data['data'];
      if (responseData is Map) {
        if (responseData['agreement_pdf_url'] != null) {
          agreementPdfUrl = responseData['agreement_pdf_url'].toString();
        }
        if (responseData['agreement_status'] != null) {
          agreementStatus =
              int.tryParse(responseData['agreement_status'].toString()) ?? 0;
        }
      }

      justSubmittedSignature = true;
      notifyListeners();

      await fetchSellerData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Failed to submit signature'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> downloadAgreement(BuildContext context) async {
    isDownloadingAgreement = true;
    notifyListeners();
    try {
      final responseBytes = await sendApiRequest(
        apiName: 'agreement/download',
        params: {},
        isPost: true,
        isRequestedForInvoice: true,
      );
      if (responseBytes != null && responseBytes is Uint8List) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/blank_agreement.pdf');
        await file.writeAsBytes(responseBytes);
        await OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download agreement'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      isDownloadingAgreement = false;
      notifyListeners();
    }
  }

  Future<void> uploadAgreement(BuildContext context, File pdfFile,
      {File? signatureFile}) async {
    isUploadingAgreement = true;
    notifyListeners();
    try {
      final Map<String, File> filesMap = {'agreement_pdf': pdfFile};
      if (signatureFile != null) {
        filesMap['agreement_signature'] = signatureFile;
      }
      final response = await sendApiMultiPartRequest(
        apiName: 'agreement/upload',
        params: {},
        filesMap: filesMap,
      );
      if (response != null) {
        Map<String, dynamic> data;
        if (response is String) {
          data = json.decode(response);
        } else {
          data = response as Map<String, dynamic>;
        }
        if (data['success'] == true || data['status'] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Agreement uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          final responseData = data['data'];
          if (responseData is Map) {
            if (responseData['agreement_pdf_url'] != null) {
              agreementPdfUrl = responseData['agreement_pdf_url'].toString();
            }
            if (responseData['agreement_status'] != null) {
              agreementStatus = int.tryParse(
                      responseData['agreement_status'].toString()) ??
                  0;
            }
            notifyListeners();
          }

          await fetchSellerData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to upload agreement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      isUploadingAgreement = false;
      notifyListeners();
    }
  }

  // Step management
  int stepIndex = 0;
  void goToStep(int i) {
    stepIndex = i;
    notifyListeners();
  }

  void nextStep() {
    if (stepIndex < 2) {
      stepIndex++;
      notifyListeners();
    }
  }

  void previousStep(BuildContext context) {
    if (stepIndex > 0) {
      stepIndex--;
      notifyListeners();
    }
    // Note: Logout handling when stepIndex == 0 is now handled in the UI layer
  }

  bool get isStep1Filled {
    return userNameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        // mobileController.text.isNotEmpty &&
        // passwordController.text.isNotEmpty &&
        // confirmPasswordController.text.isNotEmpty &&
        aadharFile != null &&
        panFile != null &&
        fassiFile != null;
  }

  bool get isStep2Filled {
    // Only check for categories if they are available
    bool categoriesValid =
        allCategories.isEmpty || selectedCategories.isNotEmpty;

    return storeLogo != null &&
        storeImages.isNotEmpty &&
        storeNameController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        location != null &&
        city != null &&
        categoriesValid && // Only require selection if categories are available
        taxNameController.text.isNotEmpty &&
        taxNumberController.text.isNotEmpty;
  }

  // Form keys — let the Next button light up every wrong field at once
  // instead of only surfacing the first error in a snackbar.
  final GlobalKey<FormState> step1FormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> step2FormKey = GlobalKey<FormState>();

  // Step-specific validation
  String? validateStep1() {
    // Name / email are left exactly as they were — only the document numbers
    // below carry the stricter, format-aware rules.
    if (userNameController.text.trim().isEmpty) {
      return "Please enter your name";
    }

    final emailError = validateEmail(emailController.text);
    if (emailError != null) return emailError;

    // Aadhaar and PAN are mandatory — their documents are mandatory too.
    final aadharError = AppValidators.aadhaar(aadharNumberController.text);
    if (aadharError != null) return aadharError;

    final panError = AppValidators.pan(panNumberController.text);
    if (panError != null) return panError;

    // FSSAI is optional (non-food stores don't have one), but if it is typed
    // it has to be a real 14-digit number.
    final fssaiError = AppValidators.fssai(fssaiNumberController.text);
    if (fssaiError != null) return fssaiError;

    if (aadharFile == null &&
        (aadharImageUrl == null || aadharImageUrl!.isEmpty)) {
      return "Please upload Aadhar card image";
    }
    if (panFile == null && (panImageUrl == null || panImageUrl!.isEmpty)) {
      return "Please upload PAN card image";
    }
    // FSSAI number entered means the certificate has to be attached.
    if (fssaiNumberController.text.trim().isNotEmpty &&
        fassiFile == null &&
        (fssaiImageUrl == null || fssaiImageUrl!.isEmpty)) {
      return "Please upload your FSSAI certificate";
    }
    return null;
  }

  String? validateStep2() {
    if (storeLogo == null && logoImageUrl == null) {
      return "Please upload store logo";
    }
    if (storeImages.isEmpty && storeImageUrls.isEmpty) {
      return "Please upload at least one store image";
    }
    final storeNameError = AppValidators.storeName(storeNameController.text);
    if (storeNameError != null) return storeNameError;

    final descriptionError =
        AppValidators.storeDescription(descriptionController.text);
    if (descriptionError != null) return descriptionError;

    if (location == null || location!.trim().isEmpty) {
      return "Please select store location";
    }
    if (latitude == null || longitude == null) {
      return "Please select store location with valid coordinates";
    }
    // if (city == null || city!.trim().isEmpty) {
    //   return "Please select city";
    // }
    // Only validate categories if they are available
    if (allCategories.isNotEmpty && selectedCategories.isEmpty) {
      return "Please select at least one category";
    }
    final taxNameError = AppValidators.gstBusinessName(taxNameController.text);
    if (taxNameError != null) return taxNameError;

    final gstinError = AppValidators.gstin(taxNumberController.text);
    if (gstinError != null) return gstinError;

    return null;
  }

  /// True when the GSTIN is complete but the PAN it contains is not the PAN
  /// entered in step 1. Not an error — a proprietor's GSTIN normally carries
  /// his own PAN, but a company GSTIN carries the company's — so this only
  /// drives an advisory note under the GSTIN field.
  bool get gstinPanMismatch {
    final panInGst = AppValidators.panInsideGstin(taxNumberController.text);
    final pan = panNumberController.text.trim().toUpperCase();
    if (panInGst == null || pan.length != 10) return false;
    return panInGst != pan;
  }

  bool _lastGstinMismatch = false;

  /// Called while the vendor types the GSTIN. Rebuilds only when the advisory
  /// actually appears or disappears, not on every keystroke.
  void refreshGstinHint() {
    final mismatch = gstinPanMismatch;
    if (mismatch != _lastGstinMismatch) {
      _lastGstinMismatch = mismatch;
      notifyListeners();
    }
  }

  /// Strips spaces/dashes the vendor may have typed, so the backend always
  /// receives a clean number.
  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  /// Validate email format (unchanged — personal info left as-is)
  String? validateEmail(String email) {
    if (email.trim().isEmpty) {
      return "Email cannot be empty";
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return "Please enter a valid email address";
    }
    return null;
  }

  /// Kept as thin wrappers so older call sites keep working.
  String? validateAadhar(String aadhar) => AppValidators.aadhaar(aadhar);

  String? validatePAN(String pan) => AppValidators.pan(pan);

  // Validation for all fields (used in final submission)
  String? validateAllFields() {
    final step1Error = validateStep1();
    if (step1Error != null) return step1Error;

    final step2Error = validateStep2();
    if (step2Error != null) return step2Error;

    return null; // All validations passed
  }

  // Step 1: Personal Info
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Document number controllers
  final TextEditingController aadharNumberController = TextEditingController();
  final TextEditingController panNumberController = TextEditingController();
  final TextEditingController fssaiNumberController = TextEditingController();

  File? aadharFile, panFile, fassiFile;
  void setAadharFile(File? file) {
    aadharFile = file;
    notifyListeners();
  }

  void setPanFile(File? file) {
    panFile = file;
    notifyListeners();
  }

  void setFassiFile(File? file) {
    fassiFile = file;
    notifyListeners();
  }

  void clearAadhar() {
    aadharFile = null;
    aadharImageUrl = null;
    notifyListeners();
  }

  void clearPan() {
    panFile = null;
    panImageUrl = null;
    notifyListeners();
  }

  void clearFassi() {
    fassiFile = null;
    fssaiImageUrl = null;
    notifyListeners();
  }

  // Step 2: Store Info
  File? storeLogo;
  List<File> storeImages = [];
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? location;
  String? city;
  double? latitude;
  double? longitude;
  final TextEditingController urlController = TextEditingController();
  final TextEditingController taxNameController = TextEditingController();
  final TextEditingController taxNumberController = TextEditingController();

  void setStoreLogo(File? file) {
    storeLogo = file;
    notifyListeners();
  }

  void clearStoreLogo() {
    storeLogo = null;
    logoImageUrl = null;
    notifyListeners();
  }

  void addStoreImages(List<File> files) {
    storeImages.addAll(files);
    notifyListeners();
  }

  void removeStoreImage(int idx) {
    storeImages.removeAt(idx);
    notifyListeners();
  }

  void removeStoreImageUrl(int idx) {
    if (idx >= 0 && idx < storeImageUrls.length) {
      storeImageUrls.removeAt(idx);
      notifyListeners();
    }
  }

  void selectCity(String? cityValue) {
    city = cityValue;
    notifyListeners();
  }

  // Toggle category selection
  void toggleCategory(CategoryModel category) {
    final index = selectedCategories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      selectedCategories.removeAt(index);
    } else {
      selectedCategories.add(category);
    }
    notifyListeners();
  }

  // Check if category is selected
  bool isCategorySelected(CategoryModel category) {
    return selectedCategories.any((c) => c.id == category.id);
  }

  // Select multiple categories at once
  void setSelectedCategories(List<CategoryModel> cats) {
    selectedCategories = cats;
    notifyListeners();
  }

  void setLocation(String value) {
    location = value;
    notifyListeners();
  }

  void setLocationData({
    required String address,
    required double lat,
    required double lng,
    String? cityName,
  }) {
    location = address;
    latitude = lat;
    longitude = lng;
    if (cityName != null && cityName.isNotEmpty) {
      city = cityName;
    }
    notifyListeners();
  }

  // API Data Fetching
  Future<void> fetchSellerData({String? storeId}) async {
    isLoading = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();

    try {
      // Fetch categories first so we can map IDs to names
      if (storeId != null && storeId.isNotEmpty) {
        await fetchCategoriesFromStoreType(storeId);
      }

      final response = await sendApiRequest(
        apiName: 'registration-data-dev',
        params: {},
        isPost: false,
      );

      if (response != null) {
        final Map<String, dynamic> data = json.decode(response);

        if (data['status'] == 1 && data['data'] != null) {
          await populateFormData(data['data']['seller']);
        } else {
          hasError = true;
          errorMessage = data['message'] ?? 'Failed to fetch data';
        }
      } else {
        hasError = true;
        errorMessage = 'Failed to fetch seller data';
      }
    } catch (e) {
      hasError = true;
      errorMessage = 'Error: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> populateFormData(Map<String, dynamic> seller) async {
    // Store admin remark if available
    if (seller['remark'] != null && seller['remark'].toString().isNotEmpty) {
      adminRemark = seller['remark'].toString();
    } else {
      adminRemark = null;
    }

    // Personal Info
    if (seller['name'] != null) {
      userNameController.text = seller['name'];
    }
    if (seller['email'] != null) {
      emailController.text = seller['email'];
    }

    // Document numbers
    if (seller['aadhar_number'] != null) {
      aadharNumberController.text = seller['aadhar_number'];
    }
    if (seller['pan_number'] != null) {
      panNumberController.text = seller['pan_number'];
    }
    if (seller['fssai_number'] != null) {
      fssaiNumberController.text = seller['fssai_number'];
    }

    // Store Info
    if (seller['store_name'] != null) {
      storeNameController.text = seller['store_name'];
    }
    if (seller['store_description'] != null) {
      descriptionController.text = seller['store_description'];
    }
    if (seller['store_location'] != null) {
      location = seller['store_location'];
    }
    if (seller['store_city'] != null) {
      city = seller['store_city'];
    }
    if (seller['store_url'] != null) {
      urlController.text = seller['store_url'];
    }
    if (seller['tax_name'] != null) {
      taxNameController.text = seller['tax_name'];
    }
    if (seller['tax_number'] != null) {
      taxNumberController.text = seller['tax_number'];
    }

    if (seller['vendor_gst_percent'] != null) {
      vendorGstPercent =
          double.tryParse(seller['vendor_gst_percent'].toString());
    }
    if (seller['vendor_gst_category'] != null) {
      vendorGstCategory = seller['vendor_gst_category'].toString();
    }
    if (seller['vendor_commission_percent'] != null) {
      vendorCommissionPercent =
          double.tryParse(seller['vendor_commission_percent'].toString());
    }
    if (seller['vendor_commission_category'] != null) {
      vendorCommissionCategory =
          seller['vendor_commission_category'].toString();
    }

    // Categories are now auto-populated from store type via fetchCategoriesFromStoreType
    // No need to parse categories_ids from seller data anymore
    // The categories from the API will already be loaded if storeId was provided

    // Auto-select category if category_name is provided in seller data
    if (seller['category_name'] != null &&
        seller['category_name'].toString().isNotEmpty) {
      String categoryNameFromApi = seller['category_name'].toString();

      // Find and select the matching category from allCategories
      final matchingCategory = allCategories.firstWhere(
        (category) =>
            category.name.toLowerCase() == categoryNameFromApi.toLowerCase(),
        orElse: () => CategoryModel(id: -1, name: '', imageUrl: null),
      );
      
      // If a matching category is found, auto-select it
      if (matchingCategory.id != -1) {
        selectedCategories = [matchingCategory];
      }
    }

    // Parse lat_long if available
    if (seller['lat_long'] != null) {
      String latLong = seller['lat_long'].toString();
      List<String> coords = latLong.split(',');
      if (coords.length == 2) {
        latitude = double.tryParse(coords[0].trim());
        longitude = double.tryParse(coords[1].trim());
      }
    }

    // Image URLs
    aadharImageUrl = seller['national_id_card'];
    panImageUrl = seller['pan_img_url'];
    fssaiImageUrl = seller['fssai_img_url'];
    logoImageUrl = seller['logo_url'];

    // Agreement
    agreementStatus = int.tryParse(seller['agreement_status']?.toString() ?? '0') ?? 0;
    agreementPdfUrl = seller['agreement_pdf_url'];

    if (seller['store_images'] != null && seller['store_images'] is List) {
      storeImageUrls = List<String>.from(seller['store_images']);
    }

    final storeId = seller['store_id']?.toString() ?? '';
    sellerStoreId = storeId.isNotEmpty ? storeId : null;

    // Safe parse booleans
    final managedByAdmin = safeParseBool(seller['managed_by_admin']);
    final isSweetHouse = safeParseBool(seller['is_sweet_house']);
    final isSuperMart = safeParseBool(seller['is_super_mart']);

    // Save store ID, managed_by_admin, is_sweet_house and is_super_mart in session
    await Constant.session.refreshData(
      SessionManager.managedByAdmin,
      managedByAdmin ? "1" : "0",
    );

    await Constant.session.refreshData(
      SessionManager.isSweetHouse,
      isSweetHouse ? "1" : "0",
    );

    await Constant.session.refreshData(
      SessionManager.isSuperMart,
      isSuperMart ? "1" : "0",
    );

    await Constant.session.refreshData(
      SessionManager.keyStoreId,
      storeId,
    );

    // Store FSSAI number from registration data
    if (seller['fssai_number'] != null) {
      await Constant.session.refreshData(
        SessionManager.fssai_number,
        seller['fssai_number'].toString(),
      );
    }

    // Store store type name from registration data
    if (seller['store_type_name'] != null) {
      await Constant.session.refreshData(
        SessionManager.store_type_name,
        seller['store_type_name'].toString(),
      );
    }

    notifyListeners();
  }

  // Upload step 2 data to server (for updates only)
  bool isUploadingStep2 = false;

  Future<void> uploadStep2Data(BuildContext context, int? storeId) async {
    // Validate step 2 fields first
    final validationError = validateStep2();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    isUploadingStep2 = true;
    hasError = false;
    notifyListeners();

    try {
      // Use category names instead of IDs (from the new API structure)
      String categoryNames = selectedCategories.isNotEmpty
          ? selectedCategories.map((c) => c.name).join(',')
          : '';

      Map<String, String> params = {
        'store_name': storeNameController.text.trim(),
        'store_description': descriptionController.text.trim(),
        'store_location': location!,
        'store_city': city ?? "--",
        'tax_name': taxNameController.text.trim(),
        'tax_number': taxNumberController.text.trim().toUpperCase(),
        // 'store_url': urlController.text.trim(),
        'lat_long': '${latitude},${longitude}',
      };

      // Only add categories_ids if categories exist
      if (categoryNames.isNotEmpty) {
        params['categories_ids'] = categoryNames;
      }

      // Add store_id if available
      if (storeId != null) {
        params['store_id'] = storeId.toString();
      }

      // Add existing store image URLs
      if (storeImageUrls.isNotEmpty) {
        for (int i = 0; i < storeImageUrls.length; i++) {
          params['store_images_urls[$i]'] = storeImageUrls[i];
        }
      }

      // Prepare files
      Map<String, File> filesMap = {};

      if (storeLogo != null) {
        filesMap['store_logo'] = storeLogo!;
      }

      // Add new store images
      if (storeImages.isNotEmpty) {
        for (int i = 0; i < storeImages.length; i++) {
          filesMap['store_images[$i]'] = storeImages[i];
        }
      }

      // Send API request to the new update-store-details endpoint
      final response = await sendApiMultiPartRequest(
        apiName: 'update-store-details',
        params: params,
        filesMap: filesMap,
      );

      if (response != null) {
        // Handle both string and map responses
        Map<String, dynamic> data;
        if (response is String) {
          data = json.decode(response);
        } else {
          data = response as Map<String, dynamic>;
        }

        if (data['status'] == 1) {
          // Success
          hasError = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  data['message'] ?? 'Store details updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Error from API
          hasError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(data['message'] ?? 'Failed to update store details'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        hasError = true;
        throw Exception('No response from server');
      }
    } catch (e) {
      hasError = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      isUploadingStep2 = false;
      notifyListeners();
    }
  }

  Future<void> updatePersonalProfile(
      BuildContext context, String? storeId) async {
    final validationError = validateStep1();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    isSubmitting = true;
    hasError = false;
    notifyListeners();

    try {
      Map<String, dynamic> params = {
        'name': userNameController.text.trim(),
        'email': emailController.text.trim(),
        'aadhar_number': _digitsOnly(aadharNumberController.text),
        'pan_number': panNumberController.text.trim().toUpperCase(),
        'fssai_number': _digitsOnly(fssaiNumberController.text),
      };

      Map<String, File> filesMap = {};
      if (aadharFile != null) filesMap['national_id_card'] = aadharFile!;
      if (panFile != null) filesMap['pan_img'] = panFile!;
      if (fassiFile != null) filesMap['fssai_img'] = fassiFile!;

      // Use the new update-personal-details endpoint
      final response = await sendApiMultiPartRequest(
        apiName: 'update-personal-details',
        params: params,
        filesMap: filesMap,
      );

      if (response != null) {
        // Handle both string and map responses
        Map<String, dynamic> data;
        if (response is String) {
          data = json.decode(response);
        } else {
          data = response as Map<String, dynamic>;
        }

        if (data['status'] == 1) {
          hasError = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    data['message'] ?? 'Personal details updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2)),
          );
        } else {
          hasError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    data['message'] ?? 'Failed to update personal details'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3)),
          );
        }
      } else {
        hasError = true;
        throw Exception('No response from server');
      }
    } catch (e) {
      hasError = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3)),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // Final submission
  bool isSubmitting = false;

  // API error message from backend
  String? apiErrorMessage;

  // Clear API error
  void clearApiError() {
    apiErrorMessage = null;
    hasError = false;
    notifyListeners();
  }

  // Approval checking
  bool isCheckingApproval = false;

  // Admin remark for rejection/pending status
  String? adminRemark;

  Future<void> checkApprovalStatus(BuildContext context) async {
    isCheckingApproval = true;
    notifyListeners();

    try {
      // Fetch latest seller data
      final response = await sendApiRequest(
        apiName: 'registration-data-dev',
        params: {},
        isPost: false,
      );

      if (response != null) {
        final Map<String, dynamic> data = json.decode(response);

        if (data['status'] == 1 && data['data'] != null) {
          final seller = data['data']['seller'];

          final storeId = seller['store_id']?.toString() ?? '';

          final userId = seller['id']?.toString();

          await Constant.session.setUserData(data: seller);
          Constant.session
              .setData(SessionManager.keyStoreId, storeId ?? '', true);
          Constant.session
              .setData(SessionManager.keyUserId, userId ?? '', true);

          // Save store ID, managed_by_admin, is_sweet_house and is_super_mart in session
          final managedByAdmin = safeParseBool(seller['managed_by_admin']);
          final isSweetHouse = safeParseBool(seller['is_sweet_house']);
          final isSuperMart = safeParseBool(seller['is_super_mart']);

          await Constant.session.refreshData(
            SessionManager.managedByAdmin,
            managedByAdmin ? "1" : "0",
          );

          await Constant.session.refreshData(
            SessionManager.isSweetHouse,
            isSweetHouse ? "1" : "0",
          );

          await Constant.session.refreshData(
            SessionManager.isSuperMart,
            isSuperMart ? "1" : "0",
          );

          await Constant.session.refreshData(
            SessionManager.keyStoreId,
            storeId,
          );

          // Store FSSAI number from registration data
          if (seller['fssai_number'] != null) {
            await Constant.session.refreshData(
              SessionManager.fssai_number,
              seller['fssai_number'].toString(),
            );
          }

          // Store store type name from registration data
          if (seller['store_type_name'] != null) {
            await Constant.session.refreshData(
              SessionManager.store_type_name,
              seller['store_type_name'].toString(),
            );
          }

          // Check approval status
          final isApproved = seller['is_approved'] == 1 ||
              seller['status'] == 'approved' ||
              seller['approved'] == true;

          // Store admin remark if available
          if (seller['remark'] != null &&
              seller['remark'].toString().isNotEmpty) {
            adminRemark = seller['remark'].toString();
          } else {
            adminRemark = null;
          }
          notifyListeners();

          if (isApproved) {
            // Approved! Navigate to dashboard
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Congratulations! Your registration has been approved!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            await Future.delayed(Duration(seconds: 1));
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(create: (_) => BottomNavProvider()),
                  ],
                  child: MainTabScaffold(),
                ),
              ),
              (route) => false,
            );
          } else {
            // Still pending
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your registration is still pending approval.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Failed to fetch approval status');
        }
      } else {
        throw Exception('No response from server');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking approval status: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      isCheckingApproval = false;
      notifyListeners();
    }
  }

  Future<void> submitRegistration(BuildContext context, String? storeId) async {
    print('_+++++++++++++++++++++++++ $storeId');
    // Validate all fields first
    final validationError = validateAllFields();
    if (validationError != null) {
      apiErrorMessage = validationError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    isSubmitting = true;
    hasError = false;
    apiErrorMessage = null;
    notifyListeners();

    try {
      // Prepare form data - match backend expectations exactly
      // Use category names instead of IDs (from the new API structure)
      String categoryNames = selectedCategories.isNotEmpty
          ? selectedCategories.map((c) => c.name).join(',')
          : '';

      Map<String, dynamic> params = {
        'name': userNameController.text.trim(),
        'email': emailController.text.trim(),
        'aadhar_number': _digitsOnly(aadharNumberController.text),
        'pan_number': panNumberController.text.trim().toUpperCase(),
        'fssai_number': _digitsOnly(fssaiNumberController.text),
        'store_name': storeNameController.text.trim(),
        'store_description': descriptionController.text.trim(),
        'store_location': location!,
        'store_city': city ?? '',
        'tax_name': taxNameController.text.trim(),
        'tax_number': taxNumberController.text.trim().toUpperCase(),
        // 'store_url': urlController.text.trim(),
        "store_id": storeId,
        'lat_long': '${latitude},${longitude}',
        'national_id': "1",
      };

      // Only add category_name if categories exist
      if (categoryNames.isNotEmpty) {
        params['category_name'] = categoryNames;
      }

      // Password handling: backend requires these fields
      // For update (storeId exists), backend may not require password
      // For create (new registration), password is required
      if (passwordController.text.isNotEmpty) {
        params['password'] = passwordController.text;
        params['confirm_password'] = confirmPasswordController.text;
      } else {
        // Use dummy password for updates where user doesn't change password
        params['password'] = "1234567891";
        params['confirm_password'] = "1234567891";
      }

      // Only send store_id when the seller already has a registration.
      // sellerStoreId = actual seller store_id from the API (set in populateFormData).
      // storeId (widget.storeId) is the store TYPE id — never use it as store_id.
      if (sellerStoreId != null && sellerStoreId!.isNotEmpty) {
        params['store_id'] = sellerStoreId!;
        log('[SUBMIT] store_id = $sellerStoreId (existing seller, update mode)');
      } else {
        log('[SUBMIT] store_id = NOT SENT (new registration)');
      }

      // Prepare files
      Map<String, File> filesMap = {};

      // Upload new files; if no new file, fall back to existing URL as a param
      if (aadharFile != null) {
        filesMap['national_id_card'] = aadharFile!;
        log('[IMG] Aadhar  → NEW FILE: ${aadharFile!.path}');
      } else if (aadharImageUrl != null && aadharImageUrl!.isNotEmpty) {
        params['national_id_card_url'] = aadharImageUrl!;
        log('[IMG] Aadhar  → EXISTING URL: $aadharImageUrl');
      } else {
        log('[IMG] Aadhar  → MISSING (null)');
      }

      if (panFile != null) {
        filesMap['pan_img'] = panFile!;
        log('[IMG] PAN     → NEW FILE: ${panFile!.path}');
      } else if (panImageUrl != null && panImageUrl!.isNotEmpty) {
        params['pan_img_url'] = panImageUrl!;
        log('[IMG] PAN     → EXISTING URL: $panImageUrl');
      } else {
        log('[IMG] PAN     → MISSING (null)');
      }

      if (fassiFile != null) {
        filesMap['fssai_img'] = fassiFile!;
        log('[IMG] FSSAI   → NEW FILE: ${fassiFile!.path}');
      } else if (fssaiImageUrl != null && fssaiImageUrl!.isNotEmpty) {
        params['fssai_img_url'] = fssaiImageUrl!;
        log('[IMG] FSSAI   → EXISTING URL: $fssaiImageUrl');
      } else {
        log('[IMG] FSSAI   → MISSING (null) — optional, skipped');
      }

      if (storeLogo != null) {
        filesMap['store_logo'] = storeLogo!;
        log('[IMG] Logo    → NEW FILE: ${storeLogo!.path}');
      } else if (logoImageUrl != null && logoImageUrl!.isNotEmpty) {
        params['store_logo_url'] = logoImageUrl!;
        log('[IMG] Logo    → EXISTING URL: $logoImageUrl');
      } else {
        log('[IMG] Logo    → MISSING (null)');
      }

      // Add store images as array
      // Backend expects store_images[] as an array
      if (storeImages.isNotEmpty) {
        for (int i = 0; i < storeImages.length; i++) {
          filesMap['store_images[$i]'] = storeImages[i];
          log('[IMG] StoreImage[$i] → NEW FILE: ${storeImages[i].path}');
        }
      }
      // Also send existing store image URLs
      if (storeImageUrls.isNotEmpty) {
        for (int i = 0; i < storeImageUrls.length; i++) {
          params['store_images_urls[$i]'] = storeImageUrls[i];
          log('[IMG] StoreImage[$i] → EXISTING URL: ${storeImageUrls[i]}');
        }
      }
      if (storeImages.isEmpty && storeImageUrls.isEmpty) {
        log('[IMG] StoreImages → MISSING (none)');
      }

      log('[SUBMIT] params keys  : ${params.keys.toList()}');
      log('[SUBMIT] filesMap keys: ${filesMap.keys.toList()}');

      // Send API request to seller registration endpoint
      final response = await sendApiMultiPartRequest(
        apiName: 'post-registration-data-dev',
        params: params,
        filesMap: filesMap,
      );

      if (response != null) {
        // Handle both string and map responses
        Map<String, dynamic> data;
        if (response is String) {
          data = json.decode(response);
        } else {
          data = response as Map<String, dynamic>;
        }

        if (data['status'] == 1 || data['success'] == true) {
          // Success - show message but don't navigate
          // Navigation will be handled by moving to step 3 (success screen)
          apiErrorMessage = null;
          hasError = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Registration Successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Error from API - backend returned error
          hasError = true;
          apiErrorMessage = data['message'] ?? 'Registration failed';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiErrorMessage!),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        hasError = true;
        apiErrorMessage = 'No response from server';
        throw Exception('No response from server');
      }
    } catch (e) {
      hasError = true;
      apiErrorMessage = 'Error: ${e.toString()}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorMessage!),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // Legacy submission (kept for compatibility)
  void onSubmit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BottomNavProvider()),
          ],
          child: MainTabScaffold(),
        ),
      ),
    );
    // ScaffoldMessenger.of(context)
    //     .showSnackBar(SnackBar(content: Text("Registration submitted!")));
  }

  // Categories - now selectable from store type
  List<CategoryModel> allCategories = []; // All available categories from API
  List<CategoryModel> selectedCategories = []; // User selected categories
  bool isCategoriesLoading = false;

  // For backward compatibility with existing code
  List<CategoryModel> get categories => selectedCategories;

  // Fetch categories from the new get-seller-registration-helper API
  Future<void> fetchCategoriesFromStoreType(String storeIdParam) async {
    if (allCategories.isNotEmpty) return; // Already fetched

    isCategoriesLoading = true;
    notifyListeners();

    try {
      final response = await sendApiRequest(
        apiName: 'get-seller-registration-helper',
        params: {},
        isPost: false,
      );

      final Map<String, dynamic> data = json.decode(response);
      if (data['status'] == 1 && data['data'] != null) {
        final List<dynamic> storeTypes = data['data'];

        // Find the store type that matches the storeId
        for (var storeType in storeTypes) {
          if (storeType['id'].toString() == storeIdParam) {
            // Convert the categories array (list of strings) to CategoryModel objects
            if (storeType['categories'] != null &&
                storeType['categories'] is List) {
              final List<String> categoryNames =
                  List<String>.from(storeType['categories']);

              // Create CategoryModel objects from category names
              // Since we only have names, we'll use index as ID
              allCategories = categoryNames.asMap().entries.map((entry) {
                return CategoryModel(
                  id: entry.key + 1, // Use index + 1 as ID
                  name: entry.value,
                  imageUrl: null, // No image URL in new API
                );
              }).toList();

              // Don't auto-select any categories - let user choose
              // selectedCategories will remain empty until user selects
            }
            break;
          }
        }
      }
    } catch (e) {
      print("Error fetching categories from store type: $e");
    } finally {
      isCategoriesLoading = false;
      notifyListeners();
    }
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String? imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
    );
  }
}
