import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart'
    hide CategoryListProvider;
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/helper/widgets/instructional_info_card.dart';
import 'package:project/models/category_model.dart';
import 'package:project/provider/category_add_provider.dart';
import 'package:project/provider/category_list_provider.dart';
import 'package:project/screens/categoryScreen/add_category_screen.dart';
import 'package:project/screens/categoryScreen/admin_managed_categories_screen.dart';
import 'package:project/screens/categoryScreen/three_stage_stepper_screen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    if (Constant.session.getManagedByAdmin()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminManagedCategoriesScreen(),
          ),
        );
      });
    } else {
      Future.microtask(() {
        context.read<CategoryListProvider>().fetchCategories(isRefresh: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (Constant.session.getManagedByAdmin()) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF9AC444),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Consumer<CategoryListProvider>(
        builder: (context, provider, _) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: AppHeader(
                    label: "Categories",
                    title: "Manage Your Categories",
                    showBackButton: true,
                    trailing: _buildHeaderActions(context),
                  ),
                ),
              ];
            },
            body: RefreshIndicator(
              onRefresh: () => provider.fetchCategories(isRefresh: true),
              color: const Color(0xFF9AC444),
              backgroundColor: colorScheme.cardBackground,
              child: Builder(
                builder: (context) {
                  // Loading state
                  if (provider.isLoading && provider.categories.isEmpty) {
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ShimmerCategoryCard(),
                                );
                              },
                              childCount: 5,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Error state
                  if (provider.hasError && provider.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.iconSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: colorScheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => provider.fetchCategories(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9AC444),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Retry",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Empty state
                  if (provider.categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 80,
                            color: colorScheme.iconSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No categories yet",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Constant.session.getManagedByAdmin()
                                ? "Categories are managed by admin"
                                : "Add your first category to get started",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!Constant.session.getManagedByAdmin())
                            ElevatedButton.icon(
                              onPressed: () => _navigateToAddCategory(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9AC444),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                "Add Category",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  // List with categories
                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent * 0.9) {
                        provider.loadMoreCategories();
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      slivers: [
                        if (Constant.session.getIsSweetHouse())
                          SliverToBoxAdapter(
                            child: InstructionalInfoCard(
                              title: "How Food Categories Work",
                              description:
                                  "Tap to learn how to organize your menu",
                              primaryColor: const Color(0xFF9AC444),
                              initiallyExpanded: false,
                              steps: const [
                                InstructionalStep(
                                  title: "Create Main Categories",
                                  description:
                                      "Start by adding main categories like Starters, Main Course, Desserts, Beverages, etc.",
                                  icon: Icons.restaurant_menu,
                                  example:
                                      "Example: Starters, Biryani, Curries, Desserts",
                                ),
                                InstructionalStep(
                                  title: "Add Category Types",
                                  description:
                                      "Within each category, you can add types to further classify your items (Veg, Non-Veg, etc.).",
                                  icon: Icons.category_outlined,
                                  example:
                                      "In Starters → Add 'Veg Starters' and 'Non-Veg Starters'",
                                ),
                                InstructionalStep(
                                  title: "Add Food Items",
                                  description:
                                      "Finally, add individual food items under each type. Customers will see them organized this way.",
                                  icon: Icons.add_circle_outline,
                                  example:
                                      "Under Starters → Add 'Paneer Tikka', 'Spring Rolls', etc.",
                                ),
                              ],
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final category = provider.categories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CategoryListCard(
                                    category: category,
                                    showActions:
                                        !Constant.session.getManagedByAdmin(),
                                    onEdit: () => _navigateToEditCategory(
                                        context, category),
                                    onDelete: () => _showDeleteConfirmation(
                                        context, category),
                                  ),
                                );
                              },
                              childCount: provider.categories.length,
                            ),
                          ),
                        ),
                        if (provider.isLoadingMore)
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                color: Color(0xFF9AC444),
                              ),
                            ),
                          ),
                        if (!provider.hasMorePages &&
                            provider.categories.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: Text(
                                "No more categories",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget? _buildHeaderActions(BuildContext context) {
    if (Constant.session.getManagedByAdmin()) {
      return null;
    }

    if (!Constant.session.getIsSweetHouse()) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _navigateToAddCategory(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF9AC444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Add",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showThreeStageMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF9AC444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.layers_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Organize",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _navigateToAddCategory(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF9AC444),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              "Add",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThreeStageMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => CategoryListProvider()),
          ],
          child: const ThreeStageCategoryStepperScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToAddCategory(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCategoryScreen(),
      ),
    );

    if (result == true && mounted) {
      context.read<CategoryListProvider>().fetchCategories(isRefresh: true);
    }
  }

  Future<void> _navigateToEditCategory(
      BuildContext context, CategoryModel category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(category: category),
      ),
    );

    if (result == true && mounted) {
      context.read<CategoryListProvider>().fetchCategories(isRefresh: true);
    }
  }

  void _showDeleteConfirmation(BuildContext context, CategoryModel category) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 48,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Delete ${category.name}?",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to delete this category? This action cannot be undone.",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                    height: 1.5,
                    letterSpacing: -0.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: colorScheme.border,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(bottomSheetContext);
                          await _deleteCategory(context, category);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Delete",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(
      BuildContext context, CategoryModel category) async {
    if (category.id == null) return;

    try {
      final categoryProvider = CategoryAddProvider(category: category);
      final success = await categoryProvider.deleteCategory(context);

      if (success) {
        if (mounted) {
          context.read<CategoryListProvider>().removeCategory(category.id!);
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Error deleting category: $e', MessageType.error);
      }
    }
  }
}

class _CategoryListCard extends StatelessWidget {
  final CategoryModel category;
  final bool showActions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListCard({
    required this.category,
    required this.showActions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.border, width: 1),
                color: colorScheme.surfaceVariant,
                boxShadow: colorScheme.cardShadow),
            clipBehavior: Clip.antiAlias,
            child: category.imageUrl != null
                ? setNetworkImg(
                    image: category.imageUrl!,
                    width: 90,
                    height: 90,
                    boxFit: BoxFit.cover,
                  )
                : Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: colorScheme.iconSecondary,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.55,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  category.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: category.status == 1
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: category.status == 1
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        category.status == 1 ? "Active" : "Inactive",
                        style: GoogleFonts.inter(
                          color: category.status == 1
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9AC444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF9AC444).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF9AC444),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ShimmerCategoryCard extends StatefulWidget {
  const _ShimmerCategoryCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerCategoryCard> createState() => _ShimmerCategoryCardState();
}

class _ShimmerCategoryCardState extends State<_ShimmerCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerGradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.surfaceVariant,
            colorScheme.surface,
            colorScheme.surfaceVariant,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: shimmerGradient,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: shimmerGradient,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: double.infinity * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: shimmerGradient,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 28,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: shimmerGradient,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: shimmerGradient,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: shimmerGradient,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
