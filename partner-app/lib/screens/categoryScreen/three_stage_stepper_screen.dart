import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/utils/generalImports.dart'
    hide CategoryListProvider;
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/helper/widgets/image_picker_bottom_sheet.dart';
import 'package:project/helper/widgets/instructional_info_card.dart';
import 'package:project/models/category_model.dart';
import 'package:project/models/three_stage_category_models.dart';
import 'package:project/provider/category_add_provider.dart';
import 'package:project/provider/category_list_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/repositories/three_stage_category_api.dart';
import 'package:project/screens/categoryScreen/add_category_screen.dart';

/// Three-Stage Category Management Screen
/// Stage 1: Manage Categories (Add/View/Edit)
/// Stage 2: Create Groups from Categories
/// Stage 3: Create Groupings from Groups
class ThreeStageCategoryStepperScreen extends StatefulWidget {
  const ThreeStageCategoryStepperScreen({Key? key}) : super(key: key);

  @override
  State<ThreeStageCategoryStepperScreen> createState() =>
      _ThreeStageCategoryStepperScreenState();
}

class _ThreeStageCategoryStepperScreenState
    extends State<ThreeStageCategoryStepperScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Stage 2: Created groups
  List<CategoryGroupModel> _categoryGroups = [];

  // Stage 3: Created groupings
  List<CategoryGroupingModel> _categoryGroupings = [];

  // Stage 1: Search and pagination
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Stage 2: Search and pagination
  final TextEditingController _stage2SearchController = TextEditingController();
  final ScrollController _stage2ScrollController = ScrollController();
  bool _isLoadingStage2 = false;
  bool _isLoadingMoreStage2 = false;
  String _stage2SearchQuery = '';
  Timer? _stage2DebounceTimer;
  int _stage2CurrentPage = 1;
  int _stage2LastPage = 1;
  bool _hasMoreGroupPages = true;

  // Stage 3: Search and pagination
  final TextEditingController _stage3SearchController = TextEditingController();
  final ScrollController _stage3ScrollController = ScrollController();
  bool _isLoadingStage3 = false;
  bool _isLoadingMoreStage3 = false;
  String _stage3SearchQuery = '';
  Timer? _stage3DebounceTimer;
  int _stage3CurrentPage = 1;
  int _stage3LastPage = 1;
  bool _hasMoreGroupingPages = true;

  @override
  void initState() {
    super.initState();
    // Fetch existing categories
    Future.microtask(() {
      context.read<CategoryListProvider>().fetchCategories(isRefresh: true);
      _loadGroupsAndGroupings();
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Stage 1 - Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Stage 2 - Setup scroll and search listeners
    _stage2ScrollController.addListener(_onStage2Scroll);
    _stage2SearchController.addListener(_onStage2SearchChanged);

    // Stage 3 - Setup scroll and search listeners
    _stage3ScrollController.addListener(_onStage3Scroll);
    _stage3SearchController.addListener(_onStage3SearchChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Use provider's load more method
      if (_currentStep == 0) {
        context.read<CategoryListProvider>().loadMoreCategories(
              search: _searchQuery.isEmpty ? null : _searchQuery,
            );
      }
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer with 500ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _refreshCategories();
      }
    });
  }

  // Stage 2 scroll listener
  void _onStage2Scroll() {
    if (_stage2ScrollController.position.pixels >=
        _stage2ScrollController.position.maxScrollExtent * 0.8) {
      _loadMoreGroups();
    }
  }

  // Stage 2 search listener
  void _onStage2SearchChanged() {
    _stage2DebounceTimer?.cancel();
    _stage2DebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_stage2SearchController.text != _stage2SearchQuery) {
        setState(() {
          _stage2SearchQuery = _stage2SearchController.text;
          _stage2CurrentPage = 1;
          _categoryGroups.clear();
        });
        _loadGroups(isRefresh: true);
      }
    });
  }

  // Stage 2 load more
  Future<void> _loadMoreGroups() async {
    if (_isLoadingMoreStage2 || !_hasMoreGroupPages) return;

    setState(() {
      _isLoadingMoreStage2 = true;
    });

    await _loadGroups(isRefresh: false);

    if (mounted) {
      setState(() {
        _isLoadingMoreStage2 = false;
      });
    }
  }

  // Stage 2 refresh
  Future<void> _refreshGroups() async {
    if (_isLoadingStage2) return;

    setState(() {
      _isLoadingStage2 = true;
      _stage2CurrentPage = 1;
      _categoryGroups.clear();
    });

    await _loadGroups(isRefresh: true);

    if (mounted) {
      setState(() {
        _isLoadingStage2 = false;
      });
    }
  }

  // Load groups from API
  Future<void> _loadGroups({required bool isRefresh}) async {
    try {
      if (isRefresh) {
        _stage2CurrentPage = 1;
      } else {
        _stage2CurrentPage++;
      }

      final groupsResponse = await getCategoryGroupsApi(
        page: _stage2CurrentPage,
        search: _stage2SearchQuery.isEmpty ? null : _stage2SearchQuery,
      );

      if (groupsResponse['status'] == 1 && groupsResponse['data'] != null) {
        final responseData = groupsResponse['data'];

        if (responseData is Map && responseData['data'] != null) {
          final List<dynamic> groupsData = responseData['data'];
          final int lastPage = responseData['last_page'] ?? 1;

          if (mounted) {
            setState(() {
              if (isRefresh) {
                _categoryGroups = groupsData
                    .map((json) => CategoryGroupModel.fromJson(json))
                    .toList();
              } else {
                _categoryGroups.addAll(
                  groupsData
                      .map((json) => CategoryGroupModel.fromJson(json))
                      .toList(),
                );
              }
              _stage2LastPage = lastPage;
              _hasMoreGroupPages = _stage2CurrentPage < lastPage;
            });
          }
        } else if (responseData is List) {
          if (mounted) {
            setState(() {
              if (isRefresh) {
                _categoryGroups = responseData
                    .map((json) => CategoryGroupModel.fromJson(json))
                    .toList();
              } else {
                _categoryGroups.addAll(
                  responseData
                      .map((json) => CategoryGroupModel.fromJson(json))
                      .toList(),
                );
              }
              _hasMoreGroupPages = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error loading groups: $e");
    }
  }

  // Stage 3 scroll listener
  void _onStage3Scroll() {
    if (_stage3ScrollController.position.pixels >=
        _stage3ScrollController.position.maxScrollExtent * 0.8) {
      _loadMoreGroupings();
    }
  }

  // Stage 3 search listener
  void _onStage3SearchChanged() {
    _stage3DebounceTimer?.cancel();
    _stage3DebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_stage3SearchController.text != _stage3SearchQuery) {
        setState(() {
          _stage3SearchQuery = _stage3SearchController.text;
          _stage3CurrentPage = 1;
          _categoryGroupings.clear();
        });
        _loadGroupings(isRefresh: true);
      }
    });
  }

  // Stage 3 load more
  Future<void> _loadMoreGroupings() async {
    if (_isLoadingMoreStage3 || !_hasMoreGroupingPages) return;

    setState(() {
      _isLoadingMoreStage3 = true;
    });

    await _loadGroupings(isRefresh: false);

    if (mounted) {
      setState(() {
        _isLoadingMoreStage3 = false;
      });
    }
  }

  // Stage 3 refresh
  Future<void> _refreshGroupings() async {
    if (_isLoadingStage3) return;

    setState(() {
      _isLoadingStage3 = true;
      _stage3CurrentPage = 1;
      _categoryGroupings.clear();
    });

    await _loadGroupings(isRefresh: true);

    if (mounted) {
      setState(() {
        _isLoadingStage3 = false;
      });
    }
  }

  // Load groupings from API
  Future<void> _loadGroupings({required bool isRefresh}) async {
    try {
      if (isRefresh) {
        _stage3CurrentPage = 1;
      } else {
        _stage3CurrentPage++;
      }

      final groupingsResponse = await getCategoryGroupingsApi(
        page: _stage3CurrentPage,
        search: _stage3SearchQuery.isEmpty ? null : _stage3SearchQuery,
      );

      if (groupingsResponse['status'] == 1 &&
          groupingsResponse['data'] != null) {
        final responseData = groupingsResponse['data'];

        if (responseData is Map && responseData['data'] != null) {
          final List<dynamic> groupingsData = responseData['data'];
          final int lastPage = responseData['last_page'] ?? 1;

          if (mounted) {
            setState(() {
              if (isRefresh) {
                _categoryGroupings = groupingsData
                    .map((json) => CategoryGroupingModel.fromJson(json))
                    .toList();
              } else {
                _categoryGroupings.addAll(
                  groupingsData
                      .map((json) => CategoryGroupingModel.fromJson(json))
                      .toList(),
                );
              }
              _stage3LastPage = lastPage;
              _hasMoreGroupingPages = _stage3CurrentPage < lastPage;
            });
          }
        } else if (responseData is List) {
          if (mounted) {
            setState(() {
              if (isRefresh) {
                _categoryGroupings = responseData
                    .map((json) => CategoryGroupingModel.fromJson(json))
                    .toList();
              } else {
                _categoryGroupings.addAll(
                  responseData
                      .map((json) => CategoryGroupingModel.fromJson(json))
                      .toList(),
                );
              }
              _hasMoreGroupingPages = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error loading groupings: $e");
    }
  }

  Future<void> _refreshCategories() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await context.read<CategoryListProvider>().fetchCategories(
          isRefresh: true,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        );

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  /// Load existing groups and groupings from API
  Future<void> _loadGroupsAndGroupings() async {
    await Future.wait([
      _loadGroups(isRefresh: true),
      _loadGroupings(isRefresh: true),
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();

    // Stage 2
    _stage2ScrollController.dispose();
    _stage2SearchController.dispose();
    _stage2DebounceTimer?.cancel();

    // Stage 3
    _stage3ScrollController.dispose();
    _stage3SearchController.dispose();
    _stage3DebounceTimer?.cancel();

    super.dispose();
  }

  void _onStepChanged(int newStep) {
    _animationController.reset();
    setState(() {
      _currentStep = newStep;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: CustomScrollView(
          controller: _currentStep == 0
              ? _scrollController
              : _currentStep == 1
                  ? _stage2ScrollController
                  : _stage3ScrollController,
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: AppHeader(
                label: 'Categories',
                title: 'Manage Categories',
                showBackButton: true,
              ),
            ),
            // Horizontal Progress Indicator
            SliverToBoxAdapter(
              child: _buildHorizontalProgressIndicator(),
            ),
            // Stepper Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),
            // Bottom padding for fixed controls
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomControls(),
    );
  }

  Future<void> _onRefresh() async {
    switch (_currentStep) {
      case 0:
        await _refreshCategories();
        break;
      case 1:
        await _refreshGroups();
        break;
      case 2:
        await _refreshGroupings();
        break;
      default:
        _loadGroupsAndGroupings();
        break;
    }
  }

  Widget _buildHeader() {
    return AppHeader(
      label: "Category Management",
      title: _getHeaderSubtitle(),
      showBackButton: true,
    );
  }

  String _getHeaderSubtitle() {
    switch (_currentStep) {
      case 0:
        return "Add and manage your categories";
      case 1:
        return "Organize categories into groups";
      case 2:
        return "Create high-level groupings";
      default:
        return "";
    }
  }

  Widget _buildHorizontalProgressIndicator() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepIndicator(
            stepNumber: 1,
            title: 'Categories',
            subtitle: '',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
            onTap: () {
              _onStepChanged(0);
              _refreshCategories();
            },
          ),
          _buildStepConnector(isCompleted: _currentStep > 0),
          _buildStepIndicator(
            stepNumber: 2,
            title: 'Groups',
            subtitle: '${_categoryGroups.length} created',
            isActive: _currentStep == 1,
            isCompleted: _currentStep > 1,
            onTap: () async {
              _onStepChanged(1);
              _refreshGroups();
            },
          ),
          _buildStepConnector(isCompleted: _currentStep > 1),
          _buildStepIndicator(
            stepNumber: 3,
            title: 'Groupings',
            subtitle: '${_categoryGroupings.length} created',
            isActive: _currentStep == 2,
            isCompleted: false,
            onTap: () {
              _onStepChanged(2);
              _refreshGroupings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? colorScheme.primary
                    : isActive
                        ? colorScheme.primary
                        : colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive || isCompleted
                      ? colorScheme.primary
                      : colorScheme.border,
                  width: 2.5,
                ),
                boxShadow: isActive || isCompleted
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : Text(
                        '$stepNumber',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : colorScheme.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? colorScheme.textPrimary
                    : colorScheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 2,
        margin: const EdgeInsets.only(bottom: 50),
        decoration: BoxDecoration(
          color:
              isCompleted ? colorScheme.primary : colorScheme.border,
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentStep == 0) _buildStage1Content(),
        if (_currentStep == 1) _buildStage2Content(),
        if (_currentStep == 2) _buildStage3Content(),
      ],
    );
  }

  Widget _buildBottomControls() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _onStepChanged(_currentStep - 1);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.textSecondary,
                    side: BorderSide(
                      color: colorScheme.border,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),

            // Show "Add Category" button only on Stage 1 (currentStep == 0)
            if (_currentStep == 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _navigateToAddCategory();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Add Category',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            if (_currentStep == 0) const SizedBox(width: 12),

            // Continue/Finish button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_currentStep < 2) {
                    _onStepChanged(_currentStep + 1);
                  } else {
                    _onFinish();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep < 2 ? 'Continue' : 'Save & Finish',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // STAGE 1: Category Management
  // ============================================================================

  Widget _buildStage1Content() {
    return Consumer<CategoryListProvider>(
      builder: (context, provider, _) {
        final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

        // Loading state
        if (provider.isLoading && provider.categories.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShimmerCategoryCard(),
                ),
              ),
            ],
          );
        }

        // Error state
        if (provider.hasError && provider.categories.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Unable to Load Categories',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // ... retry button
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructional card for Stage 1
            InstructionalInfoCard(
              title: "Stage 1: Manage Categories",
              description: "Understand how categories work in the system",
              primaryColor: colorScheme.primary,
              initiallyExpanded: false,
              steps: const [
                InstructionalStep(
                  title: "Add Basic Categories",
                  description:
                      "Create individual product categories like Atta, Rice, Daal, Milk, Bread, Beauty Products, etc.",
                  icon: Icons.category_outlined,
                  example:
                      "Examples: Atta, Rice, Daal, Milk, Bread, Shampoo, Soap",
                ),
                InstructionalStep(
                  title: "View and Edit",
                  description:
                      "All your categories will appear here. You can edit or delete them as needed.",
                  icon: Icons.edit_outlined,
                  example:
                      "Click on any category to edit its name, image, or details",
                ),
                InstructionalStep(
                  title: "Move to Next Stage",
                  description:
                      "Once you have categories, proceed to Stage 2 to create groups by combining related categories.",
                  icon: Icons.arrow_forward,
                ),
              ],
            ),

            // const SizedBox(height: 12),

            CustomTextFormField(
              title: '',
              hintText: 'Search categories...',
              controller: _searchController,
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
              ),
            ),

            SizedBox(height: 12),

            if (provider.categories.isNotEmpty) const SizedBox(height: 8),

            // Categories List
            if (provider.categories.isEmpty)
              _buildEmptyState(
                icon: Icons.category_outlined,
                title: _searchQuery.isNotEmpty
                    ? 'No categories found'
                    : 'No categories yet',
                subtitle: _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Add your first category to get started',
                color: colorScheme.primary,
              )
            else ...[
              // Category items
              ...provider.categories.map((category) {
                return _CategoryCard(
                  category: category,
                  showActions: true,
                  onEdit: () => _navigateToEditCategory(category),
                  onDelete: () => _showDeleteConfirmation(category),
                );
              }).toList(),

              // Loading more indicator at bottom
              if (provider.isLoadingMore)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                ),

              // End of list indicator
              if (!provider.hasMorePages && provider.categories.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "No more categories",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  // Navigation methods from CategoryListScreen
  Future<void> _navigateToAddCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCategoryScreen(),
      ),
    );

    // Refresh list if category was added
    // if (result == true && mounted) {
    _refreshCategories();
    // }
  }

  Future<void> _navigateToEditCategory(CategoryModel category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(category: category),
      ),
    );

    // Refresh list if category was updated or deleted
    // if (result == true && mounted) {
    _refreshCategories();

    // }
  }

  // ============================================================================
  // STAGE 2: Group Management
  // ============================================================================

  Widget _buildStage2Content() {
    return Consumer<CategoryListProvider>(
      builder: (context, provider, _) {
        final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
        final groupColor = colorScheme.primary;

        if (provider.categories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_outlined,
            title: 'No categories available',
            subtitle: 'Go back and add categories first',
            color: groupColor,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructional card for Stage 2
            InstructionalInfoCard(
              title: "Stage 2: Create Category Groups",
              description: "Learn how to group related categories together",
              primaryColor: groupColor,
              initiallyExpanded: false,
              steps: const [
                InstructionalStep(
                  title: "Combine Related Categories",
                  description:
                      "Group categories that customers often buy together. This helps in better product organization.",
                  icon: Icons.folder_outlined,
                  example:
                      "Example: Milk + Bread + Butter = 'Breakfast Essentials'",
                ),
                InstructionalStep(
                  title: "Create Smart Collections",
                  description:
                      "Think about shopping patterns - what products go together naturally?",
                  icon: Icons.shopping_cart_outlined,
                  example: "Kitchen Staples: Atta, Rice, Daal, Oil, Spices",
                ),
                InstructionalStep(
                  title: "Add Multiple Groups",
                  description:
                      "Create as many groups as you need. Each group can contain multiple categories.",
                  icon: Icons.add_circle_outline,
                  example: "Beauty Care: Shampoo, Soap, Face Wash, Cream",
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Search Bar
            CustomTextFormField(
              title: '',
              hintText: 'Search groups...',
              controller: _stage2SearchController,
              prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
            ),

            const SizedBox(height: 12),

            // Add Group Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showAddGroupDialog(provider.categories);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: groupColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: groupColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Group',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: groupColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Organize categories into groups',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: groupColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Groups List Header
            if (_categoryGroups.isNotEmpty)
              Row(
                children: [
                  Text(
                    'Your Groups',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_categoryGroups.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: groupColor,
                      ),
                    ),
                  ),
                ],
              ),

            if (_categoryGroups.isNotEmpty) const SizedBox(height: 16),

            // Groups List with Pagination
            if (_isLoadingStage2 && _categoryGroups.isEmpty)
              Column(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShimmerGroupCard(),
                  ),
                ),
              )
            else if (_categoryGroups.isEmpty)
              _buildEmptyState(
                icon: Icons.folder_open,
                title: _stage2SearchQuery.isNotEmpty
                    ? 'No groups found'
                    : 'No groups created',
                subtitle: _stage2SearchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Create your first group to organize categories',
                color: groupColor,
              )
            else ...[
              // Display all groups from API
              ..._categoryGroups.map((group) {
                return _buildGroupCard(
                  group: group,
                  onEdit: () => _showEditGroupDialog(
                    group,
                    _categoryGroups.indexOf(group),
                    provider.categories,
                  ),
                  onDelete: () => _deleteGroup(_categoryGroups.indexOf(group)),
                );
              }).toList(),

              // Loading more indicator
              if (_isLoadingMoreStage2)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: groupColor,
                    ),
                  ),
                ),

              // End of list indicator
              if (!_hasMoreGroupPages && _categoryGroups.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No more groups',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGroupCard({
    required CategoryGroupModel group,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onEdit();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ... image
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 14,
                            color: colorScheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.categoryIds.length} ${group.categoryIds.length == 1 ? 'category' : 'categories'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete Button
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDelete();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderGroupImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.folder_outlined,
        color: const Color(0xFF8B5CF6),
        size: size * 0.45,
      ),
    );
  }

  // ============================================================================
  // STAGE 3: Grouping Management
  // ============================================================================

  Widget _buildStage3Content() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
    final groupingColor = colorScheme.primary;

    if (_categoryGroups.isEmpty) {
      return _buildEmptyState(
        icon: Icons.layers_outlined,
        title: 'No groups available',
        subtitle: 'Go back and create groups first',
        color: groupingColor,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instructional card for Stage 3
        InstructionalInfoCard(
          title: "Stage 3: Organize into Groupings",
          description: "Create final collections from your groups",
          primaryColor: groupingColor,
          initiallyExpanded: false,
          steps: const [
            InstructionalStep(
              title: "Bundle Groups Together",
              description:
                  "Combine multiple groups into larger collections based on common themes or store sections.",
              icon: Icons.layers_outlined,
              example:
                  "All Kitchen Items: Breakfast Essentials + Kitchen Staples + Cooking Oils",
            ),
            InstructionalStep(
              title: "Create Store Sections",
              description:
                  "Think of groupings as sections in your store or app - like 'Personal Care', 'Grocery', 'Home Essentials'.",
              icon: Icons.store_outlined,
              example:
                  "Beauty & Personal Care: Beauty Care + Health Products + Hygiene Items",
            ),
            InstructionalStep(
              title: "Final Organization",
              description:
                  "These groupings will help customers navigate your products easily by showing them organized collections.",
              icon: Icons.check_circle_outline,
              example:
                  "Customers see: Kitchen → Breakfast → Milk, Bread, Butter",
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Search Bar
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.border),
          ),
          child: TextField(
            controller: _stage3SearchController,
            style: TextStyle(color: colorScheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search groupings...',
              hintStyle: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.iconSecondary,
                size: 20,
              ),
              suffixIcon: _stage3SearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: colorScheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        _stage3DebounceTimer?.cancel();
                        _stage3SearchController.clear();
                        setState(() {
                          _stage3SearchQuery = '';
                        });
                        _refreshGroupings();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Add Grouping Button
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showAddGroupingDialog();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Grouping',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEC4899),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Create high-level groupings from groups',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFEC4899),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Groupings List Header
        if (_categoryGroupings.isNotEmpty)
          Row(
            children: [
              Text(
                'Your Groupings',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_categoryGroupings.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEC4899),
                  ),
                ),
              ),
            ],
          ),

        if (_categoryGroupings.isNotEmpty) const SizedBox(height: 16),

        // Groupings List with Pagination
        if (_isLoadingStage3 && _categoryGroupings.isEmpty)
          Column(
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ShimmerGroupingCard(),
              ),
            ),
          )
        else if (_categoryGroupings.isEmpty)
          _buildEmptyState(
            icon: Icons.layers,
            title: _stage3SearchQuery.isNotEmpty
                ? 'No groupings found'
                : 'No groupings created',
            subtitle: _stage3SearchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Create your first grouping to organize groups',
            color: const Color(0xFFEC4899),
          )
        else ...[
          // Display all groupings from API
          ..._categoryGroupings.map((grouping) {
            return _buildGroupingCard(
              grouping: grouping,
              onEdit: () => _showEditGroupingDialog(
                grouping,
                _categoryGroupings.indexOf(grouping),
              ),
              onDelete: () =>
                  _deleteGrouping(_categoryGroupings.indexOf(grouping)),
            );
          }).toList(),

          // Loading more indicator
          if (_isLoadingMoreStage3)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Color(0xFFEC4899),
                ),
              ),
            ),

          // End of list indicator
          if (!_hasMoreGroupingPages && _categoryGroupings.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No more groupings',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGroupingCard({
    required CategoryGroupingModel grouping,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onEdit();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Grouping Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: grouping.localImageFile != null
                      ? Image.file(
                          grouping.localImageFile!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        )
                      : grouping.imageUrl != null
                          ? Image.network(
                              grouping.imageUrl!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderGroupingImage(70),
                            )
                          : _buildPlaceholderGroupingImage(70),
                ),
                const SizedBox(width: 14),
                // Grouping Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grouping.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 14,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${grouping.groups.length} ${grouping.groups.length == 1 ? 'group' : 'groups'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete Button
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDelete();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderGroupingImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.layers_outlined,
        color: const Color(0xFFEC4899),
        size: size * 0.45,
      ),
    );
  }

  // ============================================================================
  // Utility Widgets
  // ============================================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Dialog Methods
  // ============================================================================

  void _showDeleteConfirmation(CategoryModel category) {
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
                // ... icon (keep red background)
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
                          await _deleteCategory(category);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFEF4444),
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

  Future<void> _deleteCategory(CategoryModel category) async {
    if (category.id == null) return;

    try {
      // Create temporary provider for delete operation
      final categoryProvider = CategoryAddProvider(category: category);
      final success = await categoryProvider.deleteCategory(context);

      if (success) {
        // Remove from list optimistically
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

  void _showAddGroupDialog(List<CategoryModel> availableCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _GroupFormDialog(
          availableCategories: availableCategories,
          onSaved: (group) async {
            await _saveGroupToApi(group);
            await _loadGroupsAndGroupings();
          },
        );
      },
    );
  }

  Future<void> _saveGroupToApi(CategoryGroupModel group) async {
    try {
      showMessage(context, 'Saving group...', MessageType.warning);

      final response = await addCategoryGroupApi(
        name: group.name,
        categoryIds: group.categoryIds,
        imageFile: group.localImageFile,
      );

      if (response['status'] == 1) {
        showMessage(context, 'Group created successfully', MessageType.success);
        await _loadGroupsAndGroupings();
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to create group',
          MessageType.error,
        );
      }
    } catch (e) {
      showMessage(context, 'Error creating group: $e', MessageType.error);
    }
  }

  void _showEditGroupDialog(
    CategoryGroupModel group,
    int index,
    List<CategoryModel> availableCategories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _GroupFormDialog(
          availableCategories: availableCategories,
          existingGroup: group,
          onSaved: (updatedGroup) async {
            await _updateGroupToApi(updatedGroup);
            await _loadGroupsAndGroupings();
          },
        );
      },
    );
  }

  Future<void> _updateGroupToApi(CategoryGroupModel group) async {
    if (group.id == null) return;

    try {
      showMessage(context, 'Updating group...', MessageType.warning);

      final response = await updateCategoryGroupApi(
        groupId: group.id!,
        name: group.name,
        categoryIds: group.categoryIds,
        imageFile: group.localImageFile,
      );

      if (response['status'] == 1) {
        showMessage(context, 'Group updated successfully', MessageType.success);
        await _loadGroupsAndGroupings();
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to update group',
          MessageType.error,
        );
      }
    } catch (e) {
      showMessage(context, 'Error updating group: $e', MessageType.error);
    }
  }

  void _showAddGroupingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _GroupingFormDialog(
          availableGroups: _categoryGroups,
          onSaved: (grouping) async {
            await _saveGroupingToApi(grouping);
          },
        );
      },
    );
  }

  Future<void> _saveGroupingToApi(CategoryGroupingModel grouping) async {
    try {
      showMessage(context, 'Saving grouping...', MessageType.warning);

      final response = await addCategoryGroupingApi(
        name: grouping.name,
        groupIds: grouping.groupIds,
        imageFile: grouping.localImageFile,
      );

      if (response['status'] == 1) {
        showMessage(
            context, 'Grouping created successfully', MessageType.success);
        await _loadGroupsAndGroupings();
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to create grouping',
          MessageType.error,
        );
      }
    } catch (e) {
      showMessage(context, 'Error creating grouping: $e', MessageType.error);
    }
  }

  void _showEditGroupingDialog(CategoryGroupingModel grouping, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _GroupingFormDialog(
          availableGroups: _categoryGroups,
          existingGrouping: grouping,
          onSaved: (updatedGrouping) async {
            await _updateGroupingToApi(updatedGrouping);
          },
        );
      },
    );
  }

  Future<void> _updateGroupingToApi(CategoryGroupingModel grouping) async {
    if (grouping.id == null) return;

    try {
      showMessage(context, 'Updating grouping...', MessageType.warning);

      final response = await updateCategoryGroupingApi(
        groupingId: grouping.id!,
        name: grouping.name,
        groupIds: grouping.groupIds,
        imageFile: grouping.localImageFile,
      );

      if (response['status'] == 1) {
        showMessage(
            context, 'Grouping updated successfully', MessageType.success);
        await _loadGroupsAndGroupings();
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to update grouping',
          MessageType.error,
        );
      }
    } catch (e) {
      showMessage(context, 'Error updating grouping: $e', MessageType.error);
    }
  }

  void _deleteGroup(int index) {
    final group = _categoryGroups[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Group',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this group?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteGroupFromApi(group);
              await _loadGroupsAndGroupings();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: Text('Delete', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroupFromApi(CategoryGroupModel group) async {
    if (group.id == null) return;

    try {
      showMessage(context, 'Deleting group...', MessageType.warning);

      final response = await deleteCategoryGroupApi(groupId: group.id!);

      if (response['status'] == 1) {
        showMessage(context, 'Group deleted successfully', MessageType.success);
        await _loadGroupsAndGroupings();
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to delete group',
          MessageType.error,
        );
      }
    } catch (e) {
      showMessage(context, 'Error deleting group: $e', MessageType.error);
    }
  }

  void _deleteGrouping(int index) {
    final grouping = _categoryGroupings[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Grouping',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this grouping?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteGroupingFromApi(grouping);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: Text('Delete', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroupingFromApi(CategoryGroupingModel grouping) async {
    if (grouping.id == null) return;

    try {
      showMessage(context, 'Deleting grouping...', MessageType.warning);

      final response =
          await deleteCategoryGroupingApi(groupingId: grouping.id!);

      if (response['status'] == 1) {
        showMessage(
            context, 'Grouping deleted successfully', MessageType.success);
        await _loadGroupsAndGroupings();
      } else {
        showMessage(
          context,
          response['message'] ?? 'Failed to delete grouping',
          MessageType.error,
        );
      }
    } catch (e) {
      showMessage(context, 'Error deleting grouping: $e', MessageType.error);
    }
  }

  void _onFinish() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Success',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Category organization completed!\n\n'
          '${_categoryGroups.length} groups created\n'
          '${_categoryGroupings.length} groupings created',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context);
            },
            child: Text(
              'OK',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Category Card Widget (from CategoryListScreen)
// ============================================================================

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool showActions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.showActions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: category.imageUrl != null
                  ? Image.network(
                      category.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF3B82F6),
                          size: 36,
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        color: Color(0xFF3B82F6),
                        size: 36,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // Category Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -0.3,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Status badge with dot
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: category.status == 1
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category.status == 1 ? "Active" : "Inactive",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: category.status == 1
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Only show action buttons if not managed by admin
            if (showActions) ...[
              const SizedBox(width: 12),
              // Action Buttons
              Column(
                children: [
                  // Edit button
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onEdit();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ColorsRes.appColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: ColorsRes.appColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Delete button
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDelete();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Group Form Dialog Widget
// ============================================================================

class _GroupFormDialog extends StatefulWidget {
  final List<CategoryModel> availableCategories;
  final CategoryGroupModel? existingGroup;
  final Function(CategoryGroupModel) onSaved;

  const _GroupFormDialog({
    required this.availableCategories,
    this.existingGroup,
    required this.onSaved,
  });

  @override
  State<_GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<_GroupFormDialog> {
  late TextEditingController _nameController;
  late List<CategoryModel> _selectedCategories;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingGroup?.name ?? '',
    );
    _selectedCategories = widget.existingGroup != null
        ? widget.availableCategories
            .where((cat) => widget.existingGroup!.categoryIds.contains(cat.id))
            .toList()
        : [];
    _imageFile = widget.existingGroup?.localImageFile;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    ImagePickerBottomSheet.show(
      context,
      allowMultiple: false,
      title: 'Select Group Image',
      onImagesPicked: (images) {
        if (images.isNotEmpty) {
          setState(() {
            _imageFile = images.first;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.existingGroup == null ? 'Create Group' : 'Edit Group',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker
                  Center(
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.existingGroup?.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.existingGroup!.imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.folder,
                                        size: 40,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Image',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextFormField(
                    title: 'Group Name',
                    hintText: 'Enter group name',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),

                  // Categories Selection Button
                  Row(
                    children: [
                      Text(
                        'Select Categories',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_selectedCategories.length} selected',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Button to open category selection bottom sheet
                  InkWell(
                    onTap: () async {
                      final result =
                          await showModalBottomSheet<List<CategoryModel>>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => MultiProvider(
                                      providers: [
                                        ChangeNotifierProvider(
                                          create: (_) => CategoryListProvider(),
                                        ),
                                      ],
                                      child: _CategorySelectionBottomSheet(
                                        selectedCategories: _selectedCategories,
                                      )));

                      if (result != null) {
                        setState(() {
                          _selectedCategories = result;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFF8B5CF6),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedCategories.isEmpty
                                  ? 'Tap to select categories'
                                  : '${_selectedCategories.length} categories selected',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _selectedCategories.isEmpty
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Show selected categories
                  if (_selectedCategories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedCategories.map((category) {
                        return Chip(
                          label: Text(
                            category.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF8B5CF6),
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedCategories
                                  .removeWhere((c) => c.id == category.id);
                            });
                          },
                          backgroundColor:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty &&
                            _selectedCategories.isNotEmpty) {
                          final convertedCategories = _selectedCategories
                              .map((cat) => ThreeStageCategoryModel(
                                    id: cat.id,
                                    name: cat.name,
                                    subtitle: cat.subtitle,
                                    imageUrl: cat.imageUrl,
                                    image: cat.image,
                                    status: cat.status,
                                  ))
                              .toList();

                          final group = CategoryGroupModel(
                            id: widget.existingGroup?.id,
                            name: _nameController.text,
                            imageUrl: widget.existingGroup?.imageUrl,
                            categories: convertedCategories,
                            categoryIds: _selectedCategories
                                .map((c) => c.id ?? '')
                                .toList(),
                            localImageFile: _imageFile,
                          );

                          widget.onSaved(group);
                          Navigator.pop(context);
                        } else {
                          showMessage(
                            context,
                            'Please enter group name and select categories',
                            MessageType.error,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existingGroup == null ? 'Create' : 'Update',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
}

// ============================================================================
// Grouping Form Dialog Widget
// ============================================================================

class _GroupingFormDialog extends StatefulWidget {
  final List<CategoryGroupModel> availableGroups;
  final CategoryGroupingModel? existingGrouping;
  final Function(CategoryGroupingModel) onSaved;

  const _GroupingFormDialog({
    required this.availableGroups,
    this.existingGrouping,
    required this.onSaved,
  });

  @override
  State<_GroupingFormDialog> createState() => _GroupingFormDialogState();
}

class _GroupingFormDialogState extends State<_GroupingFormDialog> {
  late TextEditingController _nameController;
  late List<CategoryGroupModel> _selectedGroups;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingGrouping?.name ?? '',
    );

    // Pre-select groups based on IDs from the existing grouping
    if (widget.existingGrouping != null &&
        widget.existingGrouping!.groups.isNotEmpty) {
      // Get the IDs of groups in the existing grouping
      final existingGroupIds = widget.existingGrouping!.groups
          .map((g) => g.id)
          .where((id) => id != null)
          .toSet();

      // Find matching groups from availableGroups by ID
      _selectedGroups = widget.availableGroups
          .where((group) => existingGroupIds.contains(group.id))
          .toList();
    } else {
      _selectedGroups = [];
    }

    _imageFile = widget.existingGrouping?.localImageFile;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    ImagePickerBottomSheet.show(
      context,
      allowMultiple: false,
      title: 'Select Grouping Image',
      onImagesPicked: (images) {
        if (images.isNotEmpty) {
          setState(() {
            _imageFile = images.first;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.existingGrouping == null
                      ? 'Create Grouping'
                      : 'Edit Grouping',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker
                  Center(
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEC4899),
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.existingGrouping?.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.existingGrouping!.imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.layers,
                                        size: 40,
                                        color: Color(0xFFEC4899),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Image',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFFEC4899),
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextFormField(
                    title: 'Grouping Name',
                    hintText: 'Enter grouping name',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 24),

                  // Groups Selection
                  Row(
                    children: [
                      Text(
                        'Select Groups',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_selectedGroups.length} selected',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEC4899),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.availableGroups.length,
                    itemBuilder: (context, index) {
                      final group = widget.availableGroups[index];
                      final isSelected = _selectedGroups.contains(group);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedGroups.add(group);
                            } else {
                              _selectedGroups.remove(group);
                            }
                          });
                        },
                        title: Text(
                          group.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${group.categories.length} categories',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        activeColor: const Color(0xFFEC4899),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty &&
                            _selectedGroups.isNotEmpty) {
                          final grouping = CategoryGroupingModel(
                            id: widget.existingGrouping?.id,
                            name: _nameController.text,
                            imageUrl: widget.existingGrouping?.imageUrl,
                            groups: _selectedGroups,
                            groupIds:
                                _selectedGroups.map((g) => g.id ?? '').toList(),
                            localImageFile: _imageFile,
                          );

                          widget.onSaved(grouping);
                          Navigator.pop(context);
                        } else {
                          showMessage(
                            context,
                            'Please enter grouping name and select groups',
                            MessageType.error,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existingGrouping == null ? 'Create' : 'Update',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
}

// ============================================================================
// Category Selection Bottom Sheet Widget with Search & Pagination
// ============================================================================

class _CategorySelectionBottomSheet extends StatefulWidget {
  final List<CategoryModel> selectedCategories;

  const _CategorySelectionBottomSheet({
    required this.selectedCategories,
  });

  @override
  State<_CategorySelectionBottomSheet> createState() =>
      _CategorySelectionBottomSheetState();
}

class _CategorySelectionBottomSheetState
    extends State<_CategorySelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<CategoryModel> _selectedCategories;
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);

    // Fetch categories if not already loaded
    Future.microtask(() {
      final provider = context.read<CategoryListProvider>();
      if (provider.categories.isEmpty) {
        provider.fetchCategories(isRefresh: true);
      }
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Setup search listener with debounce
    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<CategoryListProvider>().loadMoreCategories(
            search: _searchQuery.isEmpty ? null : _searchQuery,
          );
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _refreshCategories();
      }
    });
  }

  Future<void> _refreshCategories() async {
    await context.read<CategoryListProvider>().fetchCategories(
          isRefresh: true,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Categories',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedCategories.length} selected',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                CustomTextFormField(
                  title: '',
                  hintText: 'Search categories...',
                  controller: _searchController,
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          onPressed: () {
                            _debounceTimer?.cancel();
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _refreshCategories();
                          },
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: Consumer<CategoryListProvider>(
              builder: (context, provider, _) {
                // Loading state
                if (provider.isLoading && provider.categories.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
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
                          onPressed: _refreshCategories,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
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
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No categories found'
                              : 'No categories available',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add categories first',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Categories list
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.categories.length +
                      (provider.isLoadingMore ? 1 : 0) +
                      (!provider.hasMorePages && provider.categories.isNotEmpty
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    // Loading more indicator
                    if (index == provider.categories.length &&
                        provider.isLoadingMore) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      );
                    }

                    // End of list indicator
                    if (index == provider.categories.length &&
                        !provider.hasMorePages) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            "No more categories",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      );
                    }

                    final category = provider.categories[index];
                    final isSelected =
                        _selectedCategories.any((c) => c.id == category.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories
                                  .removeWhere((c) => c.id == category.id);
                            }
                          });
                        },
                        title: Text(
                          category.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        subtitle: category.subtitle.isNotEmpty
                            ? Text(
                                category.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        secondary: category.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  category.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F6F7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.category_outlined,
                                      color: Color(0xFFB9B9B9),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F6F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.category_outlined,
                                  color: Color(0xFFB9B9B9),
                                  size: 24,
                                ),
                              ),
                        activeColor: const Color(0xFF8B5CF6),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _selectedCategories);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
}

// ============================================================================
// Shimmer Widgets
// ============================================================================

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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerGradient = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE0E0E0),
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0),
            ],
            stops: [
              _animation.value - 0.3,
              _animation.value,
              _animation.value + 0.3,
            ].map((e) => e.clamp(0.0, 1.0)).toList(),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                spreadRadius: 0,
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Image shimmer (80x80)
                Container(
                  width: 80,
                  height: 80,
                  decoration: shimmerGradient.copyWith(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                // Category Details shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: shimmerGradient,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 150,
                        decoration: shimmerGradient,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 20,
                        width: 60,
                        decoration: shimmerGradient,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons shimmer
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: shimmerGradient,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: shimmerGradient,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerGroupCard extends StatefulWidget {
  const _ShimmerGroupCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerGroupCard> createState() => _ShimmerGroupCardState();
}

class _ShimmerGroupCardState extends State<_ShimmerGroupCard>
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerGradient = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE0E0E0),
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0),
            ],
            stops: [
              _animation.value - 0.3,
              _animation.value,
              _animation.value + 0.3,
            ].map((e) => e.clamp(0.0, 1.0)).toList(),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                spreadRadius: 0,
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Group Image shimmer (70x70)
                Container(
                  width: 70,
                  height: 70,
                  decoration: shimmerGradient.copyWith(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                // Group Details shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: shimmerGradient,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 100,
                        decoration: shimmerGradient,
                      ),
                    ],
                  ),
                ),
                // Delete button shimmer
                Container(
                  width: 40,
                  height: 40,
                  decoration: shimmerGradient,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerGroupingCard extends StatefulWidget {
  const _ShimmerGroupingCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerGroupingCard> createState() => _ShimmerGroupingCardState();
}

class _ShimmerGroupingCardState extends State<_ShimmerGroupingCard>
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerGradient = BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE0E0E0),
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0),
            ],
            stops: [
              _animation.value - 0.3,
              _animation.value,
              _animation.value + 0.3,
            ].map((e) => e.clamp(0.0, 1.0)).toList(),
          ),
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                spreadRadius: 0,
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Grouping Image shimmer (70x70)
                Container(
                  width: 70,
                  height: 70,
                  decoration: shimmerGradient.copyWith(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                // Grouping Details shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: shimmerGradient,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: 80,
                        decoration: shimmerGradient,
                      ),
                    ],
                  ),
                ),
                // Delete button shimmer
                Container(
                  width: 40,
                  height: 40,
                  decoration: shimmerGradient,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
