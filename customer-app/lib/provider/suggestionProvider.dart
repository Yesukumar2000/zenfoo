import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/suggestion.dart';
import 'package:project/repositories/suggestionApi.dart';

enum SuggestionState { initial, loading, loaded, loadingMore, error }

class SuggestionProvider extends ChangeNotifier {
  SuggestionState listState = SuggestionState.initial;
  String message = '';
  List<Suggestion> suggestions = [];
  bool hasMoreData = true;
  int totalData = 0;
  int currentPage = 1;
  bool _isFetching = false;
  bool isSubmitting = false;

  Future<void> getSuggestions({required BuildContext context}) async {
    if (_isFetching || !hasMoreData) return;
    _isFetching = true;

    listState = currentPage == 1
        ? SuggestionState.loading
        : SuggestionState.loadingMore;
    notifyListeners();

    try {
      final Map<String, dynamic> getData = await getSuggestionsApi(
        context: context,
        params: {'page': currentPage.toString()},
      );

      if (getData['success'] == true) {
        final paginatedData = getData['data'];
        totalData = paginatedData['total'];
        final List<Suggestion> temp = (paginatedData['data'] as List)
            .map((e) => Suggestion.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        suggestions.addAll(temp);
        hasMoreData = suggestions.length < totalData;
        if (hasMoreData) currentPage++;
        listState = SuggestionState.loaded;
      } else {
        hasMoreData = false;
        listState =
            suggestions.isEmpty ? SuggestionState.error : SuggestionState.loaded;
      }
    } catch (e) {
      message = e.toString();
      listState = SuggestionState.error;
      showMessage(context, message, MessageType.warning);
    }

    _isFetching = false;
    notifyListeners();
  }

  Future<bool> submitSuggestion({
    required BuildContext context,
    required String text,
  }) async {
    isSubmitting = true;
    notifyListeners();

    try {
      final Map<String, dynamic> getData = await submitSuggestionApi(
        context: context,
        params: {'suggestion': text},
      );

      isSubmitting = false;

      if (getData['success'] == true) {
        showMessage(
            context, getData['message']?.toString() ?? '', MessageType.success);
        reset();
        getSuggestions(context: context);
        return true;
      }

      showMessage(
          context, getData['message']?.toString() ?? '', MessageType.warning);
      notifyListeners();
      return false;
    } catch (e) {
      message = e.toString();
      isSubmitting = false;
      showMessage(context, message, MessageType.warning);
      notifyListeners();
      return false;
    }
  }

  void reset() {
    suggestions = [];
    currentPage = 1;
    hasMoreData = true;
    totalData = 0;
    listState = SuggestionState.initial;
    _isFetching = false;
  }
}
