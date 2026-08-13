import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/super_mart_category_models.dart';
import 'package:project/provider/super_mart_category_provider.dart';

class SuperMartCategoriesScreen extends StatefulWidget {
  const SuperMartCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<SuperMartCategoriesScreen> createState() =>
      _SuperMartCategoriesScreenState();
}

class _SuperMartCategoriesScreenState extends State<SuperMartCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch category groups on screen load
    Future.microtask(() {
      final sellerId = Constant.session.getData(SessionManager.keyUserId);
      context
          .read<SuperMartCategoryProvider>()
          .fetchCategoryGroups(sellerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<SuperMartCategoryProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Header with gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9AC444), Color(0xFFFFFFFF)],
                    stops: [0, 0.85],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 22,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Super Mart Categories",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  letterSpacing: -0.55,
                                  height: 1.15,
                                ),
                              ),
                              if (provider.storeName.isNotEmpty)
                                Text(
                                  provider.storeName,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Body
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9AC444),
                        ),
                      )
                    : provider.hasError
                        ? _buildErrorState(context, provider)
                        : provider.categoryGroups.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  final sellerId = Constant.session
                                      .getData(SessionManager.keyUserId);
                                  await provider.refresh(sellerId);
                                },
                                color: const Color(0xFF9AC444),
                                child: _buildCategoryGroupsList(
                                    provider.categoryGroups),
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryGroupsList(List<CategoryGrouping> categoryGroups) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: categoryGroups.length,
      itemBuilder: (context, index) {
        final categoryGroup = categoryGroups[index];
        return _CategoryGroupingCard(
          categoryGrouping: categoryGroup,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "No category groups yet",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Category groups will appear here",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, SuperMartCategoryProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final sellerId = Constant.session.getData(SessionManager.keyUserId);
              provider.fetchCategoryGroups(sellerId);
            },
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
}

/// Category Grouping Card (Main Group)
class _CategoryGroupingCard extends StatefulWidget {
  final CategoryGrouping categoryGrouping;

  const _CategoryGroupingCard({
    required this.categoryGrouping,
  });

  @override
  State<_CategoryGroupingCard> createState() => _CategoryGroupingCardState();
}

class _CategoryGroupingCardState extends State<_CategoryGroupingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Group Header
          InkWell(
            onTap: () {
              if (widget.categoryGrouping.subCategoryGroups.isNotEmpty) {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Group Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.categoryGrouping.imageUrl != null
                        ? Image.network(
                            widget.categoryGrouping.imageUrl!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  const SizedBox(width: 16),

                  // Group Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryGrouping.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${widget.categoryGrouping.subCategoryGroups.length} Groups",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.categoryGrouping.status == 1
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.categoryGrouping.status == 1
                                    ? "Active"
                                    : "Inactive",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: widget.categoryGrouping.status == 1
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse Icon
                  if (widget.categoryGrouping.subCategoryGroups.isNotEmpty)
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF9AC444),
                      size: 28,
                    ),
                ],
              ),
            ),
          ),

          // Sub Category Groups (Expandable)
          if (_isExpanded &&
              widget.categoryGrouping.subCategoryGroups.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFF3F4F6),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: widget.categoryGrouping.subCategoryGroups
                    .map((subGroup) => _SubCategoryGroupCard(
                          subGroup: subGroup,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.category_outlined,
        color: Color(0xFFB9B9B9),
        size: 32,
      ),
    );
  }
}

/// Sub Category Group Card
class _SubCategoryGroupCard extends StatelessWidget {
  final SubCategoryGroup subGroup;

  const _SubCategoryGroupCard({
    required this.subGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sub Group Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: subGroup.imageUrl != null
                ? Image.network(
                    subGroup.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 12),

          // Sub Group Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subGroup.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                if (subGroup.subcategoryIds != null &&
                    subGroup.subcategoryIds!.isNotEmpty)
                  Text(
                    "${subGroup.subcategoryIds!.split(',').length} Categories",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),

          // Forward Arrow
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.folder_outlined,
        color: Color(0xFFB9B9B9),
        size: 28,
      ),
    );
  }
}
