import 'package:project/helper/utils/generalImports.dart';

enum ProductSearchState {
  initial,
  loaded,
  loading,
  loadingMore,
  empty,
  error,
}

class ProductSearchProvider extends ChangeNotifier {
  ProductSearchState productSearchState = ProductSearchState.initial;
  String message = '';
  int currentSortByOrderIndex = 0;
  late ProductList productList;
  List<ProductListItem> products = [];
  bool hasMoreData = false;
  int totalData = 0;
  int offset = 0;
  int searchedTextLength = 0;

  /// The query the current results belong to.
  ///
  /// The debounce used to dedupe on `searchedTextLength`, so a second search
  /// with the same number of characters was silently dropped — "ghee" after
  /// "milk", or the same phrase spoken twice, returned nothing at all because
  /// the API was never called. Comparing the text is the only thing that
  /// actually identifies a query.
  String searchedText = '';

  bool isSearchingByVoice = false;

  getProductSearchProvider(
      {required Map<String, dynamic> params,
      required BuildContext context}) async {
    if (offset == 0) {
      productSearchState = ProductSearchState.loading;
    } else {
      productSearchState = ProductSearchState.loadingMore;
    }
    notifyListeners();

    params[ApiAndParams.limit] = Constant.defaultDataLoadLimitAtOnce.toString();
    params[ApiAndParams.offset] = offset.toString();

    try {
      Map<String, dynamic> response =
          await getProductListApi(context: context, params: params);
      if (response[ApiAndParams.status].toString() == "1") {
        productList = ProductList.fromJson(response);

        totalData = int.parse(productList.total);

        if (totalData > 0) {
          products.addAll(productList.data);

          productSearchState = ProductSearchState.loaded;

          hasMoreData = totalData > products.length;

          if (hasMoreData) {
            offset += Constant.defaultDataLoadLimitAtOnce;
          }
          productSearchState = ProductSearchState.loaded;
          notifyListeners();
        } else {
          productSearchState = ProductSearchState.empty;
          notifyListeners();
        }
      } else {
        if (response[ApiAndParams.message] == "No Products found") {
          productSearchState = ProductSearchState.empty;
          notifyListeners();
        } else {
          message = Constant.somethingWentWrong;
          productSearchState = ProductSearchState.error;
          notifyListeners();
        }
      }
    } catch (e) {
      message = e.toString();
      productSearchState = ProductSearchState.error;
      notifyListeners();
      rethrow;
    }
  }

  changeState(ProductSearchState state) {
    productSearchState = state;
    notifyListeners();
  }

  setSearchLength(String text) {
    searchedTextLength = text.length;
    searchedText = text.trim();
    if (text.isEmpty) {
      products.clear();
    }
    notifyListeners();
  }

  /// Clears the record of what was last searched.
  ///
  /// Called when the field is emptied, so retyping the very same query still
  /// runs — otherwise clearing and searching again for the same thing did
  /// nothing.
  clearSearchedText() {
    searchedText = '';
    searchedTextLength = 0;
    products.clear();
    notifyListeners();
  }

  enableDisableSearchByVoice(bool value) {
    isSearchingByVoice = value;
    notifyListeners();
  }
}
