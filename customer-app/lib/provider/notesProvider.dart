import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/userNote.dart';
import 'package:project/repositories/notesApi.dart';

enum NotesState {
  initial,
  loading,
  loaded,
  error,
}

class NotesProvider extends ChangeNotifier {
  NotesState notesState = NotesState.initial;
  String message = '';
  List<UserNote> notes = [];
  bool isDataLoaded = false;

  // Loading states for individual operations
  bool isAdding = false;
  String? deletingNoteId;
  String? togglingNoteId;

  // Get all notes
  Future<void> getAllNotes({required BuildContext context}) async {
    notesState = NotesState.loading;
    notifyListeners();

    try {
      Map<String, dynamic> response = await getNotesApi(context: context);

      if (response['status'].toString() == '1') {
        UserNoteResponse noteResponse = UserNoteResponse.fromJson(response);
        notes = noteResponse.data ?? [];
        isDataLoaded = true;
        notesState = NotesState.loaded;
        notifyListeners();
      } else {
        message = response['message'] ?? 'Failed to load notes';
        notesState = NotesState.error;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      notesState = NotesState.error;
      notifyListeners();
    }
  }

  // Add a new note
  Future<bool> addNote({
    required BuildContext context,
    required String noteText,
    bool isSelected = true,
  }) async {
    isAdding = true;
    notifyListeners();

    try {
      Map<String, dynamic> params = {
        'note_text': noteText,
        'is_selected': isSelected ? '1' : '0',
      };

      Map<String, dynamic> response =
          await addNoteApi(context: context, params: params);

      if (response.isNotEmpty && response['status']?.toString() == '1') {
        // Refresh notes list to get updated data from server
        await getAllNotes(context: context);
        return true;
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to add note',
          MessageType.error,
        );
      }
      return false;
    } catch (e) {
      showMessage(
        context,
        'Failed to add note: $e',
        MessageType.error,
      );
      return false;
    } finally {
      isAdding = false;
      notifyListeners();
    }
  }

  // Delete a note
  Future<bool> deleteNote({
    required BuildContext context,
    required String noteId,
  }) async {
    deletingNoteId = noteId;
    notifyListeners();

    try {
      Map<String, dynamic> response =
          await deleteNoteApi(context: context, noteId: noteId);

      if (response.isNotEmpty && response['status']?.toString() == '1') {
        // Refresh notes list to get updated data from server
        await getAllNotes(context: context);
        return true;
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to delete note',
          MessageType.error,
        );
      }
      return false;
    } catch (e) {
      showMessage(
        context,
        'Failed to delete note: $e',
        MessageType.error,
      );
      return false;
    } finally {
      deletingNoteId = null;
      notifyListeners();
    }
  }

  // Toggle note selection
  Future<bool> toggleNoteSelection({
    required BuildContext context,
    required String noteId,
    required bool isSelected,
  }) async {
    togglingNoteId = noteId;
    notifyListeners();

    try {
      Map<String, dynamic> params = {
        'is_selected': isSelected ? '1' : '0',
      };

      Map<String, dynamic> response = await toggleNoteSelectionApi(
        context: context,
        noteId: noteId,
        params: params,
      );

      if (response.isNotEmpty && response['status']?.toString() == '1') {
        // Refresh notes list to get updated data from server
        await getAllNotes(context: context);
        return true;
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to update note',
          MessageType.error,
        );
      }
      return false;
    } catch (e) {
      showMessage(
        context,
        'Failed to update note: $e',
        MessageType.error,
      );
      return false;
    } finally {
      togglingNoteId = null;
      notifyListeners();
    }
  }

  // Update note text
  Future<bool> updateNote({
    required BuildContext context,
    required String noteId,
    String? noteText,
    bool? isSelected,
  }) async {
    try {
      Map<String, dynamic> params = {};
      if (noteText != null) params['note_text'] = noteText;
      if (isSelected != null) params['is_selected'] = isSelected ? '1' : '0';

      Map<String, dynamic> response = await updateNoteApi(
        context: context,
        noteId: noteId,
        params: params,
      );

      if (response.isNotEmpty && response['status']?.toString() == '1') {
        SingleUserNoteResponse noteResponse =
            SingleUserNoteResponse.fromJson(response);
        int index = notes.indexWhere((note) => note.id == noteId);
        if (index != -1) {
          if (noteResponse.note != null) {
            notes[index] = noteResponse.note!;
          } else {
            // Update locally if server didn't return updated object
            notes[index] = notes[index].copyWith(
              noteText: noteText,
              isSelected: isSelected,
            );
          }
          notifyListeners();
        }
        return true;
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to update note',
          MessageType.error,
        );
      }
      return false;
    } catch (e) {
      showMessage(
        context,
        'Failed to update note: $e',
        MessageType.error,
      );
      return false;
    }
  }

  // Get selected notes
  List<UserNote> getSelectedNotes() {
    return notes.where((note) => note.isSelected).toList();
  }

  // Get selected notes count
  int getSelectedCount() {
    return notes.where((note) => note.isSelected).length;
  }

  // Get selected notes text list
  List<String> getSelectedNotesText() {
    return notes
        .where((note) => note.isSelected)
        .map((note) => note.noteText ?? '')
        .toList();
  }

  // Clear all notes (optional)
  void clearNotes() {
    notes.clear();
    isDataLoaded = false;
    notesState = NotesState.initial;
    notifyListeners();
  }
}
