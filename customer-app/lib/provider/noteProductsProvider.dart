import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/noteProduct.dart';
import 'package:project/repositories/notesApi.dart';

enum NoteProductsState {
  initial,
  loading,
  loaded,
  error,
}

class NoteProductsProvider extends ChangeNotifier {
  NoteProductsState state = NoteProductsState.initial;
  String message = '';
  List<NoteProductGroup> noteProductGroups = [];
  bool isDataLoaded = false;

  // Get products by selected notes
  Future<void> getProductsBySelectedNotes({
    required BuildContext context,
  }) async {
    state = NoteProductsState.loading;
    notifyListeners();

    try {
      Map<String, dynamic> response =
          await getProductsBySelectedNotesApi(context: context);

      if (response['status'].toString() == '1') {
        NoteProductsResponse noteProductsResponse =
            NoteProductsResponse.fromJson(response);
        noteProductGroups = noteProductsResponse.data ?? [];
        isDataLoaded = true;
        state = NoteProductsState.loaded;
        notifyListeners();
      } else {
        message = response['message'] ?? 'Failed to load products';
        state = NoteProductsState.error;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      state = NoteProductsState.error;
      notifyListeners();
    }
  }

  // Get groups with products (excluding empty groups)
  List<NoteProductGroup> getGroupsWithProducts() {
    return noteProductGroups
        .where((group) => (group.productsCount ?? 0) > 0)
        .toList();
  }

  // Get total products count
  int getTotalProductsCount() {
    return noteProductGroups.fold(
        0, (sum, group) => sum + (group.productsCount ?? 0));
  }

  // Clear data
  void clearData() {
    noteProductGroups.clear();
    isDataLoaded = false;
    state = NoteProductsState.initial;
    notifyListeners();
  }
}
