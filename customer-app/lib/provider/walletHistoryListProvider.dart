import 'package:project/helper/utils/generalImports.dart';
import 'package:project/repositories/walletApis.dart';

enum WalletHistoryState {
  initial,
  loading,
  loaded,
  loadingMore,
  empty,
  error,
}

class WalletHistoryProvider extends ChangeNotifier {
  WalletHistoryState walletHistoryState = WalletHistoryState.initial;
  String message = '';
  late WalletHistory walletHistoryData;
  List<WalletHistoryData> walletHistories = [];
  bool hasMoreData = false;
  int totalData = 0;
  int offset = 0;
  String currentFilter = 'all';

  /// Resets state for filter change and fetches fresh data
  void resetForFilter(String filter) {
    currentFilter = filter;
    offset = 0;
    walletHistories.clear();
    walletHistoryState = WalletHistoryState.loading;
    notifyListeners();
  }

  getWalletHistoryProvider({
    required Map<String, dynamic> params,
    required BuildContext context,
  }) async {
    if (offset == 0) {
      walletHistoryState = WalletHistoryState.loading;
    } else {
      walletHistoryState = WalletHistoryState.loadingMore;
    }
    notifyListeners();

    try {
      params[ApiAndParams.limit] =
          Constant.defaultDataLoadLimitAtOnce.toString();
      params[ApiAndParams.offset] = offset.toString();

      // Add filter param if not 'all'
      if (currentFilter != 'all') {
        params[ApiAndParams.filter] = currentFilter;
      }

      Map<String, dynamic> getData =
          (await getWalletHistoryApi(context: context, params: params));

      // Support both response formats:
      // Old format: {"status": 1, "total": ..., "data": [...]}
      // New format: {"error": false, "total": ..., "data": [...]}
      final bool isSuccess =
          getData[ApiAndParams.status].toString() == "1" ||
              getData['error'] == false;

      if (isSuccess) {
        totalData = int.parse(getData[ApiAndParams.total].toString());
        List<WalletHistoryData> tempWalletHistories = (getData['data'] as List)
            .map((e) => WalletHistoryData.fromJson(Map.from(e)))
            .toList();

        walletHistories.addAll(tempWalletHistories);

        hasMoreData = totalData > walletHistories.length;
        if (hasMoreData) {
          offset += Constant.defaultDataLoadLimitAtOnce;
        }

        if (totalData > 0) {
          walletHistoryState = WalletHistoryState.loaded;
          notifyListeners();
        } else {
          walletHistoryState = WalletHistoryState.empty;
          notifyListeners();
        }
      } else {
        walletHistoryState = WalletHistoryState.empty;
        notifyListeners();
      }
    } catch (e) {
      message = e.toString();
      walletHistoryState = WalletHistoryState.error;
      showMessage(
        context,
        message,
        MessageType.warning,
      );
      notifyListeners();
    }
  }
}
