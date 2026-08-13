import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/driver_issue_model.dart';
import 'package:zenfoo_partner/providers/driver_issue_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class DriverIssuesScreen extends StatefulWidget {
  final String? fixedIssueType;

  const DriverIssuesScreen({super.key, this.fixedIssueType});

  @override
  State<DriverIssuesScreen> createState() => _DriverIssuesScreenState();
}

class _DriverIssuesScreenState extends State<DriverIssuesScreen> {
  final ScrollController _scrollController = ScrollController();

  // Filter tab: 0=Daily, 1=Weekly, 2=Monthly
  int _selectedTabIndex = 1;
  int _periodOffset = 0;
  String? _selectedStatus;
  String? _selectedIssueType;
  final Set<int> _expandedIds = {};

  bool get _isFixedType => widget.fixedIssueType != null;

  final List<Map<String, String>> _issueTypes = [
    {'value': 'incorrect_payout', 'label': 'Incorrect Payout'},
    {'value': 'incentive', 'label': 'Incentive'},
    {'value': 'multi_order', 'label': 'Multi-order'},
    {'value': 'joining_bonus', 'label': 'Joining Bonus'},
  ];

  String get _filterValue {
    switch (_selectedTabIndex) {
      case 0:
        return 'daily';
      case 1:
        return 'weekly';
      case 2:
        return 'monthly';
      default:
        return 'weekly';
    }
  }

  String get _periodLabel {
    final now = DateTime.now();

    switch (_selectedTabIndex) {
      case 0: // Daily
        final date = now.add(Duration(days: _periodOffset));
        if (_periodOffset == 0) return 'Today';
        if (_periodOffset == -1) return 'Yesterday';
        return DateFormat('dd MMM yyyy').format(date);

      case 1: // Weekly
        final weekStart =
            now.subtract(Duration(days: now.weekday - 1 + (-_periodOffset * 7)));
        final weekEnd = weekStart.add(const Duration(days: 6));
        if (_periodOffset == 0) return 'This Week';
        if (_periodOffset == -1) return 'Last Week';
        return '${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM').format(weekEnd)}';

      case 2: // Monthly
        final month = DateTime(now.year, now.month + _periodOffset);
        if (_periodOffset == 0) return 'This Month';
        if (_periodOffset == -1) return 'Last Month';
        return DateFormat('MMMM yyyy').format(month);

