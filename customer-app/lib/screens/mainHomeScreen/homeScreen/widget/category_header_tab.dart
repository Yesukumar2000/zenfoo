import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/models/category_groups.dart';
import 'package:project/repositories/ordersApi.dart';
import 'package:shimmer/shimmer.dart';
import 'package:velocity_x/velocity_x.dart';

Color colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final hexColor = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.parse(hexColor, radix: 16));
}

class CategoryHeaderTabBar extends StatefulWidget {
  final List<CategoryGroup> categories;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CategoryHeaderTabBar({
    Key? key,
    required this.categories,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CategoryHeaderTabBar> createState() => _CategoryHeaderTabBarState();
}

class _CategoryHeaderTabBarState extends State<CategoryHeaderTabBar> {
  late ScrollController _scrollController;
  final Map<int, GlobalKey> _itemKeys = {};
  String? _allStoresImgUrl;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    for (int i = 0; i < widget.categories.length; i++) {
      _itemKeys[i] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    _fetchAllStoresImg();
  }

  Future<void> _fetchAllStoresImg() async {
    try {
      final response =
          await fetchAppMedia(context: context, type: 'all_stores_img');
      if (response['status'] == 1 && response['data'] != null) {
        final imgUrl = response['data']['all_stores_img'];
        if (imgUrl != null && imgUrl.toString().isNotEmpty && mounted) {
          setState(() => _allStoresImgUrl = imgUrl.toString());
        }
      }
    } catch (e) {
      debugPrint("Error fetching all_stores_img: $e");
    }
  }

  @override
  void didUpdateWidget(CategoryHeaderTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.categories.length != widget.categories.length) {
      if (oldWidget.categories.length != widget.categories.length) {
        _itemKeys.clear();
        for (int i = 0; i < widget.categories.length; i++) {
          _itemKeys[i] = GlobalKey();
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final key = _itemKeys[widget.selectedIndex];
    if (key?.currentContext == null) return;

    final renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final itemWidth = renderBox.size.width;
    final screenWidth = MediaQuery.of(context).size.width;

    final targetOffset = _scrollController.offset +
        position.dx -
        (screenWidth / 2) +
        (itemWidth / 2);

    final maxScroll = _scrollController.position.maxScrollExtent;
    final minScroll = _scrollController.position.minScrollExtent;

    _scrollController.animateTo(
      targetOffset.clamp(minScroll, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Approx. width a single tab needs (item minWidth + its horizontal margins).
    const double estimatedItemWidth = 56 + 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsWithoutScroll = widget.categories.isNotEmpty &&
            (widget.categories.length * estimatedItemWidth) <=
                constraints.maxWidth;

        if (fitsWithoutScroll) {
          // Distribute all tabs evenly across the full width: no horizontal
          // scroll and no empty space beside the last tab (e.g. "Food").
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                widget.categories.length,
                (idx) => Expanded(child: _buildTab(idx)),
              ),
            ),
          );
        }

        // Fallback for many categories: keep the scrollable strip.
        return ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
          itemCount: widget.categories.length,
          itemBuilder: (context, idx) => _buildTab(idx),
        );
      },
    );
  }

  Widget _buildTab(int idx) {
    final group = widget.categories[idx];
    final isSelected = (widget.selectedIndex == idx);
    final catColor = colorFromHex(group.color ?? "#9AC444");

    final Widget iconWidget = group.iconUrl?.isNotEmpty == true
        ? CachedNetworkImage(
            imageUrl: group.iconUrl!,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            color: isSelected ? catColor : const Color(0xFF6B6B6B),
            colorBlendMode: BlendMode.srcIn,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: const Color(0xFFE0E0E0),
              highlightColor: const Color(0xFFF5F5F5),
              child: Container(width: 32, height: 32, color: Colors.white),
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.category_outlined,
              size: 32,
              color: isSelected ? catColor : const Color(0xFF6B6B6B),
            ),
          )
        : Icon(
            Icons.category_outlined,
            size: 32,
            color: isSelected ? catColor : const Color(0xFF6B6B6B),
          );

    return Padding(
      key: _itemKeys[idx],
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _TabBarItem(
        icon: idx == 0
            ? _allStoresImgUrl != null
                ? CachedNetworkImage(
                    imageUrl: _allStoresImgUrl!,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE0E0E0),
                      highlightColor: const Color(0xFFF5F5F5),
                      child: Container(
                          width: 45, height: 45, color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/animations/home_tab.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    'assets/animations/home_tab.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  )
            : iconWidget,
        label: group.name,
        selected: isSelected,
        accentColor: catColor,
        onTap: () => widget.onTap(idx),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TabBarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        // width can be fixed or min; using min makes it flexible
        constraints: const BoxConstraints(minWidth: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min, // flex height with content
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with flexible size
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                // color: selected
                //     ? accentColor.withOpacity(0.12)
                //     : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedScale(
                scale: selected ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: icon,
              ),
            ),
            const SizedBox(height: 2),
            // Label with flexible height
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.inter(
                color: selected ? accentColor : const Color(0xFF6B6B6B),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                height: 1.02,
                letterSpacing: -0.55,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ).w(56),
            ),
            const SizedBox(height: 4),
            // Bottom indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: selected ? 48 : 0,
              height: 3.5,
              decoration: BoxDecoration(
                color: selected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
