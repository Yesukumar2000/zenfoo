import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/placeSuggestionsModel.dart' as model;
import 'package:project/models/placeSuggestionsModel.dart';
import 'package:project/repositories/getPlaceSuggestionsApi.dart';

enum PlaceSuggestionsState {
  initial,
  loading,
  loaded,
  empty,
  error,
}

class PlaceSuggestionsProvider extends ChangeNotifier {
  PlaceSuggestionsState placeSuggestionsState = PlaceSuggestionsState.initial;
  List<Suggestions> suggestions = [];
  String message = '';

  Future<void> fetchSuggestions({
    required BuildContext context,
    required String input,
  }) async {
    placeSuggestionsState = PlaceSuggestionsState.loading;
    suggestions = [];
    message = '';
    notifyListeners();

    try {
      final sessionManager = context.read<SessionManager>();

      // 1. Try from cache first
      if (Constant.autocompleteSuggestionsCache.containsKey(input)) {
        final cachedList = Constant.autocompleteSuggestionsCache[input] ?? [];
        suggestions = cachedList.map((e) => Suggestions.fromJson(e)).toList();

        if (suggestions.isNotEmpty) {
          placeSuggestionsState = PlaceSuggestionsState.loaded;
          notifyListeners();
          return;
        }
      } else {
        // 2. If not cached, call API
        final response = await getPlaceSuggestionsApi(
          context: context,
          input: input,
        );

        if (response[ApiAndParams.error] == true) {
          message =
              response[ApiAndParams.message] ?? Constant.somethingWentWrong;
          placeSuggestionsState = PlaceSuggestionsState.error;
        } else {
          try {
            // Check if data exists
            if (response[ApiAndParams.data] == null) {
              debugPrint("PlaceSuggestions: data is null in response");
              message = "No results found";
              placeSuggestionsState = PlaceSuggestionsState.empty;
            } else if (response[ApiAndParams.data][ApiAndParams.suggestions] ==
                    null &&
                response[ApiAndParams.data][ApiAndParams.predictions] == null) {
              debugPrint(
                  "PlaceSuggestions: suggestions and predictions are null");
              message = "No results found";
              placeSuggestionsState = PlaceSuggestionsState.empty;
            } else {
              if (response[ApiAndParams.data][ApiAndParams.suggestions] !=
                  null) {
                final dataList = response[ApiAndParams.data]
                    [ApiAndParams.suggestions] as List;
                suggestions =
                    dataList.map((item) => Suggestions.fromJson(item)).toList();
              } else if (response[ApiAndParams.data]
                      [ApiAndParams.predictions] !=
                  null) {
                final dataList = response[ApiAndParams.data]
                    [ApiAndParams.predictions] as List;
                suggestions = dataList.map((item) {
                  return Suggestions(
                    placePrediction: PlacePrediction(
                      placeId: item['place_id'],
                      place: item['description'],
                      structuredFormat: StructuredFormat(
                        mainText: model.Text(
                            text: item['structured_formatting']?['main_text']),
                        secondaryText: SecondaryText(
                            text: item['structured_formatting']
                                ?['secondary_text']),
                      ),
                    ),
                  );
                }).toList();
              }

              if (suggestions.isEmpty) {
                placeSuggestionsState = PlaceSuggestionsState.empty;
              } else {
                placeSuggestionsState = PlaceSuggestionsState.loaded;
                // Save in Constant & session
                Constant.autocompleteSuggestionsCache[input] =
                    suggestions.map((e) => e.toJson()).toList();
                await sessionManager.saveAutocompleteSuggestions();
              }
            }
          } catch (parseError) {
            debugPrint("PlaceSuggestions parse error: $parseError");
            debugPrint("Response structure: ${response.toString()}");
            message = "Unable to parse search results";
            placeSuggestionsState = PlaceSuggestionsState.error;
          }
        }
      }
    } catch (e) {
      debugPrint("PlaceSuggestions network error: $e");
      message = "Network error. Please try again.";
      placeSuggestionsState = PlaceSuggestionsState.error;
    }

    notifyListeners();
  }

  void clearSuggestions() {
    suggestions = [];
    message = '';
    placeSuggestionsState = PlaceSuggestionsState.initial;
    notifyListeners();
  }
}
