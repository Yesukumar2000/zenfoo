import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/report.dart';

enum ReportsState { initial, loading, loaded, loadingMore, error, empty }

enum ReportFilterType { all, pending, resolved }

class ReportsProvider extends ChangeNotifier {
  ReportsState _state = ReportsState.initial;
  ReportsState get state => _state;

  ReportFilterType _filterType = ReportFilterType.all;
  ReportFilterType get filterType => _filterType;

  List<Report> _reports = [];
  List<Report> get reports => _reports;

  // API now handles filtering, so just return all reports
  List<Report> get filteredReports => _reports;

  String _message = '';
  String get message => _message;

  int _offset = 0;
  int get offset => _offset;

  int _total = 0;
  int get total => _total;

  bool get hasMoreData => _reports.length < _total;

  void setFilterType(ReportFilterType type, BuildContext context) {
    if (_filterType != type) {
      _filterType = type;
      fetchReports(context: context, isReset: true);
    }
  }

  Future<void> fetchReports({
    required BuildContext context,
    bool isReset = false,
  }) async {
    try {
      if (isReset) {
        _offset = 0;
        _reports = [];
        _state = ReportsState.loading;
      } else {
        _state = ReportsState.loadingMore;
      }
      notifyListeners();

      // Calculate page number from offset
      int page = (_offset ~/ 10) + 1;

      // Build params based on filter type
      Map<String, dynamic> params = {
        'page': page.toString(),
        'per_page': '10',
      };

      // Add status filter based on filter type
      if (_filterType == ReportFilterType.pending) {
        params['status'] = '0';
      } else if (_filterType == ReportFilterType.resolved) {
        params['status'] = '2';
      }
      // For 'all', don't add status parameter

      final response = await sendApiRequest(
        apiName: 'issue_report/reports',
        params: params,
        isPost: false,
        context: context,
      );

      final data = json.decode(response);

      if (data['status'] == 1) {
        _total = int.parse(data['total']?.toString() ?? '0');

        List<Report> newReports = [];
        if (data['data'] != null) {
          newReports = (data['data']['reports'] as List)
              .map((item) => Report.fromJson(item))
              .toList();
        }

        _reports.addAll(newReports);
        _offset += newReports.length;

        _state = _reports.isEmpty ? ReportsState.empty : ReportsState.loaded;
      } else {
        _message = data['message'] ?? 'Failed to load reports';
        _state = ReportsState.error;
      }
    } catch (e) {
      _message = e.toString();
      _state = ReportsState.error;
    }
    notifyListeners();
  }
}
