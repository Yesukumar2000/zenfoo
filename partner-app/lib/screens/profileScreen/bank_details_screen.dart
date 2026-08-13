import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/bank_model.dart';
import 'package:project/provider/bank_details_provider.dart';
import 'package:project/screens/profileScreen/add_edit_bank_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({Key? key}) : super(key: key);

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BankDetailsProvider>(context, listen: false);
      provider.fetchBankAccounts(
          Constant.session.getData(SessionManager.keyStoreId));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Consumer<BankDetailsProvider>(
        builder: (context, provider, child) {
          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return AppHeader(
                        label: getTranslatedValue(context, bankAccountsLabel),
                        title: getTranslatedValue(context, manageYourBankDetailsLabel),
                        showBackButton: true,
                      );
                    },
                  ),
                ),
              ];
            },
            body: RefreshIndicator(
              onRefresh: () => provider.fetchBankAccounts(
                  Constant.session.getData(SessionManager.keyStoreId)),
              color: ColorsRes.appColor,
              backgroundColor: colorScheme.cardBackground,
              child: Builder(
                builder: (context) {
                  if (provider.isLoading && provider.bankAccounts.isEmpty) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) => const _ShimmerBankCard(),
                    );
                  }

                  if (provider.bankAccounts.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.bankAccounts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.bankAccounts.length) {
                        return const SizedBox(height: 20);
                      }
                      return _buildBankCard(
                          context, provider.bankAccounts[index], provider);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems(
      BuildContext context, BankModel bank, dynamic colorScheme) {
    return [
      PopupMenuItem(
        value: 'edit',
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Row(
              children: [
                Icon(Icons.edit_rounded, size: 20, color: Colors.blue[600]),
                const SizedBox(width: 12),
                Text(
                  getTranslatedValue(context, editLabel),
                  style: TextStyle(color: colorScheme.textPrimary),
                ),
              ],
            );
          },
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Row(
              children: [
                Icon(Icons.delete_rounded, size: 20, color: Colors.red[600]),
                const SizedBox(width: 12),
                Text(
                  getTranslatedValue(context, deleteLabel),
                  style: TextStyle(color: colorScheme.textPrimary),
                ),
              ],
            );
          },
        ),
      ),
    ];
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Icon(
                        Icons.account_balance_outlined,
                        size: 56,
                        color: colorScheme.iconSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      getTranslatedValue(context, noBankAccountsLabel),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getTranslatedValue(context, noBankAccountMessageLabel),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _navigateToAddEdit(context, null);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: ColorsRes.appColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,
                                spreadRadius: 0,
                                color: ColorsRes.appColor.withValues(alpha: 0.25),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslatedValue(context, addBankAccountLabel),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBankCard(
      BuildContext context, BankModel bank, BankDetailsProvider provider) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorsRes.appColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ColorsRes.appColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: ColorsRes.appColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.bankName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bank.accountHolderName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: colorScheme.iconSecondary,
                    ),
                  ),
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  offset: const Offset(0, 8),
                  onSelected: (value) {
                    HapticFeedback.lightImpact();
                    if (value == 'edit') {
                      _navigateToAddEdit(context, bank);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, bank, provider);
                    } else if (value == 'set_default') {
                      _setAsDefault(context, bank, provider);
                    }
                  },
                  itemBuilder: (context) => _buildPopupMenuItems(context, bank, colorScheme),
                ),
              ],
            ),
          ),
          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Column(
                  children: [
                    _buildInfoRow(
                      context: context,
                      icon: Icons.credit_card_rounded,
                      labelKey: accountNumberLabel,
                      value: _maskAccountNumber(bank.accountNumber),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: colorScheme.border,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.business_rounded,
                      labelKey: ifscCodeLabel,
                      value: bank.ifscCode,
                    ),
                    if (bank.documentType != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: colorScheme.border,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.description_rounded,
                        labelKey: documentTypeLabel,
                        value: _formatDocumentType(bank.documentType!),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String labelKey,
    required String value,
  }) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: colorScheme.iconSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslatedValue(context, labelKey),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                  letterSpacing: 0.3,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDocumentType(String type) {
    switch (type.toLowerCase()) {
      case 'cheque':
        return 'Cancelled Cheque';
      case 'statement':
        return 'Bank Statement';
      case 'passbook':
        return 'Passbook';
      default:
        return type;
    }
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return 'XXXX${accountNumber.substring(accountNumber.length - 4)}';
  }

  void _navigateToAddEdit(BuildContext context, BankModel? bank) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: Provider.of<BankDetailsProvider>(context, listen: false),
          child: AddEditBankScreen(bank: bank),
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        Provider.of<BankDetailsProvider>(context, listen: false)
            .fetchBankAccounts(
                Constant.session.getData(SessionManager.keyStoreId));
      }
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, BankModel bank, BankDetailsProvider provider) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              getTranslatedValue(context, deleteBankAccountLabel),
              style: TextStyle(color: colorScheme.textPrimary),
            ),
            content: Text(
              '${getTranslatedValue(context, areYouSureDeleteBankLabel)}\n\n${bank.bankName}\n${bank.accountNumber}',
              style: TextStyle(color: colorScheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  getTranslatedValue(context, cancelLabel),
                  style: TextStyle(color: colorScheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await provider.deleteBankAccount(
                    context,
                    Constant.session.getData(SessionManager.keyStoreId),
                    bank.id!,
                  );
                },
                child: Text(
                  getTranslatedValue(context, deleteLabel),
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _setAsDefault(
      BuildContext context, BankModel bank, BankDetailsProvider provider) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              getTranslatedValue(context, setAsDefaultLabel),
              style: TextStyle(color: colorScheme.textPrimary),
            ),
            content: Text(
              '${getTranslatedValue(context, areYouSureSetDefaultBankLabel)}\n\n${bank.bankName}\n${bank.accountNumber}',
              style: TextStyle(color: colorScheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  getTranslatedValue(context, cancelLabel),
                  style: TextStyle(color: colorScheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await provider.setDefaultBankAccount(
                    context,
                    Constant.session.getData(SessionManager.keyStoreId),
                    bank.id!,
                  );
                },
                child: Text(
                  getTranslatedValue(context, setAsDefaultLabel),
                  style: TextStyle(color: ColorsRes.appColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShimmerBankCard extends StatefulWidget {
  const _ShimmerBankCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerBankCard> createState() => _ShimmerBankCardState();
}

class _ShimmerBankCardState extends State<_ShimmerBankCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerGradient = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              colorScheme.surfaceVariant,
              colorScheme.surface,
              colorScheme.surfaceVariant,
            ],
            stops: [
              _animation.value - 1,
              _animation.value,
              _animation.value + 1,
            ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            children: [
              // Header Section Shimmer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: shimmerGradient.copyWith(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: shimmerGradient.copyWith(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 12,
                            width: 120,
                            decoration: shimmerGradient.copyWith(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: shimmerGradient.copyWith(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              // Details Section Shimmer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildShimmerInfoRow(shimmerGradient),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: colorScheme.border,
                    ),
                    const SizedBox(height: 12),
                    _buildShimmerInfoRow(shimmerGradient),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: colorScheme.border,
                    ),
                    const SizedBox(height: 12),
                    _buildShimmerInfoRow(shimmerGradient),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerInfoRow(BoxDecoration shimmerGradient) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: shimmerGradient.copyWith(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                width: 80,
                decoration: shimmerGradient.copyWith(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 14,
                width: 150,
                decoration: shimmerGradient.copyWith(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
