import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:provider/provider.dart';

class OrdersTabBar extends StatefulWidget {
  final int selectedIndex;
  final List<OrderTabData> tabs;
  final ValueChanged<int> onTabSelected;

  const OrdersTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  State<OrdersTabBar> createState() => _OrdersTabBarState();
}

class _OrdersTabBarState extends State<OrdersTabBar> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _tabKeys = [];
  int? _currentSelectedIndex;

  @override
  void initState() {
    super.initState();
    _currentSelectedIndex = widget.selectedIndex;
    _initializeKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant OrdersTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      setState(() {
        _currentSelectedIndex = widget.selectedIndex;
      });
    }

    if (oldWidget.tabs.length != widget.tabs.length) {
      _initializeKeys();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _initializeKeys() {
    _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
  }

  void _scrollToSelected() {
    if (!mounted || !_scrollController.hasClients) return;

    final selectedIndex = _currentSelectedIndex ?? widget.selectedIndex;
    if (selectedIndex >= _tabKeys.length || selectedIndex < 0) {
      return;
    }

    final key = _tabKeys[selectedIndex];
    final context = key.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    try {
      final scrollBox = _scrollController.position.context.storageContext
          .findRenderObject() as RenderBox?;
      if (scrollBox == null) return;

      final tabOffset = box.localToGlobal(Offset.zero, ancestor: scrollBox).dx;
      final tabWidth = box.size.width;
      final scrollWidth = scrollBox.size.width;
      final scrollOffset = _scrollController.offset;

      double target = scrollOffset + tabOffset + tabWidth / 2 - scrollWidth / 2;

      target = target.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        target,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      // Silently fail if scroll animation fails
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final selectedIndex = _currentSelectedIndex ?? widget.selectedIndex;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: colorScheme.cardShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: List.generate(widget.tabs.length, (i) {
            final isSelected = i == selectedIndex;
            final data = widget.tabs[i];

            return Padding(
              padding:
                  EdgeInsets.only(right: i < widget.tabs.length - 1 ? 10 : 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentSelectedIndex = i;
                    });
                    widget.onTabSelected(i);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    key: _tabKeys[i],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(0xFF9AC444)
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Color(0xFF9AC444) : colorScheme.border,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    Color(0xFF9AC444).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.textSecondary,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : Color(0xFF9AC444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${data.count}",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  isSelected ? Colors.white : Color(0xFF9AC444),
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class OrderTabData {
  final String title;
  final int count;
  const OrderTabData(this.title, this.count);
}
