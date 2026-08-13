import 'package:project/helper/utils/generalImports.dart';

enum SimilarFromCartState { initial, loading, loaded, empty, error }

class SimilarFromCartProvider extends ChangeNotifier {
  SimilarFromCartState state = SimilarFromCartState.initial;
  List<ProductListItem> products = [];
  String message = '';

  Future<void> fetchSimilarProducts({
    required BuildContext context,
    int limit = 10,
  }) async {
    state = SimilarFromCartState.loading;
    notifyListeners();

    try {
      Map<String, dynamic> params = {
        ApiAndParams.limit: limit.toString(),
      };

      debugPrint("=== SIMILAR FROM CART API ===");
      Map<String, dynamic> response = await getSimilarFromCartApi(
        context: context,
        params: params,
      );
      debugPrint("SimilarFromCart response: $response");
      debugPrint("SimilarFromCart status: ${response[ApiAndParams.status]}");

      if (response[ApiAndParams.status].toString() == "1") {
        final dataList = response[ApiAndParams.data] as List?;
        debugPrint("SimilarFromCart data length: ${dataList?.length}");
        if (dataList != null && dataList.isNotEmpty) {
          products = dataList
              .map((e) => ProductListItem.fromJson(e))
              .toList();
          debugPrint("SimilarFromCart parsed products: ${products.length}");
          state = SimilarFromCartState.loaded;
        } else {
          debugPrint("SimilarFromCart: data is empty");
          state = SimilarFromCartState.empty;
        }
      } else {
        message = response[ApiAndParams.message]?.toString() ?? '';
        debugPrint("SimilarFromCart: status not 1, message: $message");
        state = SimilarFromCartState.empty;
      }
    } catch (e, stackTrace) {
      debugPrint("SimilarFromCart ERROR: $e");
      debugPrint("SimilarFromCart STACK: $stackTrace");
      message = e.toString();
      state = SimilarFromCartState.error;
    }

    notifyListeners();
  }
}
