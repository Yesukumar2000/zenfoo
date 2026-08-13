import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/chatProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/screens/orderIssueReportScreen/select_missing_items_screen.dart';
import 'package:project/screens/customerSupportScreen/customerSupportChatScreen.dart';

class SelectIssueTypeScreen extends StatefulWidget {
  final String orderId;
  final Set<String> selectedOptions;

  const SelectIssueTypeScreen({
    super.key,
    required this.orderId,
    required this.selectedOptions,
  });

  @override
  State<SelectIssueTypeScreen> createState() => _SelectIssueTypeScreenState();
}

class _SelectIssueTypeScreenState extends State<SelectIssueTypeScreen> {
  String? selectedIssueType;

  List<IssueType> _getIssueTypes(BuildContext context) {
    return [
      IssueType(
        id: 'item_missing',
        labelKey: itemMissingLabel,
      ),
      IssueType(
        id: 'wrong_order',
        labelKey: wrongOrderReceivedLabel,
      ),
      IssueType(id: 'return', labelKey: returnItem),
      IssueType(
        id: 'misbehavior',
        labelKey: misbehaviorOrHarassmentLabel,
      ),
      IssueType(
        id: 'complaint',
        labelKey: fileComplaintLabel,
      ),
      IssueType(
        id: 'others',
        labelKey: othersLabel,
      ),
    ];
  }

  void _handleIssueTypeSelect(String issueTypeId) {
    setState(() {
      selectedIssueType = issueTypeId;
    });

    log('Selected issue type: $issueTypeId');
  }

  void _handleContinue() {
    if (selectedIssueType == null) {
      showMessage(
        context,
        getTranslatedValue(context, pleaseSelectIssueTypeLabel),
        MessageType.warning,
      );
      return;
    }

    final issueTypes = _getIssueTypes(context);
    final selectedType =
        issueTypes.firstWhere((type) => type.id == selectedIssueType);

    log('Continue with issue type: ${selectedType.labelKey}');
    log('Selected options from previous screen: ${widget.selectedOptions.join(", ")}');

    // Navigate to appropriate screen based on issue type
    if (selectedIssueType == 'item_missing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectMissingItemsScreen(
            orderId: widget.orderId,
            selectedOptions: widget.selectedOptions,
            issueType: selectedIssueType!,
          ),
        ),
      );
    } else if (selectedIssueType == 'wrong_order') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectMissingItemsScreen(
            orderId: widget.orderId,
            selectedOptions: widget.selectedOptions,
            issueType: selectedIssueType!,
          ),
        ),
      );
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => SelectWrongItemsScreen(
      //       orderId: widget.orderId,
      //       selectedOptions: widget.selectedOptions,
      //       issueType: selectedIssueType!,
      //     ),
      //   ),
      // );
    }  else if (selectedIssueType == 'return') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectMissingItemsScreen(
            orderId: widget.orderId,
            selectedOptions: widget.selectedOptions,
            issueType: selectedIssueType!,
          ),
        ),
      );
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => SelectWrongItemsScreen(
      //       orderId: widget.orderId,
      //       selectedOptions: widget.selectedOptions,
      //       issueType: selectedIssueType!,
      //     ),
      //   ),
      // );
    } else {
      // For other issue types (misbehavior, complaint, others), open customer support chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider<ChatProvider>(
                create: (context) => ChatProvider(),
              ),
            ],
            child: CustomerSupportChatScreen(
              orderId: widget.orderId,
            ),
          ),
        ),
      );
    }
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
                title: getTranslatedValue(context, selectIssueTypeLabel),
                showBackButton: true,
              ),
              Expanded(
                child: _buildIssueTypes(context, colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIssueTypes(BuildContext context, AppColorScheme colorScheme) {
    final issueTypes = _getIssueTypes(context);
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
            // Title
            Text(
              getTranslatedValue(context, selectYourIssueLabel),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Issue types list
            ...List.generate(
              issueTypes.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < issueTypes.length - 1 ? 16 : 0,
                ),
                child: _buildIssueTypeItem(
                  issueTypes[index],
                  colorScheme,
                  context,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedIssueType == null ? null : _handleContinue,
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
                  selectedIssueType == null
                      ? getTranslatedValue(context, selectIssueTypeButtonLabel)
                      : getTranslatedValue(context, continueLabel),
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

  Widget _buildIssueTypeItem(
      IssueType issueType, AppColorScheme colorScheme, BuildContext context) {
    final isSelected = selectedIssueType == issueType.id;

    return GestureDetector(
      onTap: () => _handleIssueTypeSelect(issueType.id),
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
                getTranslatedValue(context, issueType.labelKey),
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
                shape: BoxShape.circle,
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
                      size: 14,
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

class IssueType {
  final String id;
  final String labelKey;

  IssueType({
    required this.id,
    required this.labelKey,
  });
}
