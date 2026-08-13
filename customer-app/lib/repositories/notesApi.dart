import 'package:project/helper/utils/generalImports.dart';

// Get all notes
Future<Map<String, dynamic>> getNotesApi({
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiNotes,
      params: {},
      isPost: false,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in getNotesApi: $e");
    rethrow;
  }
}

// Add a new note
Future<Map<String, dynamic>> addNoteApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: "${ApiAndParams.apiNotes}/add",
      params: params,
      isPost: true,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in addNoteApi: $e");
    rethrow;
  }
}

// Update a note
Future<Map<String, dynamic>> updateNoteApi({
  required BuildContext context,
  required String noteId,
  required Map<String, dynamic> params,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: '${ApiAndParams.apiNotes}/update/$noteId',
      params: params,
      isPost: true,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in updateNoteApi: $e");
    rethrow;
  }
}

// Delete a note
Future<Map<String, dynamic>> deleteNoteApi({
  required BuildContext context,
  required String noteId,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: '${ApiAndParams.apiNotes}/delete/$noteId',
      params: {},
      isPost: true,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in deleteNoteApi: $e");
    rethrow;
  }
}

// Toggle note selection
Future<Map<String, dynamic>> toggleNoteSelectionApi({
  required BuildContext context,
  required String noteId,
  required Map<String, dynamic> params,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: '${ApiAndParams.apiNotes}/$noteId/toggle-select',
      params: params,
      isPost: true,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in toggleNoteSelectionApi: $e");
    rethrow;
  }
}

// Get selected notes only
Future<Map<String, dynamic>> getSelectedNotesApi({
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiNotesSelected,
      params: {},
      isPost: false,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in getSelectedNotesApi: $e");
    rethrow;
  }
}

// Bulk update notes
Future<Map<String, dynamic>> bulkUpdateNotesApi({
  required BuildContext context,
  required Map<String, dynamic> params,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: ApiAndParams.apiNotesBulkUpdate,
      params: params,
      isPost: true,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in bulkUpdateNotesApi: $e");
    rethrow;
  }
}

// Get products by selected notes
Future<Map<String, dynamic>> getProductsBySelectedNotesApi({
  required BuildContext context,
}) async {
  try {
    var response = await sendApiRequest(
      apiName: '${ApiAndParams.apiNotes}/products-by-selected-notes',
      params: {},
      isPost: false,
      context: context,
    );
    return response != null ? json.decode(response) : {};
  } catch (e) {
    debugPrint("Error in getProductsBySelectedNotesApi: $e");
    rethrow;
  }
}
