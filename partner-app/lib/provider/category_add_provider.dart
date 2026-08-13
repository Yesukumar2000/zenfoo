import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/category_model.dart';

class CategoryAddProvider extends ChangeNotifier {
  final CategoryModel? category;

  CategoryAddProvider({this.category}) {
    if (category != null) {
      _initFromCategory();
    }
  }

  void _initFromCategory() {
    name.text = category!.name;
    subtitle.text = category!.subtitle;
    imageUrl = category!.imageUrl;
    // Don't initialize _types with existing types
    // _types should only contain new types to be added
  }

  // Controllers
  final TextEditingController name = TextEditingController();
  final TextEditingController subtitle = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? imageFile;
  String? imageUrl;

  // Types management
  List<String> _types = [];
  List<String> get types => _types;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setImageFile(File? file) {
    imageFile = file;
    imageUrl = null; // Clear URL when new file is selected
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setImageFile(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Add this back to CategoryAddProvider
  Future<void> recoverLostData() async {
    try {
      final LostDataResponse response = await _imagePicker.retrieveLostData();
      if (response.isEmpty) return;

      if (response.file != null) {
        setImageFile(File(response.file!.path));
        debugPrint('✅ Recovered lost image: ${response.file!.path}');
      }
    } catch (e) {
      debugPrint('❌ Error recovering lost data: $e');
    }
  }

  // Add type to the list
  void addType(String typeName) {
    if (typeName.trim().isNotEmpty && !_types.contains(typeName.trim())) {
      _types.add(typeName.trim());
      typeController.clear();
      notifyListeners();
    }
  }

  // Remove type from the list
  void removeType(int index) {
    if (index >= 0 && index < _types.length) {
      _types.removeAt(index);
      notifyListeners();
    }
  }

  // Remove type by ID (for existing category types)
  Future<bool> removeTypeById(BuildContext context, String typeId) async {
    if (category?.id == null) return false;

    try {
      setLoading(true);
      final result = await deleteCategoryTypeApi(typeId: typeId);
      setLoading(false);

      if (result != null && result['status'].toString() == '1') {
        showMessage(
          context,
          result['message'] ?? 'Type deleted successfully!',
          MessageType.success,
        );
        return true;
      } else {
        showMessage(
          context,
          result?['message'] ?? 'Failed to delete type',
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      setLoading(false);
      showMessage(context, 'Error deleting type: $e', MessageType.error);
      return false;
    }
  }

  /// Validate form fields
  bool validateFields(BuildContext context) {
    if (name.text.trim().isEmpty) {
      showMessage(context, 'Please enter category name', MessageType.error);
      return false;
    }

    if (subtitle.text.trim().isEmpty) {
      showMessage(
          context, 'Please enter category description', MessageType.error);
      return false;
    }

    if (imageFile == null && imageUrl == null) {
      showMessage(context, 'Please upload category image', MessageType.error);
      return false;
    }

    return true;
  }

  /// Save category to API
  Future<bool> saveCategory(BuildContext context) async {
    if (!validateFields(context)) {
      return false;
    }

    setLoading(true);

    try {
      // Get store ID from session
      final storeId = Constant.session.getData(SessionManager.keyStoreId);

      // Prepare params
      Map<String, String> params = {
        'name': name.text.trim(),
        'subtitle': subtitle.text.trim(),
        'store_id': storeId.toString(),
      };

      // Call API with types
      final result = await addOrUpdateCategoryApi(
        params: params,
        imageFile: imageFile,
        types: _types.isNotEmpty ? _types : null,
        isAdd: category == null,
        categoryId: category?.id,
      );

      setLoading(false);

      if (result != null && result['status'].toString() == '1') {
        showMessage(
          context,
          result['message'] ?? 'Category saved successfully!',
          MessageType.success,
        );
        return true;
      } else {
        showMessage(
          context,
          result?['message'] ?? 'Failed to save category',
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      setLoading(false);
      print('Error saving category: $e');
      showMessage(context, 'Error: $e', MessageType.error);
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(BuildContext context) async {
    if (category == null || category!.id == null) {
      showMessage(context, 'No category to delete', MessageType.error);
      return false;
    }

    setLoading(true);

    try {
      final result = await deleteCategoryApi(
        categoryId: category!.id!,
      );

      setLoading(false);

      if (result != null && result['status'].toString() == '1') {
        showMessage(
          context,
          result['message'] ?? 'Category deleted successfully!',
          MessageType.success,
        );
        return true;
      } else {
        showMessage(
          context,
          result?['message'] ?? 'Failed to delete category',
          MessageType.error,
        );
        return false;
      }
    } catch (e) {
      setLoading(false);
      showMessage(context, 'Error deleting category: $e', MessageType.error);
      return false;
    }
  }

  @override
  void dispose() {
    name.dispose();
    subtitle.dispose();
    typeController.dispose();
    super.dispose();
  }
}