      default:
        return '';
    }
  }

  bool get _isCurrentPeriod => _periodOffset == 0;

  @override
  void initState() {
    super.initState();
    _selectedIssueType =
        widget.fixedIssueType ?? _issueTypes.first['value'];
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchIssues();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<DriverIssueProvider>().loadMore(
            filter: _filterValue,
            issueType: _selectedIssueType,
            status: _selectedStatus,
            periodOffset: _periodOffset,
          );
    }
  }

  void _fetchIssues() {
    context.read<DriverIssueProvider>().fetchIssues(
          filter: _filterValue,
          issueType: _selectedIssueType,
          status: _selectedStatus,
          periodOffset: _periodOffset,
        );
  }

  void _navigatePrevious() {
    HapticFeedback.lightImpact();
    setState(() => _periodOffset--);
    _fetchIssues();
  }

  void _navigateNext() {
    if (_isCurrentPeriod) return;
    HapticFeedback.lightImpact();
    setState(() => _periodOffset++);
    _fetchIssues();
  }

  void _onTabChanged(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTabIndex = index;
      _periodOffset = 0;
    });
    _fetchIssues();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('help_center'),
            title: languageProvider.getTranslatedText('my_issues'),
            showBackButton: true,
            showExitButton: false,
          ),

          // Daily / Weekly / Monthly Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildFilterTabs(colorScheme, languageProvider),
          ),

          // Period Navigation (left/right arrows)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildPeriodNavigation(colorScheme),
          ),

          // Issue Type + Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                if (!_isFixedType) ...[
                  _buildIssueTypeChip(colorScheme, languageProvider),
                  const SizedBox(width: 8),
                ],
                _buildStatusChip(colorScheme, languageProvider),
              ],
            ),
          ),

          // Issues List
          Expanded(
            child: Consumer<DriverIssueProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return _buildLoadingState(colorScheme);
                }

                if (provider.issuesResponse.status == 'error') {
                  return _buildErrorState(
                    colorScheme,
                    languageProvider,
                    provider.issuesResponse.message ?? '',
                  );
                }

                if (provider.issues.isEmpty) {
                  return _buildEmptyState(colorScheme, languageProvider);
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchIssues(),
                  color: colorScheme.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.issues.length +
                        (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.issues.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary),
                              ),
                            ),
                          ),
                        );
                      }

                      final issue = provider.issues[index];
                      return _buildIssueCard(issue, colorScheme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER TABS (Daily / Weekly / Monthly) ───

  Widget _buildFilterTabs(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    final tabs = [
      languageProvider.getTranslatedText('daily'),
      languageProvider.getTranslatedText('weekly'),
      languageProvider.getTranslatedText('monthly'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? Colors.white
                        : colorScheme.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── PERIOD NAVIGATION (Left / Right arrows) ───

  Widget _buildPeriodNavigation(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigatePrevious,
              borderRadius: BorderRadius.circular(17),
              child: Ink(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Period Label
          Expanded(
            child: Text(
              _periodLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.05,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Next
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCurrentPeriod ? null : _navigateNext,
              borderRadius: BorderRadius.circular(17),
              child: Ink(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _isCurrentPeriod
                      ? colorScheme.surfaceElevated.withValues(alpha: 0.5)
                      : colorScheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _isCurrentPeriod
                        ? colorScheme.textSecondary.withValues(alpha: 0.4)
                        : colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ISSUE TYPE CHIP ───

  Widget _buildIssueTypeChip(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() => _selectedIssueType = value);
        _fetchIssues();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      itemBuilder: (context) => _issueTypes
          .map((type) => PopupMenuItem(
                value: type['value']!,
                child: Text(
                  type['label']!,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 13,
                    fontWeight: _selectedIssueType == type['value']
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _issueTypes.firstWhere(
                  (t) => t['value'] == _selectedIssueType,
                  orElse: () => _issueTypes.first)['label']!,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // ─── STATUS CHIP ───

  Widget _buildStatusChip(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() => _selectedStatus = value == 'all' ? null : value);
        _fetchIssues();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      itemBuilder: (context) => [
        _buildStatusMenuItem(
            'all', 'all_status', colorScheme, languageProvider),
        _buildStatusMenuItem(
            'pending', 'pending', colorScheme, languageProvider),
        _buildStatusMenuItem(
            'resolved', 'resolved', colorScheme, languageProvider),
        _buildStatusMenuItem(
            'rejected', 'rejected', colorScheme, languageProvider),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _selectedStatus != null
              ? colorScheme.primary
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedStatus != null
                ? colorScheme.primary
                : colorScheme.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedStatus != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _selectedStatus != null
                  ? _selectedStatus![0].toUpperCase() +
                      _selectedStatus!.substring(1)
                  : languageProvider.getTranslatedText('status'),
              style: GoogleFonts.inter(
                color: _selectedStatus != null
                    ? Colors.white
                    : colorScheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: _selectedStatus != null
                  ? Colors.white
                  : colorScheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem(
    String value,
    String labelKey,
    AppColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    final isAll = value == 'all';
    final statusColor = !isAll ? _getStatusColor(value, colorScheme) : null;
    final isSelected =
        isAll ? _selectedStatus == null : _selectedStatus == value;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (statusColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            languageProvider.getTranslatedText(labelKey),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─── IMAGE VIEWER ───

  void _openImageViewer(
      List<String> images, int initialIndex, AppColorScheme colorScheme) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _ImageViewerDialog(
          images: images,
          initialIndex: initialIndex,
          colorScheme: colorScheme,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ─── ISSUE CARD (Expandable) ───

  Widget _buildIssueCard(DriverIssue issue, AppColorScheme colorScheme) {
    final statusColor = _getStatusColor(issue.status, colorScheme);
    final statusBgColor = _getStatusBgColor(issue.status, colorScheme);
    final isExpanded = _expandedIds.contains(issue.id);
    final hasExpandableContent = issue.description.isNotEmpty ||
        issue.issueIds.isNotEmpty ||
        issue.attachments.isNotEmpty ||
        (issue.adminMessage != null && issue.adminMessage!.isNotEmpty);

    return GestureDetector(
      onTap: hasExpandableContent
          ? () {
              HapticFeedback.lightImpact();
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(issue.id);
                } else {
                  _expandedIds.add(issue.id);
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? statusColor.withValues(alpha: 0.3)
                : colorScheme.border.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded
                  ? statusColor.withValues(alpha: 0.08)
                  : colorScheme.primary.withValues(alpha: 0.04),
              blurRadius: isExpanded ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Collapsed Header (always visible) ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: _getIssueIcon(issue.issueType),
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                issue.issueTypeDisplay,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                issue.status[0].toUpperCase() +
                                    issue.status.substring(1),
                                style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.tag,
                              size: 12,
                              color: colorScheme.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${issue.id}',
                              style: GoogleFonts.inter(
                                color: colorScheme.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: colorScheme.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(issue.createdAt),
                              style: GoogleFonts.inter(
                                color: colorScheme.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (hasExpandableContent) ...[
                              const Spacer(),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: colorScheme.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Expanded Content ──
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildExpandedContent(issue, colorScheme, statusColor),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
      DriverIssue issue, AppColorScheme colorScheme, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          color: colorScheme.border.withValues(alpha: 0.15),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              if (issue.description.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 15,
                      color: colorScheme.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.description,
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Issue IDs
              if (issue.issueIds.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.link,
                        size: 15,
                        color: colorScheme.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Related IDs',
                            style: GoogleFonts.inter(
                              color: colorScheme.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: issue.issueIds
                                .map((id) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: statusColor
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Text(
                                        '#$id',
                                        style: GoogleFonts.inter(
                                          color: colorScheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              // Attachments
              if (issue.attachments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 15,
                      color: colorScheme.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attachments (${issue.attachments.length})',
                      style: GoogleFonts.inter(
                        color: colorScheme.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: issue.attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openImageViewer(
                            issue.attachments, index, colorScheme),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.border.withValues(alpha: 0.2),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  issue.attachments[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: colorScheme.surfaceContainer,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 24,
                                      color: colorScheme.textTertiary,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.zoom_in,
                                        size: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Admin reply
              if (issue.adminMessage != null &&
                  issue.adminMessage!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.support_agent,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Response',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue.adminMessage!,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Updated at
              if (issue.updatedAt.isAfter(
                  issue.createdAt.add(const Duration(minutes: 1)))) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.update,
                      size: 12,
                      color: colorScheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${DateFormat('dd MMM, hh:mm a').format(issue.updatedAt)}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── COLORS & ICONS ───

  Color _getStatusColor(String status, AppColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return colorScheme.textSecondary;
    }
  }

  Color _getStatusBgColor(String status, AppColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'resolved':
        return const Color(0xFFDEFFEA);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return colorScheme.surfaceContainer;
    }
  }

  dynamic _getIssueIcon(String issueType) {
    switch (issueType) {
      case 'incorrect_payout':
        return HugeIcons.strokeRoundedCreditCard;
      case 'incentive':
        return HugeIcons.strokeRoundedGift;
      case 'multi_order':
        return HugeIcons.strokeRoundedDeliveryBox01;
      case 'joining_bonus':
        return HugeIcons.strokeRoundedMoney02;
      case 'order_earning':
        return HugeIcons.strokeRoundedMoneyReceive01;
      case 'pocketing_issue':
        return HugeIcons.strokeRoundedWallet01;
      case 'not_getting_order_issue':
        return HugeIcons.strokeRoundedClock02;
      default:
        return HugeIcons.strokeRoundedCustomerSupport;
    }
  }

  // ─── LOADING STATE ───

  Widget _buildLoadingState(AppColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.border.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: 160,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── ERROR STATE ───

  Widget _buildErrorState(AppColorScheme colorScheme,
      LanguageProvider languageProvider, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              languageProvider.getTranslatedText('something_went_wrong'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.isNotEmpty
                  ? message
                  : languageProvider
                      .getTranslatedText('failed_to_load_issues'),
              style: GoogleFonts.inter(
                  color: colorScheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _fetchIssues();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  languageProvider.getTranslatedText('retry'),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ───

  Widget _buildEmptyState(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: colorScheme.textSecondary.withValues(alpha: 0.4),
              size: 72,
            ),
            const SizedBox(height: 20),
            Text(
              languageProvider.getTranslatedText('no_issues_found'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                languageProvider.getTranslatedText('no_issues_description'),
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_selectedStatus != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedStatus = null;
                  });
                  _fetchIssues();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    languageProvider.getTranslatedText('clear_filters'),
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── FULL SCREEN IMAGE VIEWER ───

class _ImageViewerDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final AppColorScheme colorScheme;

  const _ImageViewerDialog({
    required this.images,
    required this.initialIndex,
    required this.colorScheme,
  });

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) =>
                setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load image',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Bottom dots indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
