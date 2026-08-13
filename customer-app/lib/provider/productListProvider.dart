import 'package:project/helper/utils/generalImports.dart';

enum ProductState {
  initial,
  loaded,
  loading,
  loadingMore,
  empty,
  error,
}

/* class ProductListProvider extends ChangeNotifier {
  ProductState productState = ProductState.initial;
  String message = '';
  int currentSortByOrderIndex = 0;
  late ProductList productList;
  List<ProductListItem> products = [];
  bool hasMoreData = false;
  int totalData = 0;
  int offset = 0;

  getProductListProvider(
      {required Map<String, dynamic> params,
      required BuildContext context}) async {
    if (offset == 0) {
      productState = ProductState.loading;
    } else {
      productState = ProductState.loadingMore;
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

          hasMoreData = totalData > products.length;

          if (hasMoreData) {
            offset += Constant.defaultDataLoadLimitAtOnce;
          }
          productState = ProductState.loaded;
          notifyListeners();
        } else {
          productState = ProductState.empty;
          notifyListeners();
        }
      } else {
        message = Constant.somethingWentWrong;
        productState = ProductState.empty;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      showMessage(context, message, MessageType.error);
      productState = ProductState.error;
      notifyListeners();
    }
  }
} */
class ProductListProvider extends ChangeNotifier {
  ProductState productState = ProductState.initial;
  String message = '';
  int currentSortByOrderIndex = 0;
  late ProductList productList;
  List<ProductListItem> products = [];
  bool hasMoreData = false;
  int totalData = 0;
  int offset = 0;

  bool isLoading = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /* Future<void> getProductListProvider({
    required Map<String, dynamic> params,
    required BuildContext context,
  }) async {
    if (isLoading) return; // Prevent multiple calls

    isLoading = true;

    if (offset == 0) {
      productState = ProductState.loading;
    } else {
      productState = ProductState.loadingMore;
    }
    notifyListeners();

    params[ApiAndParams.limit] = Constant.defaultDataLoadLimitAtOnce.toString();
    params[ApiAndParams.offset] = offset.toString();

    try {
      Map<String, dynamic> response = await getProductListApi(context: context, params: params);

      if (response[ApiAndParams.status].toString() == "1") {
        productList = ProductList.fromJson(response);
        totalData = int.parse(productList.total);

        if (totalData > 0) {
          products.addAll(productList.data);
          hasMoreData = totalData > products.length;

          if (hasMoreData) {
            offset += Constant.defaultDataLoadLimitAtOnce;
          }

          productState = ProductState.loaded;
        } else {
          productState = ProductState.empty;
        }
      } else {
        message = Constant.somethingWentWrong;
        productState = ProductState.empty;
      }
    } catch (e) {
      message = e.toString();
      showMessage(context, message, MessageType.error);
      productState = ProductState.error;
    }

    isLoading = false;
    notifyListeners();
  }
} */
Future<void> getProductListProvider({
  required Map<String, dynamic> params,
  required BuildContext context,
}) async {
  if (isLoading) return; // Prevent multiple calls
  isLoading = true;

  if (offset == 0) {
    productState = ProductState.loading;
    products.clear();
  } else {
    productState = ProductState.loadingMore;
  }
  if (!_isDisposed) notifyListeners();

  params[ApiAndParams.limit] = Constant.defaultDataLoadLimitAtOnce.toString();
  params[ApiAndParams.offset] = offset.toString();

  try {
    Map<String, dynamic> response =
        await getProductListApi(context: context, params: params);

    if (response[ApiAndParams.status].toString() == "1") {
      productList = ProductList.fromJson(response);
      totalData = int.parse(productList.total);

      if (totalData > 0) {
        if (offset == 0) {
          // For reset calls, replace all products
          products = List<ProductListItem>.from(productList.data);
        } else {
          // For pagination, add new items avoiding duplicates
          for (var newItem in productList.data) {
            if (!products.any((existing) => existing.id == newItem.id)) {
              products.add(newItem);
            }
          }
        }

        hasMoreData = totalData > products.length;

        if (hasMoreData) {
          offset += Constant.defaultDataLoadLimitAtOnce;
        }

        productState = ProductState.loaded;
      } else {
        productState = ProductState.empty;
      }
    } else {
      message = Constant.somethingWentWrong;
      productState = ProductState.empty;
    }
  } catch (e) {
    message = e.toString();
    showMessage(context, message, MessageType.error);
    productState = ProductState.error;
  }

  isLoading = false;
  if (!_isDisposed) notifyListeners();
}
}

