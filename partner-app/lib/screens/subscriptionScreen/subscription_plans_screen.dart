import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/subscription_plan.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen>
    with SingleTickerProviderStateMixin {
  List<SubscriptionPlan> _plans = [];
  int? _selectedIndex;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadMockData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Simulate API call delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      // Mock data for UI demonstration
      _plans = [
        SubscriptionPlan(
          id: '1',
          name: 'Weekly',
          price: 1299.00,
          duration: '7 days',
          benefits: [
            'Visibility above non-subscribed vendors',
            'Valid for 7 days',
          ],
          isPopular: false,
          isSelected: false,
        ),
        SubscriptionPlan(
          id: '2',
          name: 'Monthly',
          price: 4999.00,
          duration: '30 days',
          benefits: [
            'Higher ranking in vendor list & search',
            'Valid for 30 days',
            'Analytics (views & orders count)',
            'Priority customer support',
          ],
          isPopular: true,
          isSelected: true,
        ),
        SubscriptionPlan(
          id: '3',
          name: 'Yearly',
          price: 49999.00,
          duration: '365 days',
          benefits: [
            'Top ranking in vendor list & search',
            'Valid for 365 days',
            'Advanced analytics dashboard',
            'Priority customer support',
            'Featured store badge',
          ],
          isPopular: false,
          isSelected: false,
        ),
      ];

      setState(() {
        _selectedIndex = 1; // Default to Monthly (popular)
        _isLoading = false;
      });

      _animationController.forward();
    });
  }

  Future<void> _fetchPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate refresh with mock data
    await Future.delayed(const Duration(milliseconds: 800));
    _loadMockData();
  }

  void _selectPlan(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _subscribeToPlan() {
    if (_selectedIndex == null) {
      showMessage(
        context,
        'Please select a subscription plan',
        MessageType.warning,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final selectedPlan = _plans[_selectedIndex!];
    showMessage(
      context,
      'Subscribing to ${selectedPlan.name} plan',
      MessageType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: "Subscription",
            title: "Choose Your Plan",
            showBackButton: true,
            onBackPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchPlans,
              color: colorScheme.primary,
              child: _buildBody(colorScheme),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(colorScheme),
    );
  }

  Widget _buildBody(app_theme.AppColorScheme colorScheme) {
    if (_isLoading) {
      return _buildShimmerLoading(colorScheme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        return _buildAnimatedPlanCard(index, colorScheme);
      },
    );
  }

  Widget _buildShimmerLoading(app_theme.AppColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: colorScheme.surface,
            highlightColor: colorScheme.surfaceVariant,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPlanCard(
      int index, app_theme.AppColorScheme colorScheme) {
    final plan = _plans[index];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildPlanCard(plan, index, colorScheme),
      ),
    );
  }

  Widget _buildPlanCard(
      SubscriptionPlan plan, int index, app_theme.AppColorScheme colorScheme) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _selectPlan(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with popular badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (plan.isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.primary
                                          .withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Most Popular',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            SizedBox(height: plan.isPopular ? 12 : 0),
                            Row(
                              children: [
                                Text(
                                  plan.name,
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    plan.duration,
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Radio button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.border,
                            width: 2,
                          ),
                          color: colorScheme.surface,
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        plan.price.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(
                    height: 1,
                    color: colorScheme.divider,
                  ),
                  const SizedBox(height: 20),
                  // Benefits section
                  Text(
                    'What\'s Included',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Benefits list
                  ...plan.benefits.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(app_theme.AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedIndex != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Plan',
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _plans[_selectedIndex!].name,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${_plans[_selectedIndex!].price.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _subscribeToPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Subscribe Now',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(app_theme.AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Plans',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPlans,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
