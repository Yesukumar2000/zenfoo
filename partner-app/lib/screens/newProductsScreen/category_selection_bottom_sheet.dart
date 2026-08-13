import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/models/category_selection_models.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class CategorySelectionBottomSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final Future<Map<String, dynamic>> Function(String? search, int page)
      fetchData;
  final Function(dynamic item) onItemSelected;
  final String? addNewLabel;
  final VoidCallback? onAddNew;

  const CategorySelectionBottomSheet({
    Key? key,
    required this.title,
    required this.searchHint,
    required this.fetchData,
    required this.onItemSelected,
    this.addNewLabel,
    this.onAddNew,
  }) : super(key: key);

  @override
  State<CategorySelectionBottomSheet> createState() =>
      _CategorySelectionBottomSheetState();
}

class _CategorySelectionBottomSheetState
    extends State<CategorySelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<dynamic> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _items.clear();
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.fetchData(
          _searchQuery.isEmpty ? null : _searchQuery, _currentPage);

      if ((response['success'] == true || response['status'] == 1) &&
          response['data'] != null) {
        final paginationData = response['data'];
        final List<dynamic> newItems = paginationData['data'] ?? [];

        setState(() {
          if (refresh) {
            _items = newItems;
          } else {
            _items.addAll(newItems);
          }
          _currentPage =
              int.parse(paginationData['current_page'].toString() ?? "1");
          _lastPage = int.parse(paginationData['last_page'].toString() ?? "1");
          _hasMore = _currentPage < _lastPage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;

    try {
      final response = await widget.fetchData(
          _searchQuery.isEmpty ? null : _searchQuery, nextPage);

      if (response['success'] == true && response['data'] != null) {
        final paginationData = response['data'];
        final List<dynamic> newItems = paginationData['data'] ?? [];

        setState(() {
          _items.addAll(newItems);
          _currentPage = paginationData['current_page'] ?? nextPage;
          _lastPage = paginationData['last_page'] ?? 1;
          _hasMore = _currentPage < _lastPage;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _hasMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _loadData(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.55,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Close button with background like StoresGrid arrow
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: CustomTextFormField(
                title: "",
                hintText: widget.searchHint,
                controller: _searchController,
                onChanged: _onSearchChanged,
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: colorScheme.textSecondary,
                  strokeWidth: 1.5,
                ),
              ),
              // TextField(
              //   style: GoogleFonts.inter(
              //     fontSize: 15,
              //     fontWeight: FontWeight.w500,
              //     letterSpacing: -0.55,
              //     height: 1.15,
              //   ),
              //   controller: _searchController,
              //   onChanged: _onSearchChanged,
              //   decoration: InputDecoration(
              //     hintText: widget.searchHint,
              //     hintStyle: GoogleFonts.inter(
              //       fontSize: 15,
              //       color: const Color(0xFF9CA3AF),
              //       fontWeight: FontWeight.w500,
              //       letterSpacing: -0.55,
              //       height: 1.15,
              //     ),
              //     prefixIcon: const Icon(Icons.search,
              //         color: Color(0xFF9CA3AF), size: 20),
              //     filled: true,
              //     fillColor: const Color(0xFFF9FAFB),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(14),
              //       borderSide:
              //           const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              //     ),
              //     enabledBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(14),
              //       borderSide:
              //           const BorderSide(color: Color(0xFFE5E7EB), width: 1),
              //     ),
              //     focusedBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(14),
              //       borderSide:
              //           const BorderSide(color: Color(0xFF9AC444), width: 2),
              //     ),
              //     contentPadding:
              //         const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              //   ),
              // ),
            ),

            // List
            Expanded(
              child: _isLoading && _items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9AC444),
                        strokeWidth: 3,
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Consumer<LanguageProvider>(
                                builder: (context, languageProvider, child) {
                                  return Column(
                                    children: [
                                      Text(
                                        getTranslatedValue(context, nothingFoundLabel),
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        getTranslatedValue(context, tryAdjustingSearchLabel),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: colorScheme.textSecondary.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      if (widget.onAddNew != null) ...[
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context, 'addNew');
                                          },
                                          icon: const Icon(Icons.add, size: 20),
                                          label: Text(
                                            widget.addNewLabel ?? 'Add New',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF9AC444),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadData(refresh: true),
                          color: const Color(0xFF9AC444),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _items.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _items.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF9AC444),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              }

                              final item = _items[index];
                              return _buildListItem(item, colorScheme);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(dynamic item, dynamic colorScheme) {
    String name = '';
    String? subtitle;
    String? imageUrl;
    Color? bgColor;

    // Handle different item types
    if (item is CategoryGroup) {
      name = item.name;
      imageUrl = item.imageUrl;
      bgColor = item.color != null ? _parseColor(item.color!) : null;
    } else if (item is CategoryItem) {
      name = item.name;
    } else if (item is SubcategoryItem) {
      name = item.name;
      subtitle = item.subtitle;
      imageUrl = item.imageUrl;
    } else if (item is Map<String, dynamic>) {
      name = item['name'] ?? '';
      subtitle = item['subtitle'];
      imageUrl = item['image_url'];
      bgColor = item['color'] != null ? _parseColor(item['color']) : null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          widget.onItemSelected(item);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon/Image
                if (imageUrl != null)
                  Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: colorScheme.border, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.category_outlined,
                              color: bgColor ?? colorScheme.textSecondary,
                              size: 28,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: colorScheme.surfaceVariant,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color:
                          bgColor?.withOpacity(0.1) ?? colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: bgColor?.withOpacity(0.2) ??
                            colorScheme.border,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      color: bgColor ?? colorScheme.textSecondary,
                      size: 28,
                    ),
                  ),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: colorScheme.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arrow button like StoresGrid
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF9AC444);
    }
  }
}
