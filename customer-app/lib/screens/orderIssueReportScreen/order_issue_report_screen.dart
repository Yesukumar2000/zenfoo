import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/screens/orderIssueReportScreen/select_issue_type_screen.dart';

class OrderIssueReportScreen extends StatefulWidget {
  final String orderId;

  const OrderIssueReportScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderIssueReportScreen> createState() => _OrderIssueReportScreenState();
}

class _OrderIssueReportScreenState extends State<OrderIssueReportScreen> {
  bool isLoading = true;
  Map<String, dynamic>? issueData;
  Set<String> selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _fetchIssueReportData();
  }

  Future<void> _fetchIssueReportData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await sendApiRequest(
        apiName: 'issue_report/order_items',
        params: {'order_id': widget.orderId},
        isPost: false,
        context: context,
      );

      final data = json.decode(response);

      log('Issue Report API Response: ${json.encode(data)}');

      if (data['status'] == 1) {
        setState(() {
          issueData = data['message'];
          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load issue report data');
      }
    } catch (e) {
      log('Error fetching issue report data: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showMessage(
          context,
          getTranslatedValue(context, failedToLoadIssueReportLabel),
          MessageType.error,
        );
      }
    }
  }

  List<IssueOption> _getIssueOptions() {
    if (issueData == null) return [];

    List<IssueOption> options = [];

    // Check if has_combos is true
    if (issueData!['has_combos'] == true) {
      options.add(IssueOption(
        id: 'combos',
        label: 'Combos',
        type: 'combos',
      ));
    }

    // Check if has_zenfoo is true
    if (issueData!['has_zenfoo'] == true) {
      options.add(IssueOption(
        id: 'zenfoo',
        label: 'Zenfoo Store',
        type: 'zenfoo',
      ));
    }

    // Add vendor-specific options
    if (issueData!['vendors'] != null &&
        (issueData!['vendors'] as List).isNotEmpty) {
      for (var vendor in issueData!['vendors']) {
        options.add(IssueOption(
          id: 'vendor_${vendor['id']}',
          label: vendor['name'],
          type: 'vendor',
          vendorId: vendor['id'],
        ));
      }
    }

    return options;
  }

  void _handleOptionSelect(String optionId) {
    setState(() {
      if (selectedOptions.contains(optionId)) {
        selectedOptions.remove(optionId);
      } else {
        selectedOptions.add(optionId);
      }
    });

    log('Selected options: ${selectedOptions.join(", ")}');
  }

  void _handleSelectAll() {
    setState(() {
      final allOptions = _getIssueOptions();
      if (selectedOptions.length == allOptions.length) {
        // All selected, deselect all
        selectedOptions.clear();
      } else {
        // Select all
        selectedOptions = allOptions.map((opt) => opt.id).toSet();
      }
    });
  }

  void _handleContinue() {
    if (selectedOptions.isEmpty) {
      showMessage(
        context,
        getTranslatedValue(context, selectAtLeastOneOptionLabel),
        MessageType.warning,
      );
      return;
    }

    final selectedLabels = _getIssueOptions()
        .where((opt) => selectedOptions.contains(opt.id))
        .map((opt) => opt.label)
        .join(', ');

    log('Continue with selections: $selectedLabels');

    // Navigate to issue type selection screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectIssueTypeScreen(
          orderId: widget.orderId,
          selectedOptions: selectedOptions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Scaffold(
          backgroundColor: colorScheme.background,
          body: Column(
            children: [
              AppHeader(
                label: 'Order #${widget.orderId}',
                title: getTranslatedValue(context, reportIssueLabel),
                showBackButton: true,
              ),
              Expanded(
                child: isLoading
                    ? _buildShimmerLoading(colorScheme)
                    : issueData == null
                        ? _buildErrorState(colorScheme)
                        : _buildIssueOptions(colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                const CustomShimmer(
                  height: 24,
                  width: 180,
                  borderRadius: 8,
                ),
                const SizedBox(height: 24),
                // Option shimmers
                ...List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: const CustomShimmer(
                              height: 16,
                              width: double.infinity,
                              borderRadius: 6,
                            ),
                          ),
                          const SizedBox(width: 16),
                          CustomShimmer(
                            height: 20,
                            width: 20,
                            borderRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              getTranslatedValue(context, failedToLoadIssueReportLabel),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getTranslatedValue(context, pleaseRetryLabel),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.textSecondary,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchIssueReportData,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                getTranslatedValue(context, retryLabel),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.55,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueOptions(AppColorScheme colorScheme) {
    final options = _getIssueOptions();

    if (options.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 64,
              color: colorScheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              getTranslatedValue(context, noOptionsAvailableLabel),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Select All button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getTranslatedValue(context, selectOptionsLabel),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.55,
                    height: 1.4,
                  ),
                ),
                TextButton(
                  onPressed: _handleSelectAll,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    selectedOptions.length == options.length
                        ? getTranslatedValue(context, deselectAllLabel)
                        : getTranslatedValue(context, selectAllLabel),
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.55,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Options list
            ...List.generate(
              options.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < options.length - 1 ? 16 : 0,
                ),
                child: _buildOptionItem(
                  options[index],
                  colorScheme,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedOptions.isEmpty ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colorScheme.buttonDisabledBackground,
                  disabledForegroundColor: colorScheme.buttonDisabledText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  selectedOptions.isEmpty
                      ? getTranslatedValue(context, selectAtLeastOneOptionButtonLabel)
                      : '${getTranslatedValue(context, continueLabel)} (${selectedOptions.length} ${getTranslatedValue(context, selectedLabel)})',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.55,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(IssueOption option, AppColorScheme colorScheme) {
    final isSelected = selectedOptions.contains(option.id);

    return GestureDetector(
      onTap: () => _handleOptionSelect(option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.label,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.55,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.borderStrong,
                  width: 2,
                ),
                color: isSelected ? colorScheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class IssueOption {
  final String id;
  final String label;
  final String type;
  final int? vendorId;

  IssueOption({
    required this.id,
    required this.label,
    required this.type,
    this.vendorId,
  });
}
