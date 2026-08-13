import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/models/report.dart';
import 'package:project/screens/customerSupportScreen/customerSupportChatScreen.dart';

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Report get report => widget.report;

  // Status mapping: 0=Pending, 1=In Review, 2=Resolved, 3=Rejected, 4=Driver Assigned
  _StatusStyle _statusStyle(AppColorScheme cs) {
    switch (report.status ?? 0) {
      case 2:
        return _StatusStyle(
          label: getTranslatedValue(context, resolvedLabel),
          color: cs.success,
          icon: Icons.check_circle_rounded,
        );
      case 1:
        return _StatusStyle(
          label: getTranslatedValue(context, 'in_review'),
          color: cs.info,
          icon: Icons.hourglass_top_rounded,
        );
      case 3:
        return _StatusStyle(
          label: getTranslatedValue(context, 'rejected'),
          color: cs.error,
          icon: Icons.cancel_rounded,
        );
      case 4:
        return _StatusStyle(
          label: getTranslatedValue(context, 'driver_assigned'),
          color: cs.info,
          icon: Icons.delivery_dining_rounded,
        );
      default:
        return _StatusStyle(
          label: getTranslatedValue(context, pendingLabel),
          color: cs.warning,
          icon: Icons.schedule_rounded,
        );
    }
  }

  String _reportTypeDisplay() {
    switch ((report.reportType ?? '').toLowerCase()) {
      case 'wrong':
        return getTranslatedValue(context, 'wrong_item');
      case 'missing':
        return getTranslatedValue(context, 'missing_item');
      case 'return':
        return getTranslatedValue(context, 'return_item');
      case 'misbehavior':
        return getTranslatedValue(context, 'misbehavior');
      case 'complaint':
        return getTranslatedValue(context, 'complaint');
      case 'others':
        return getTranslatedValue(context, 'other_report_type');
      default:
        return report.reportType ?? 'N/A';
    }
  }

  IconData _reportTypeIcon() {
    switch ((report.reportType ?? '').toLowerCase()) {
      case 'wrong':
        return Icons.swap_horiz_rounded;
      case 'missing':
        return Icons.remove_shopping_cart_rounded;
      case 'return':
        return Icons.keyboard_return_rounded;
      case 'misbehavior':
        return Icons.report_gmailerrorred_rounded;
      case 'complaint':
        return Icons.feedback_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.watch<app_theme.ThemeProvider>().colorScheme;
    final bool isResolved = (report.status ?? 0) == 2;
    final images = _collectAllImages();
    final hasDriver = (report.driver != null &&
            (report.driver!.id != null || report.driver!.name != null)) ||
        (report.deliveryPartnerId != null &&
            report.deliveryPartnerId!.isNotEmpty);

    return Scaffold(
      backgroundColor: cs.background,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, supportLabel),
            title: getTranslatedValue(context, reportIssueLabel),
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(cs),
                  const SizedBox(height: 16),

                  if (isResolved &&
                      report.statusChangeJson != null &&
                      report.statusChangeJson!.isNotEmpty) ...[
                    _buildResolvedCard(cs),
                    const SizedBox(height: 16),
                  ],

                  if (report.supportNote != null &&
                      report.supportNote!.isNotEmpty) ...[
                    _buildNoteCard(cs),
                    const SizedBox(height: 16),
                  ],

                  if (report.storeWiseItems?.isNotEmpty ?? false) ...[
                    _sectionCard(
                      cs: cs,
                      icon: Icons.storefront_outlined,
                      title: getTranslatedValue(context, itemsByStoreLabel),
                      child: Column(
                        children: _withGaps(
                          report.storeWiseItems!
                              .map((s) => _buildStoreBlock(s, cs))
                              .toList(),
                          14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (report.comboItems?.isNotEmpty ?? false) ...[
                    _sectionCard(
                      cs: cs,
                      icon: Icons.inventory_2_outlined,
                      title: getTranslatedValue(context, comboItemsLabel),
                      child: Column(
                        children: _withGaps(
                          report.comboItems!
                              .map((c) => _buildComboBlock(c, cs))
                              .toList(),
                          14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (images.isNotEmpty) ...[
                    _sectionCard(
                      cs: cs,
                      icon: Icons.image_outlined,
                      title:
                          '${getTranslatedValue(context, 'attached_images')} (${images.length})',
                      child: _buildImagesGrid(images, cs,
                          heroPrefix: 'attached'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (report.statusChangeJson != null &&
                      report.statusChangeJson!.isNotEmpty) ...[
                    _sectionCard(
                      cs: cs,
                      icon: Icons.timeline_rounded,
                      title: getTranslatedValue(context, issueStatusLabel),
                      child: _buildTimeline(report.statusChangeJson!, cs),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _sectionCard(
                    cs: cs,
                    icon: Icons.person_outline_rounded,
                    title: getTranslatedValue(context, customerDetailsLabel),
                    child: Column(
                      children: [
                        _detailRow(
                          cs,
                          Icons.badge_outlined,
                          getTranslatedValue(context, nameLabel),
                          report.customer?.name ?? report.userName,
                        ),
                        _detailRow(
                          cs,
                          Icons.phone_outlined,
                          getTranslatedValue(context, phoneNumberLabel),
                          report.customer?.phone ?? report.userPhone,
                        ),
                        _detailRow(
                          cs,
                          Icons.mail_outline_rounded,
                          getTranslatedValue(context, emailAddressLabel),
                          report.customer?.email ?? report.userEmail,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  if (hasDriver) ...[
                    const SizedBox(height: 16),
                    _sectionCard(
                      cs: cs,
                      icon: Icons.delivery_dining_rounded,
                      title: getTranslatedValue(
                          context, deliveryPartnerDetailsLabel),
                      child: Column(
                        children: [
                          _detailRow(
                            cs,
                            Icons.tag_rounded,
                            getTranslatedValue(context, idLabel),
                            report.driver?.id ?? report.deliveryPartnerId,
                          ),
                          _detailRow(
                            cs,
                            Icons.person_pin_circle_outlined,
                            getTranslatedValue(context, nameLabel),
                            report.driver?.name ?? report.deliveryPartnerName,
                            isLast: !(report.driver?.deliveredAt != null &&
                                report.driver!.deliveredAt!.isNotEmpty),
                          ),
                          if (report.driver?.deliveredAt != null &&
                              report.driver!.deliveredAt!.isNotEmpty)
                            _detailRow(
                              cs,
                              Icons.event_available_outlined,
                              getTranslatedValue(context, deliveredAtLabel),
                              report.driver!.deliveredAt,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                  ],

                  if (report.driver?.deliveryImages != null &&
                      report.driver!.deliveryImages!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionCard(
                      cs: cs,
                      icon: Icons.photo_camera_back_outlined,
                      title:
                          '${getTranslatedValue(context, 'delivery_proof')} (${report.driver!.deliveryImages!.length})',
                      child: _buildImagesGrid(
                        report.driver!.deliveryImages!,
                        cs,
                        heroPrefix: 'delivery',
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _sectionCard(
                    cs: cs,
                    icon: Icons.receipt_long_outlined,
                    title: getTranslatedValue(context, reportIssueLabel),
                    child: Column(
                      children: [
                        _detailRow(
                          cs,
                          Icons.calendar_today_outlined,
                          getTranslatedValue(context, reportedOnLabel),
                          report.createdAt ?? report.reportedOn,
                        ),
                        _detailRow(
                          cs,
                          Icons.store_mall_directory_outlined,
                          getTranslatedValue(context, storeVendorLabel),
                          _storeVendorText(),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  if (isResolved) ...[
                    const SizedBox(height: 24),
                    _buildActionButtons(cs),
                  ],

                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      'ZENFOO',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: cs.textTertiary.withValues(alpha: 0.25),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SUMMARY (HERO) CARD =====================
  Widget _buildSummaryCard(AppColorScheme cs) {
    final status = _statusStyle(cs);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: cs.isDark ? 0.18 : 0.10),
            cs.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        boxShadow: cs.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslatedValue(context, orderIdLabel).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${report.orderNumber ?? report.orderId ?? getTranslatedValue(context, notAvailableLabel)}',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  cs,
                  _reportTypeIcon(),
                  getTranslatedValue(context, reportTypeLabel),
                  _reportTypeDisplay(),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: cs.border,
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Expanded(
                child: _miniInfo(
                  cs,
                  Icons.schedule_outlined,
                  getTranslatedValue(context, reportedOnLabel),
                  report.createdAt ?? report.reportedOn ?? '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(
      AppColorScheme cs, IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _statusPill(_StatusStyle status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: status.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 15, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== RESOLVED CARD =====================
  Widget _buildResolvedCard(AppColorScheme cs) {
    final resolved = report.statusChangeJson!.last;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.success.withValues(alpha: cs.isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.success.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: cs.success, size: 20),
              const SizedBox(width: 8),
              Text(
                getTranslatedValue(context, resolvedLabel),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: cs.success,
                ),
              ),
            ],
          ),
          if (resolved.message != null && resolved.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              resolved.message!,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.5,
                color: cs.textPrimary,
              ),
            ),
          ],
          if (resolved.refundAmount != null && resolved.refundAmount! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.success.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 18, color: cs.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '₹${resolved.refundAmount} ${getTranslatedValue(context, creditedToWalletLabel)}',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: cs.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (resolved.changedAt != null && resolved.changedAt!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: cs.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${getTranslatedValue(context, resolvedOnLabel)}: ${resolved.changedAt}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===================== SUPPORT NOTE =====================
  Widget _buildNoteCard(AppColorScheme cs) {
    return _sectionCard(
      cs: cs,
      icon: Icons.sticky_note_2_outlined,
      title: getTranslatedValue(context, supportNoteLabel),
      child: Text(
        report.supportNote ?? '',
        style: GoogleFonts.inter(
          fontSize: 13.5,
          height: 1.5,
          color: cs.textPrimary,
        ),
      ),
    );
  }

  // ===================== SECTION CARD SHELL =====================
  Widget _sectionCard({
    required AppColorScheme cs,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.border),
        boxShadow: cs.cardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ===================== DETAIL ROW =====================
  Widget _detailRow(
    AppColorScheme cs,
    IconData icon,
    String label,
    String? value, {
    bool isLast = false,
  }) {
    final display = (value == null || value.trim().isEmpty)
        ? getTranslatedValue(context, notAvailableLabel)
        : value;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: cs.iconSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: cs.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: cs.border),
          ),
      ],
    );
  }

  // ===================== STORE BLOCK =====================
  Widget _buildStoreBlock(ReportStoreWiseItem store, AppColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withValues(alpha: cs.isDark ? 0.4 : 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  store.storeName ?? 'Store',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (store.description != null && store.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _descriptionChip(store.description!, cs),
          ],
          if (store.items != null && store.items!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._buildItemRows(
              store.items!
                  .map((i) => _ItemRow(
                        name: i.productName ?? 'Product',
                        qty: i.quantity,
                        subTotal: i.subTotal,
                      ))
                  .toList(),
              cs,
            ),
          ],
        ],
      ),
    );
  }

  // ===================== COMBO BLOCK =====================
  Widget _buildComboBlock(ReportComboItem combo, AppColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withValues(alpha: cs.isDark ? 0.4 : 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  combo.comboName ?? 'Combo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.textPrimary,
                  ),
                ),
              ),
              if (combo.subTotal != null)
                Text(
                  '₹${combo.subTotal}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.textPrimary,
                  ),
                ),
            ],
          ),
          if (combo.comboQuantity != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                'X ${combo.comboQuantity}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.textSecondary,
                ),
              ),
            ),
          if (combo.description != null && combo.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _descriptionChip(combo.description!, cs),
          ],
          if (combo.products != null && combo.products!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._buildItemRows(
              combo.products!
                  .map((p) => _ItemRow(
                        name: p.productName ?? 'Product',
                        qty: p.quantity,
                        subTotal: p.subTotal,
                      ))
                  .toList(),
              cs,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildItemRows(List<_ItemRow> items, AppColorScheme cs) {
    final widgets = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'x${item.qty ?? 1}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: cs.textPrimary,
                ),
              ),
            ),
            if (item.subTotal != null)
              Text(
                '₹${item.subTotal}',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: cs.textPrimary,
                ),
              ),
          ],
        ),
      );
      if (i != items.length - 1) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, thickness: 1, color: cs.border),
        ));
      }
    }
    return widgets;
  }

  Widget _descriptionChip(String text, AppColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslatedValue(context, 'description'),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: cs.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TIMELINE =====================
  Widget _buildTimeline(List<ReportStatusChange> changes, AppColorScheme cs) {
    return Column(
      children: List.generate(changes.length, (index) {
        final c = changes[index];
        final isLast = index == changes.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cs.success.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded,
                        size: 16, color: cs.success),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: cs.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.statusName ?? 'Status Update',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.textPrimary,
                        ),
                      ),
                      if (c.message != null && c.message!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          c.message!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: cs.textSecondary,
                          ),
                        ),
                      ],
                      if (c.refundAmount != null && c.refundAmount! > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${getTranslatedValue(context, refundLabel)} ₹${c.refundAmount} ${getTranslatedValue(context, creditedToWalletLabel)}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: cs.success,
                          ),
                        ),
                      ],
                      if (c.changedAt != null && c.changedAt!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          c.changedAt!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: cs.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ===================== IMAGES GRID =====================
  Widget _buildImagesGrid(
    List<String> images,
    AppColorScheme cs, {
    String heroPrefix = 'img',
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onTap: () => _openImageViewer(image, cs),
          child: Hero(
            tag: '${heroPrefix}_$index',
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: cs.primary,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        imgErrorWidget(iconSize: 28),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_out_map_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openImageViewer(String imageUrl, AppColorScheme cs) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) =>
                    imgErrorWidget(iconSize: 40),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== ACTION BUTTONS =====================
  // "Re-Open Again" was removed: there is no reopen API, so the button
  // was non-functional. Only "Open Chat" (support) is shown.
  Widget _buildActionButtons(AppColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      child: _actionButton(
        label: getTranslatedValue(context, openChatLabel),
        filled: true,
        cs: cs,
        icon: Icons.chat_bubble_outline_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerSupportChatScreen(
                orderId: report.orderId ?? '',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool filled,
    required AppColorScheme cs,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final Color contentColor = filled ? cs.buttonPrimaryText : cs.primary;
    return Material(
      color: filled ? cs.primary : cs.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: cs.primary, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: contentColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== HELPERS =====================
  String _storeVendorText() {
    if (report.storeWiseItems != null && report.storeWiseItems!.isNotEmpty) {
      final names = report.storeWiseItems!
          .where((i) => i.storeName != null && i.storeName!.isNotEmpty)
          .map((i) => i.storeName!)
          .toList();
      if (names.isNotEmpty) return names.join(', ');
    }
    return report.storeVendor ?? '';
  }

  List<Widget> _withGaps(List<Widget> children, double gap) {
    final out = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i != children.length - 1) out.add(SizedBox(height: gap));
    }
    return out;
  }

  // Collect every image attached to this report. Customer-uploaded images are
  // stored per store / per combo (image_urls), not just on the top-level
  // `images` field, so we aggregate all of them here.
  List<String> _collectAllImages() {
    final images = <String>[];

    if (report.images != null) images.addAll(report.images!);

    if (report.storeWiseItems != null) {
      for (final store in report.storeWiseItems!) {
        if (store.imageUrls != null) images.addAll(store.imageUrls!);
      }
    }

    if (report.comboItems != null) {
      for (final combo in report.comboItems!) {
        if (combo.imageUrls != null) images.addAll(combo.imageUrls!);
      }
    }

    final seen = <String>{};
    return images
        .where((url) => url.trim().isNotEmpty && seen.add(url))
        .toList();
  }
}

// ===================== HELPER CLASSES =====================
class _StatusStyle {
  final String label;
  final Color color;
  final IconData icon;

  _StatusStyle({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _ItemRow {
  final String name;
  final String? qty;
  final String? subTotal;

  _ItemRow({required this.name, this.qty, this.subTotal});
}
