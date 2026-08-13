import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/utils/generalImports.dart' hide log;
import 'package:project/helper/widgets/image_picker_bottom_sheet.dart';
import 'package:project/models/places_model.dart';
import 'package:project/provider/place_proveder.dart';
import 'package:project/screens/resgistration/food/food_registration_provider.dart';
import "package:project/screens/resgistration/food/location_picker.dart";
import 'package:project/screens/resgistration/food/signature_canvas.dart';

class FoodRegistrationScreen extends StatefulWidget {
  final String? storeId;
  final int initialStep;

  const FoodRegistrationScreen({
    Key? key,
    this.storeId,
    this.initialStep = 0,
  }) : super(key: key);

  @override
  State<FoodRegistrationScreen> createState() => _FoodRegistrationScreenState();
}

class _FoodRegistrationScreenState extends State<FoodRegistrationScreen> {
  late FoodRegistrationProvider _provider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Fetch seller data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.fetchSellerData(storeId: widget.storeId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget stepper(BuildContext context, FoodRegistrationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64),
      child: Row(
        children: [
          _AnimatedStepCircle(
            index: 0,
            currentIndex: provider.stepIndex,
          ),
          Expanded(
            child: _AnimatedStepLine(
              isActive: provider.stepIndex > 0,
            ),
          ),
          _AnimatedStepCircle(
            index: 1,
            currentIndex: provider.stepIndex,
          ),
          Expanded(
            child: _AnimatedStepLine(
              isActive: provider.stepIndex > 1,
            ),
          ),
          _AnimatedStepCircle(
            index: 2,
            currentIndex: provider.stepIndex,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log(widget.storeId.toString());
    return ChangeNotifierProvider(
      create: (context) {
        _provider = FoodRegistrationProvider(context, storeId: widget.storeId);
        _provider.stepIndex = widget.initialStep; // Set initial step
        return _provider;
      },
      child:
          Consumer<FoodRegistrationProvider>(builder: (context, provider, _) {
        // Show loading indicator
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ColorsRes.appColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading your data...",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return PopScope(
          canPop: provider.stepIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // stepIndex > 0: go to previous step instead of popping
            provider.previousStep(context);
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: RefreshIndicator(
              color: Color(0xFF9AC444),
              onRefresh: () async {
                await provider.fetchSellerData(storeId: widget.storeId);
                if (provider.stepIndex == 2) {
                  await provider.checkApprovalStatus(context);
                }
              },
              child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Collapsing SliverAppBar
                SliverAppBar(
                  expandedHeight: 160,
                  collapsedHeight: 70,
                  floating: true,
                  pinned: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  automaticallyImplyLeading: false,
                  flexibleSpace: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      // Calculate collapse progress
                      final double collapsedHeight = 100;
                      final double currentHeight = constraints.maxHeight;

                      // Determine if fully collapsed
                      final bool isCollapsed =
                          currentHeight <= collapsedHeight + 10;

                      return Stack(
                        children: [
                          // Main expanded header
                          FlexibleSpaceBar(
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFB9E990),
                                    Color(0xFFFFFFFF),
                                  ],
                                  stops: [0.0, 1.0],
                                ),
                              ),
                              child: SafeArea(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 20, 18, 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Modern back button
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.lightImpact();
                                              if (provider.stepIndex == 0) {
                                                Navigator.pop(context);
                                              } else {
                                                provider.previousStep(context);
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.06),
                                                    blurRadius: 12,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.arrow_back_ios_new,
                                                size: 18,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 14),
                                          // Title with subtitle in row
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Register",
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 26,
                                                    letterSpacing: -0.6,
                                                    color: Color(0xFF111827),
                                                    height: 1.2,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  "Create your partner account",
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                    letterSpacing: -0.1,
                                                    color: Color(0xFF6B7280),
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 14),
                                          // Logout icon button
                                          GestureDetector(
                                            onTap: () async {
                                              HapticFeedback.lightImpact();
                                              final shouldLogout =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext
                                                        dialogContext) =>
                                                    AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  surfaceTintColor:
                                                      Colors.transparent,
                                                  title: Text(
                                                    'Logout',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF111827),
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    'Are you sure you want to logout? Your registration progress will be saved.',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF6B7280),
                                                      height: 1.4,
                                                      letterSpacing: -0.2,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              dialogContext,
                                                              false),
                                                      child: Text(
                                                        'Cancel',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                              0xFF6B7280),
                                                          letterSpacing: -0.2,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              dialogContext,
                                                              true),
                                                      child: Text(
                                                        'Logout',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                              0xFFEF4444),
                                                          letterSpacing: -0.2,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (shouldLogout == true) {
                                                Constant.session.logoutUser(
                                                    context,
                                                    confirmationRequired:
                                                        false);
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.06),
                                                    blurRadius: 12,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.logout,
                                                size: 18,
                                                color: Color(0xFFEF4444),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                      stepper(context, provider),
                                      SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Compact header - only shown when collapsed
                          if (isCollapsed)
                            SafeArea(
                              child: Container(
                                height: 70,
                                color: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 18),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        if (provider.stepIndex == 0) {
                                          Navigator.pop(context);
                                        } else {
                                          provider.previousStep(context);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Color(0xFFE5E7EB),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_back_ios_new,
                                          size: 16,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Register",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        letterSpacing: -0.4,
                                        color: Color(0xFF111827),
                                        height: 1.2,
                                      ),
                                    ),
                                    Spacer(),
                                    // Logout icon button (collapsed)
                                    GestureDetector(
                                      onTap: () async {
                                        HapticFeedback.lightImpact();
                                        final shouldLogout =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext
                                                  dialogContext) =>
                                              AlertDialog(
                                            backgroundColor: Colors.white,
                                            surfaceTintColor:
                                                Colors.transparent,
                                            title: Text(
                                              'Logout',
                                              style: GoogleFonts.inter(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            content: Text(
                                              'Are you sure you want to logout? Your registration progress will be saved.',
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF6B7280),
                                                height: 1.4,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        dialogContext, false),
                                                child: Text(
                                                  'Cancel',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF6B7280),
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        dialogContext, true),
                                                child: Text(
                                                  'Logout',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFEF4444),
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (shouldLogout == true) {
                                          Constant.session.logoutUser(context,
                                              confirmationRequired: false);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Color(0xFFE5E7EB),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.logout,
                                          size: 16,
                                          color: Color(0xFFEF4444),
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
                  ),
                ),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Show API error message if exists
                      if (provider.apiErrorMessage != null &&
                          provider.apiErrorMessage!.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(bottom: 16, top: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFFECACA),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Error',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF4444),
                                        letterSpacing: -0.2,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      provider.apiErrorMessage!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF991B1B),
                                        height: 1.4,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => provider.clearApiError(),
                                child: Icon(
                                  Icons.close,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (provider.stepIndex == 0) PersonalInfoStepBody(),
                      if (provider.stepIndex == 1) StoreInfoStepBody(),
                      if (provider.stepIndex == 2)
                        // Success Screen - Awaiting Confirmation
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                                    children: [
                                      SizedBox(height: 40),
                                      // Warning/Info Icon
                                      Container(
                                        width: 51,
                                        height: 51,
                                        decoration: BoxDecoration(
                                          color: provider.adminRemark != null
                                              ? Color(0xFFF59E0B)
                                              : Color(0xFFF97316),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          provider.adminRemark != null
                                              ? Icons.error_outline
                                              : Icons.access_time,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(height: 23),
                                      // Title
                                      Text(
                                        provider.adminRemark != null
                                            ? 'Action Required'
                                            : 'Awaiting confirmation.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                          height: 1.25,
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                      SizedBox(height: 13),
                                      // Subtitle or Admin Remark
                                      if (provider.adminRemark != null)
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              horizontal: 20),
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFEF3C7),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Color(0xFFFCD34D),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Color(0xFFD97706),
                                                size: 24,
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Message from Admin',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFFD97706),
                                                        letterSpacing: -0.2,
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      provider.adminRemark!,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Color(0xFF92400E),
                                                        height: 1.4,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Text(
                                          'Your request has been submitted successfully and is now waiting for approval from our team.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF374151),
                                            height: 1.33,
                                            letterSpacing: -0.12,
                                          ),
                                        ),
                                      SizedBox(height: 16),
                                      // Pull to refresh hint
                                      Text(
                                        'Pull down to refresh status',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF9CA3AF),
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: -0.12,
                                          height: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      // Personal Information Section
                                      InkWell(
                                        onTap: () {
                                          provider.goToStep(0);
                                          _scrollController.animateTo(
                                            0,
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.easeOut,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Color(0xFFE5E7EB),
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.04),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              // Checkmark icon
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF9AC444),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              // Text
                                              Expanded(
                                                child: Text(
                                                  'Personal Information',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF111827),
                                                    height: 1.38,
                                                    letterSpacing: -0.18,
                                                  ),
                                                ),
                                              ),
                                              // Arrow icon
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      // Store Information Section
                                      InkWell(
                                        onTap: () {
                                          provider.goToStep(1);
                                          _scrollController.animateTo(
                                            0,
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.easeOut,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Color(0xFFE5E7EB),
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.04),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              // Checkmark icon
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF9AC444),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              // Text
                                              Expanded(
                                                child: Text(
                                                  'Store Information',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF111827),
                                                    height: 1.38,
                                                    letterSpacing: -0.18,
                                                  ),
                                                ),
                                              ),
                                              // Arrow icon
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      // Agreement Section
                                      AgreementSection(),
                                      SizedBox(height: 28),
                                      // Go to Dashboard Button
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(1000),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF6B7280)
                                                  .withOpacity(0.2),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: provider.isCheckingApproval
                                              ? null
                                              : () async {
                                                  await provider
                                                      .checkApprovalStatus(
                                                          context);
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                provider.isCheckingApproval
                                                    ? Color(0xFF9CA3AF)
                                                    : Color(0xFF6B7280),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(1000),
                                            ),
                                          ),
                                          child: provider.isCheckingApproval
                                              ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'Go to Dashboard',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    letterSpacing: 0.2,
                                                    height: 1.2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      SizedBox(height: 100), // Bottom padding for button
                    ]),
                  ),
                ),
              ],
            ),
            ), // closes RefreshIndicator
            bottomNavigationBar: provider.stepIndex == 2
                ? null // Hide navigation on success screen
                : Container(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton(
                        onPressed: provider.isSubmitting ||
                                provider.isUploadingStep2
                            ? null
                            : () async {
                                if (provider.stepIndex == 0) {
                                  // Light up every wrong field, then report
                                  // the first problem in the snackbar.
                                  provider.step1FormKey.currentState
                                      ?.validate();
                                  // Validate step 1 before proceeding
                                  final error = provider.validateStep1();
                                  if (error != null) {
                                    HapticFeedback.heavyImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: Colors.white),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                error,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                  letterSpacing: -0.28,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        duration: Duration(seconds: 3),
                                        margin: EdgeInsets.all(16),
                                      ),
                                    );
                                    return;
                                  }

                                  // If updating existing registration, call update API
                                  if (provider.sellerStoreId != null &&
                                      provider.sellerStoreId!.isNotEmpty) {
                                    await provider.updatePersonalProfile(
                                        context, provider.sellerStoreId);
                                    // Only proceed if update was successful
                                    if (!provider.isSubmitting &&
                                        !provider.hasError) {
                                      provider.nextStep();
                                      // Scroll to top when moving to next step
                                      _scrollController.animateTo(
                                        0,
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  } else {
                                    // For new registration, just move to next step
                                    provider.nextStep();
                                    // Scroll to top when moving to next step
                                    _scrollController.animateTo(
                                      0,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                } else if (provider.stepIndex == 1) {
                                  // Light up every wrong field, then report
                                  // the first problem in the snackbar.
                                  provider.step2FormKey.currentState
                                      ?.validate();
                                  // Validate step 2 before proceeding
                                  final error = provider.validateStep2();
                                  if (error != null) {
                                    HapticFeedback.heavyImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: Colors.white),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                error,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                  letterSpacing: -0.28,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        duration: Duration(seconds: 3),
                                        margin: EdgeInsets.all(16),
                                      ),
                                    );
                                    return;
                                  }

                                  // Check if this is an update or new registration
                                  // Use sellerStoreId (actual seller ID from API), not
                                  // widget.storeId (which is just the store type ID)
                                  log('[STEP2] sellerStoreId = ${provider.sellerStoreId}, widget.storeId = ${widget.storeId}');
                                  if (provider.sellerStoreId != null &&
                                      provider.sellerStoreId!.isNotEmpty) {
                                    // Update existing store details
                                    await provider.uploadStep2Data(
                                        context,
                                        // int.tryParse(provider.sellerStoreId!)
                                        int.tryParse(widget.storeId.toString())
                                        );
                                    // Only proceed to success screen if update was successful
                                    if (!provider.isUploadingStep2 &&
                                        !provider.hasError) {
                                      provider.nextStep();
                                      // Scroll to top when moving to success screen
                                      _scrollController.animateTo(
                                        0,
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  } else {
                                    // Submit all data for new registration.
                                    // widget.storeId is the store TYPE ID (e.g. "1"
                                    // for Sweet House) — required by the backend.
                                    await provider.submitRegistration(
                                      context,
                                      widget.storeId,
                                    );
                                    // Only proceed to success screen if submission was successful
                                    if (!provider.isSubmitting &&
                                        !provider.hasError) {
                                      provider.nextStep();
                                      // Scroll to top when moving to success screen
                                      _scrollController.animateTo(
                                        0,
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  }
                                } else {
                                  // Step 3 is success screen - navigate to dashboard
                                  provider.onSubmit(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF9AC444), 
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child:
                            provider.isSubmitting || provider.isUploadingStep2
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    provider.stepIndex == 2
                                        ? "Go to Dashboard"
                                        : "Next",
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -0.4,
                                      height: 1.02,
                                    ),
                                  ),
                      ),
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

// --- Modern Form Steps (Personal / Store Info) ---
class PersonalInfoStepBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<FoodRegistrationProvider>(context, listen: false);
    return Form(
      key: provider.step1FormKey,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          "Personal Information",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.2,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 20),
        CustomTextFormField(
          title: "User Name",
          hintText: "Enter user Name",
          controller: provider.userNameController,
          prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedUser),
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[^a-zA-Z\s]')),
          ],
        ),
        SizedBox(height: 16),
        CustomTextFormField(
          title: "Email Address",
          hintText: "Enter email address",
          controller: provider.emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedMail01),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[^a-zA-Z0-9@.\s]')),
          ],
        ),
        // SizedBox(height: 16),
        // CustomTextFormField(
        //   title: "Mobile Number",
        //   hintText: "Enter mobile Number",
        //   controller: provider.mobileController,
        //   keyboardType: TextInputType.phone,
        //   prefixIcon:
        //       Icon(Icons.phone_outlined, size: 22, color: Color(0xFF9E9E9E)),
        // ),
        // SizedBox(height: 16),
        // CustomTextFormField(
        //   title: "Password",
        //   hintText: "Enter Password",
        //   controller: provider.passwordController,
        //   obscureText: true,
        //   prefixIcon:
        //       Icon(Icons.lock_outline, size: 22, color: Color(0xFF9E9E9E)),
        // ),
        // SizedBox(height: 16),
        // CustomTextFormField(
        //   title: "Confirm Password",
        //   hintText: "Enter Confirm Password",
        //   controller: provider.confirmPasswordController,
        //   obscureText: true,
        //   prefixIcon:
        //       Icon(Icons.lock_outline, size: 22, color: Color(0xFF9E9E9E)),
        // ),
        SizedBox(height: 12),
        _UploadTile(
          title: "Aadhar Card",
          uploadLabel: "Upload Aadhar image/PDF\nPNG, JPG, PDF",
          file: provider.aadharFile,
          imageUrl: provider.aadharImageUrl,
          onTap: () async {
            final picked = await pickPDFOrImage(context);
            if (picked != null) provider.setAadharFile(picked);
          },
          onRemove: () => provider.clearAadhar(),
        ),
        SizedBox(height: 12),
        CustomTextFormField(
          title: "Aadhar Number",
          hintText: "e.g. ${AppValidators.aadhaarExample.replaceAll(' ', '')}",
          helperText:
              "12 digits, exactly as printed on the card (no spaces needed)",
          controller: provider.aadharNumberController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: AppValidators.aadhaar,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          maxLength: 12,
          prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedIdentityCard,
              size: 22,
              color: Color(0xFF9E9E9E)),
        ),
        SizedBox(height: 16),
        _UploadTile(
          title: "PAN Card",
          uploadLabel: "Upload PAN image/PDF\nPNG, JPG, PDF",
          file: provider.panFile,
          imageUrl: provider.panImageUrl,
          onTap: () async {
            final picked = await pickPDFOrImage(context);
            if (picked != null) provider.setPanFile(picked);
          },
          onRemove: () => provider.clearPan(),
        ),
        SizedBox(height: 12),
        CustomTextFormField(
          title: "PAN Number",
          hintText: "e.g. ${AppValidators.panExample}",
          helperText: "10 characters — 5 letters, 4 digits, then 1 letter",
          controller: provider.panNumberController,
          validator: AppValidators.pan,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[^a-zA-Z0-9]')),
            LengthLimitingTextInputFormatter(10),
            UpperCaseTextFormatter(),
          ],
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          maxLength: 10,
          prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedIdentityCard,
              size: 22,
              color: Color(0xFF9E9E9E)),
        ),
        SizedBox(height: 16),
        _UploadTile(
          title: "FSSAI",
          uploadLabel: "Upload Fassi image/PDF\nPNG, JPG, PDF",
          file: provider.fassiFile,
          imageUrl: provider.fssaiImageUrl,
          onTap: () async {
            final picked = await pickPDFOrImage(context);
            if (picked != null) provider.setFassiFile(picked);
          },
          onRemove: () => provider.clearFassi(),
        ),
        SizedBox(height: 12),
        CustomTextFormField(
          title: "FSSAI Number",
          hintText: "e.g. ${AppValidators.fssaiExample}",
          helperText:
              "14 digits from your FSSAI licence / registration certificate",
          controller: provider.fssaiNumberController,
          validator: (value) => AppValidators.fssai(value),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(14),
          ],
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 14,
          prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedIdentityCard,
              size: 22,
              color: Color(0xFF9E9E9E)),
        ),
        SizedBox(height: 16),
      ],
    ),
    );
  }

  Future<File?> pickPDFOrImage(BuildContext context) async {
    final completer = Completer<File?>();

    ImagePickerBottomSheet.show(
      context,
      allowMultiple: false,
      onImagesPicked: (files) {
        if (!completer.isCompleted && files.isNotEmpty) {
          completer.complete(files.first);
        }
      },
      title: 'Select Image or PDF',
    ).then((result) {
      // result == true means we intentionally popped to open gallery;
      // wait for onImagesPicked. Only complete null if the sheet was
      // dismissed by the user (drag/tap outside).
      if (result != true && !completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }
}

// Category selection bottom sheet helper function
void _showCategorySelectionBottomSheet({
  required BuildContext context,
  required FoodRegistrationProvider provider,
  bool allowMultipleSelection = false,
}) {
  // Create a temporary list to track selections
  List<CategoryModel> tempSelected = List.from(provider.selectedCategories);
  final TextEditingController searchController = TextEditingController();
  List<CategoryModel> filteredCategories = List.from(provider.allCategories);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          void filterCategories(String query) {
            setState(() {
              if (query.isEmpty) {
                filteredCategories = List.from(provider.allCategories);
              } else {
                filteredCategories = provider.allCategories
                    .where((category) => category.name
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header with drag handle
                Container(
                  padding: EdgeInsets.only(top: 12, bottom: 16),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Title and close button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                allowMultipleSelection
                                    ? 'Select Categories'
                                    : 'Select Category',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(sheetContext),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: filterCategories,
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: -0.2,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF9CA3AF),
                          size: 22,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  filterCategories('');
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Color(0xFF9CA3AF),
                                  size: 20,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Selected count (only for multiple selection)
                if (allowMultipleSelection && tempSelected.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: ColorsRes.appColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ColorsRes.appColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: ColorsRes.appColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${tempSelected.length} ${tempSelected.length == 1 ? 'category' : 'categories'} selected',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorsRes.appColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (allowMultipleSelection && tempSelected.isNotEmpty)
                  SizedBox(height: 16),

                // Categories list
                Expanded(
                  child: provider.allCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 64,
                                color: Color(0xFFE5E7EB),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No categories available',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredCategories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Color(0xFFE5E7EB),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No categories found',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Try a different search term',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = filteredCategories[index];
                                final isSelected = tempSelected
                                    .any((c) => c.id == category.id);

                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      if (allowMultipleSelection) {
                                        // Multiple selection mode
                                        if (isSelected) {
                                          tempSelected.removeWhere(
                                              (c) => c.id == category.id);
                                        } else {
                                          tempSelected.add(category);
                                        }
                                      } else {
                                        // Single selection mode
                                        tempSelected.clear();
                                        tempSelected.add(category);
                                        // Auto-close and save for single selection
                                        provider.setSelectedCategories(
                                            tempSelected);
                                        Navigator.pop(sheetContext);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? ColorsRes.appColor
                                              .withValues(alpha: 0.1)
                                          : Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? ColorsRes.appColor
                                            : Color(0xFFE5E7EB),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? ColorsRes.appColor
                                                : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? ColorsRes.appColor
                                                  : Color(0xFFD1D5DB),
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? Icon(Icons.check,
                                                  size: 16, color: Colors.white)
                                              : null,
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            category.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Color(0xFF111827)
                                                  : Color(0xFF374151),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: ColorsRes.appColor,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                // Bottom buttons (only for multiple selection)
                if (allowMultipleSelection)
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: tempSelected.isEmpty
                                ? null
                                : () {
                                    provider
                                        .setSelectedCategories(tempSelected);
                                    Navigator.pop(sheetContext);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tempSelected.isEmpty
                                  ? Color(0xFFE5E7EB)
                                  : ColorsRes.appColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              tempSelected.isEmpty
                                  ? 'Select at least one'
                                  : 'Apply (${tempSelected.length})',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

// --- Store Info BODY ---
class StoreInfoStepBody extends StatelessWidget {
  const StoreInfoStepBody({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<FoodRegistrationProvider>(context, listen: false);
    return Form(
      key: provider.step2FormKey,
      child: Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            "Store Information",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.2,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 20),
          _UploadTile(
            title: "Store Logo",
            uploadLabel: "Upload Store Logo\nPNG, JPG",
            file: provider.storeLogo,
            imageUrl: provider.logoImageUrl,
            onTap: () async {
              final picked = await _pickImage(context);
              if (picked != null) provider.setStoreLogo(picked);
            },
            onRemove: () => provider.clearStoreLogo(),
          ),
          SizedBox(height: 16),
          _StoreImagesUploadTile(
            files: provider.storeImages,
            imageUrls: provider.storeImageUrls,
            onTap: () async {
              HapticFeedback.lightImpact();
              final files = await _pickMultipleImages(context);
              if (files.isNotEmpty) provider.addStoreImages(files);
            },
            onRemove: (i) => provider.removeStoreImage(i),
            onRemoveUrl: (i) => provider.removeStoreImageUrl(i),
          ),
          SizedBox(height: 16),
          CustomTextFormField(
            title: "Store Name",
            hintText: "e.g. Sri Sai Bakery & Sweets",
            helperText: "The name customers will see in the Zenfoo app",
            controller: provider.storeNameController,
            prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedUserAccount),
            validator: AppValidators.storeName,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
              LengthLimitingTextInputFormatter(60),
            ],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
          ),
          SizedBox(height: 16),
          CustomTextFormField(
            title: "Description",
            hintText:
                "e.g. Fresh sweets, snacks and hot samosas prepared daily",
            helperText: "20 to 500 characters — tell customers what you sell",
            controller: provider.descriptionController,
            maxLines: 3,
            prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedText),
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            validator: AppValidators.storeDescription,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
              LengthLimitingTextInputFormatter(500),
            ],
          ),
          SizedBox(height: 16),
          CustomTextFormField(
            title: "Store location",
            hintText: provider.location ?? "Select location",
            controller: TextEditingController(text: provider.location ?? ""),
            prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedLocation01),
            readOnly: true,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider(
                          create: (_) => PlaceSuggestionsProvider()),
                      ChangeNotifierProvider(
                          create: (_) => PlaceDetailsProvider()),
                    ],
                    child: LocationPickerScreen(),
                  ),
                ),
              );

              if (result != null && result is PlaceDetailsModel) {
                // Extract city from formatted address
                String? cityName;
                if (result.formattedAddress != null) {
                  final addressParts = result.formattedAddress!.split(',');
                  // Try to extract city (usually second or third part)
                  if (addressParts.length > 1) {
                    cityName = addressParts[addressParts.length - 3].trim();
                    provider.selectCity(cityName);
                  }
                }

                provider.setLocationData(
                  address: result.formattedAddress ?? '',
                  lat: result.latitude ?? 0.0,
                  lng: result.longitude ?? 0.0,
                  cityName: cityName,
                );
              }
            },
          ),
          SizedBox(height: 16),
          // CustomTextFormField(
          //   title: "City",
          //   hintText: "Select City",
          //   controller: TextEditingController(text: provider.city ?? ""),
          //   prefixIcon:
          //       Icon(Icons.location_city, size: 22, color: Color(0xFF9E9E9E)),
          //   readOnly: true,
          //   onTap: () {
          //     // Show your city picker dialog and call provider.selectCity(result)
          //   },
          // ),
          // SizedBox(height: 16),
          // Only show categories field if categories are available
          if (provider.allCategories.isNotEmpty) ...[
            CustomTextFormField(
              title: "Categories",
              hintText: provider.selectedCategories.isEmpty
                  ? "Select categories"
                  : provider.selectedCategories.map((c) => c.name).join(", "),
              controller: TextEditingController(
                  text: provider.selectedCategories
                      .map((c) => c.name)
                      .join(", ")),
              prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedCatalogue),
              readOnly: true,
              onTap: () {
                _showCategorySelectionBottomSheet(
                  context: context,
                  provider: provider,
                  allowMultipleSelection:
                      false, // Change to false for single selection
                );
              },
            ),
            SizedBox(height: 16),
          ],
          // CustomTextFormField(
          //   title: "Store Url",
          //   hintText: "Past URL",
          //   controller: provider.urlController,
          //   prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedLink01),
          //   keyboardType: TextInputType.url,
          //   inputFormatters: [
          //     FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
          //   ],
          // ),
          // SizedBox(height: 16),
          CustomTextFormField(
            title: "GST Business Name",
            hintText: "e.g. Sri Sai Foods",
            helperText: "Legal / trade name exactly as on the GST certificate",
            controller: provider.taxNameController,
            prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedTaxes),
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: AppValidators.gstBusinessName,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
              LengthLimitingTextInputFormatter(100),
            ],
          ),
          SizedBox(height: 16),
          CustomTextFormField(
            title: "GSTIN Number",
            hintText: "e.g. ${AppValidators.gstinExample}",
            helperText: "15 characters: state code + PAN + entity code + Z + 1",
            controller: provider.taxNumberController,
            prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedTaxes),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            maxLength: 15,
            validator: AppValidators.gstin,
            onChanged: (_) => provider.refreshGstinHint(),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[^a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(15),
              UpperCaseTextFormatter(),
            ],
          ),
          // Soft advisory: a proprietor's GSTIN normally carries his own PAN.
          if (provider.gstinPanMismatch) ...[
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFFFFBEB),
                border: Border.all(color: Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This GSTIN contains PAN ${AppValidators.panInsideGstin(provider.taxNumberController.text)}, '
                      'which is different from the PAN you entered. That is fine for a company GSTIN — '
                      'otherwise please re-check both numbers.',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Color(0xFFB45309),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (provider.vendorGstPercent != null) ...[
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFEFF6FF),
                border: Border.all(color: Color(0xFFBFDBFE)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Color(0xFF1D4ED8),
                            height: 1.4),
                        children: [
                          TextSpan(text: 'Applicable GST: '),
                          TextSpan(
                            text:
                                '${_formatGstPercent(provider.vendorGstPercent!)}%',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (provider.vendorGstCategory != null &&
                              provider.vendorGstCategory!.isNotEmpty)
                            TextSpan(
                                text:
                                    ' (${provider.vendorGstCategory} vendor)'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (provider.vendorCommissionPercent != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFF0FDF4),
                border: Border.all(color: Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.percent_rounded,
                      size: 18, color: Color(0xFF15803D)),
                  SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Color(0xFF14532D),
                            height: 1.4),
                        children: [
                          TextSpan(text: 'Applicable Commission: '),
                          TextSpan(
                            text:
                                '${_formatGstPercent(provider.vendorCommissionPercent!)}%',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (provider.vendorCommissionCategory != null &&
                              provider.vendorCommissionCategory!.isNotEmpty)
                            TextSpan(
                                text:
                                    ' (${provider.vendorCommissionCategory} vendor)'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16),
        ],
      ),
    ),
    );
  }

  String _formatGstPercent(double v) {
    if (v == v.roundToDouble()) {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(2);
  }

  Future<File?> _pickImage(BuildContext context) async {
    final completer = Completer<File?>();

    ImagePickerBottomSheet.show(
      context,
      allowMultiple: false,
      onImagesPicked: (files) {
        if (!completer.isCompleted && files.isNotEmpty) {
          completer.complete(files.first);
        }
      },
      title: 'Select Store Image',
    ).then((result) {
      if (result != true && !completer.isCompleted) {
        completer.complete(null);
      }
    });

    return completer.future;
  }

  Future<List<File>> _pickMultipleImages(BuildContext context) async {
    final completer = Completer<List<File>>();

    ImagePickerBottomSheet.show(
      context,
      allowMultiple: true,
      onImagesPicked: (files) {
        if (!completer.isCompleted) {
          completer.complete(files);
        }
      },
      title: 'Select Store Images',
    ).then((result) {
      if (result != true && !completer.isCompleted) {
        completer.complete([]);
      }
    });

    return completer.future;
  }
}

// --- Upload Tile and Image Previews ---
class _UploadTile extends StatefulWidget {
  final String title, uploadLabel;
  final File? file;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _UploadTile({
    required this.title,
    required this.uploadLabel,
    required this.onTap,
    this.file,
    this.imageUrl,
    this.onRemove,
    Key? key,
  }) : super(key: key);

  @override
  State<_UploadTile> createState() => _UploadTileState();
}

class _UploadTileState extends State<_UploadTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPreview() {
    if (widget.file == null && widget.imageUrl == null) {
      // Empty state with modern upload icon
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorsRes.appColor.withOpacity(0.1),
                  Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: ColorsRes.appColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.uploadLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap to browse',
            style: GoogleFonts.inter(
              color: ColorsRes.appColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: -0.15,
              height: 1.2,
            ),
          ),
        ],
      );
    } else if (widget.file != null &&
        widget.file!.path.toLowerCase().endsWith('.pdf')) {
      // PDF preview with modern card
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 32,
                color: Color(0xFFEF4444),
              ),
            ),
            SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PDF Document',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to change',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                      letterSpacing: -0.15,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Image preview with modern styling
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: widget.file != null
                ? Image.file(
                    widget.file!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  )
                : setNetworkImg(
                    image: widget.imageUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    boxFit: BoxFit.contain,
                    // errorBuilder: (context, error, stackTrace) => Center(
                    //   child: Icon(Icons.broken_image, color: Colors.grey),
                    // ),
                  ),
          ),
          // Change overlay on hover/tap
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.4],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Tap to change",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF374151),
            letterSpacing: -0.1,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Stack(
          children: [
            GestureDetector(
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) {
                _controller.reverse();
                widget.onTap();
              },
              onTapCancel: () => _controller.reverse(),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.file != null || widget.imageUrl != null
                        ? Colors.white
                        : Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: widget.file != null || widget.imageUrl != null
                        ? Border.all(color: Color(0xFFE5E7EB), width: 1)
                        : null,
                  ),
                  child: widget.file != null || widget.imageUrl != null
                      ? _buildPreview()
                      : CustomPaint(
                          painter: DashedBorderPainter(
                            color: Color(0xFFD1D5DB),
                            strokeWidth: 1.5,
                            dashWidth: 6,
                            dashSpace: 4,
                            borderRadius: 16,
                          ),
                          child: _buildPreview(),
                        ),
                ),
              ),
            ),
            // Remove button — sits OUTSIDE the tile GestureDetector
            if ((widget.file != null || widget.imageUrl != null) &&
                widget.onRemove != null)
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.borderRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final Path dashedPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path path = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        path.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      dashWidth != oldDelegate.dashWidth ||
      dashSpace != oldDelegate.dashSpace ||
      borderRadius != oldDelegate.borderRadius;
}

class _StoreImagesUploadTile extends StatefulWidget {
  final List<File> files;
  final List<String> imageUrls;
  final VoidCallback onTap;
  final Function(int) onRemove;
  final Function(int) onRemoveUrl;

  const _StoreImagesUploadTile({
    Key? key,
    required this.files,
    required this.imageUrls,
    required this.onTap,
    required this.onRemove,
    required this.onRemoveUrl,
  }) : super(key: key);

  @override
  State<_StoreImagesUploadTile> createState() => _StoreImagesUploadTileState();
}

class _StoreImagesUploadTileState extends State<_StoreImagesUploadTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full-width "Add Photos" button styled like _UploadTile
        _UploadTile(
          title: "Store Images",
          uploadLabel: "Add Store Images\nPNG, JPG",
          onTap: widget.onTap,
          // We don't pass file/imageUrl here because this is just the "Add" button
          // The images are shown below
        ),

        if (widget.imageUrls.isNotEmpty || widget.files.isNotEmpty) ...[
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                // Existing Images from Server
                ...widget.imageUrls.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _ImageThumbnail(
                      imageUrl: entry.value,
                      onRemove: () => widget.onRemoveUrl(entry.key),
                      isServerImage: true,
                    ),
                  );
                }).toList(),

                // Newly Added Images
                ...widget.files.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _ImageThumbnail(
                      file: entry.value,
                      onRemove: () => widget.onRemove(entry.key),
                      isServerImage: false,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageThumbnail extends StatefulWidget {
  final File? file;
  final String? imageUrl;
  final VoidCallback onRemove;
  final bool isServerImage;

  const _ImageThumbnail({
    Key? key,
    this.file,
    this.imageUrl,
    required this.onRemove,
    this.isServerImage = false,
  }) : super(key: key);

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.file != null
                ? Image.file(widget.file!, fit: BoxFit.cover)
                : setNetworkImg(
                    image: widget.imageUrl!,
                    boxFit: BoxFit.cover,
                    // errorBuilder: (context, error, stackTrace) =>
                    //     Center(child: Icon(Icons.error, color: Colors.red,),),
                  ),
          ),
        ),
        // Remove button for both server and local images
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onRemove();
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Confirmation Screen ---
class ConfirmationAwaitingScreen extends StatefulWidget {
  final FoodRegistrationProvider provider;
  final VoidCallback onGoDashboard;
  final VoidCallback onViewPersonal;
  final VoidCallback onViewStore;

  const ConfirmationAwaitingScreen({
    Key? key,
    required this.provider,
    required this.onGoDashboard,
    required this.onViewPersonal,
    required this.onViewStore,
  }) : super(key: key);

  @override
  State<ConfirmationAwaitingScreen> createState() =>
      _ConfirmationAwaitingScreenState();
}

class _ConfirmationAwaitingScreenState extends State<ConfirmationAwaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 40),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.check_rounded, size: 48, color: Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(height: 32),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Text(
                "Registration Complete!",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Your application has been submitted successfully. We will review your details and get back to you shortly.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.2,
                    color: Color(0xFF6B7280),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              SizedBox(height: 40),
              _InfoTile(
                title: "Personal Details",
                subtitle: "Name, Email, Phone...",
                icon: Icons.person_outline_rounded,
                onTap: widget.onViewPersonal,
              ),
              SizedBox(height: 16),
              _InfoTile(
                title: "Store Details",
                subtitle: "Store Name, Location, Tax...",
                icon: Icons.store_outlined,
                onTap: widget.onViewStore,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _InfoTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFF4B5563), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF111827),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

// --- Animated Stepper Components ---

class _AnimatedStepCircle extends StatefulWidget {
  final int index;
  final int currentIndex;

  const _AnimatedStepCircle({
    Key? key,
    required this.index,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<_AnimatedStepCircle> createState() => _AnimatedStepCircleState();
}

class _AnimatedStepCircleState extends State<_AnimatedStepCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isActive = widget.currentIndex == widget.index;
    bool isCompleted = widget.currentIndex > widget.index;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        double scale = isActive ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted
              ? Color(0xFF10B981)
              : isActive
                  ? ColorsRes.appColor
                  : Colors.white,
          border: Border.all(
            color: isCompleted
                ? Color(0xFF10B981)
                : isActive
                    ? ColorsRes.appColor
                    : Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ColorsRes.appColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: isCompleted
                ? Icon(Icons.check,
                    key: ValueKey('check'), color: Colors.white, size: 18)
                : Text(
                    "${widget.index + 1}",
                    key: ValueKey('text'),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isActive ? Colors.white : Color(0xFF9CA3AF),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStepLine extends StatelessWidget {
  final bool isActive;

  const _AnimatedStepLine({Key? key, required this.isActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: double.infinity,
      child: Stack(
        children: [
          // Background line
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Animated foreground line
          AnimatedFractionallySizedBox(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            widthFactor: isActive ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Agreement Section ────────────────────────────────────────────────────────

class AgreementSection extends StatelessWidget {
  const AgreementSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FoodRegistrationProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.description_rounded,
                  color: Color(0xFF9AC444), size: 18),
            ),
            SizedBox(width: 10),
            Text(
              'Agreement',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (provider.agreementPdfUrl == null) ...[
          _buildUploadFlow(context, provider),
        ] else ...[
          _buildExistingAgreementCard(context, provider),
        ],
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _buildUploadFlow(
      BuildContext context, FoodRegistrationProvider provider) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: Color(0xFF3B82F6)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Download the blank agreement to review the terms, then sign digitally below to accept.',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Color(0xFF1D4ED8),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // Step 1 — Download
          _buildStepRow(
            number: '1',
            color: Color(0xFF3B82F6),
            title: 'Download Agreement',
            subtitle: 'Get the blank agreement template',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isDownloadingAgreement
                    ? null
                    : () => provider.downloadAgreement(context),
                icon: provider.isDownloadingAgreement
                    ? SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF3B82F6)))
                    : Icon(Icons.download_rounded,
                        size: 17, color: Color(0xFF3B82F6)),
                label: Text(
                  provider.isDownloadingAgreement
                      ? 'Downloading...'
                      : 'Download Template',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  side: BorderSide(color: Color(0xFF3B82F6)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          _buildStepDivider(),

          // Step 2 — Digital Signature
          _buildStepRow(
            number: '2',
            color: Color(0xFF9AC444),
            title: 'Sign Digitally',
            subtitle: 'Draw your signature in the box below',
            child: _buildSignaturePad(context, provider),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // "Sign Digitally" UX upgrade.
  //
  // Inline pad below + a full-screen mode (see _openFullScreenSignature),
  // both bound to the same DrawingController so strokes stay in sync.
  // What changed vs. the old plain box:
  //   • Notepad-style "✗ ____  Sign here" guide that hides once you draw.
  //   • Live button states — Clear / Undo / Submit enable only when there's ink.
  //   • Pen / Eraser tools, selectable pen thickness, and Undo / Redo.
  //   • Active-state cues (green border + helper text) and haptic on submit.
  //   • Full-screen mode can ROTATE the canvas (not the device) for a wide
  //     signing area; the captured signature still saves upright.
  // ───────────────────────────────────────────────────────────────────────
  Widget _buildSignaturePad(
      BuildContext context, FoodRegistrationProvider provider) {
    // Rebuild whenever the strokes change so the "Sign here" guide hides and
    // the Clear / Undo / Submit buttons enable in real time.
    return AnimatedBuilder(
      animation: provider.signatureController,
      builder: (context, _) {
        final bool hasSignature = provider.hasSignature;
        final bool busy = provider.isUploadingAgreement;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Drawing surface (notepad style) ----
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: hasSignature ? Color(0xFF9AC444) : Color(0xFFD1D5DB),
                  width: hasSignature ? 1.4 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // The actual ink surface.
                  Positioned.fill(
                    child: SignatureCanvas(
                      controller: provider.signatureController,
                    ),
                  ),

                  // Notepad signature line + hint — only while empty.
                  if (!hasSignature)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Sign here',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '✗',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFFB0B6BE),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: CustomPaint(
                                      painter: _DashedLinePainter(
                                          color: Color(0xFFCBD2D9)),
                                      size: Size(double.infinity, 1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Expand-to-fullscreen affordance (top-right).
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: busy
                            ? null
                            : () => _openFullScreenSignature(context, provider),
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_full_rounded,
                                  size: 13, color: Color(0xFF6B7280)),
                              SizedBox(width: 4),
                              Text(
                                'Expand',
                                style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),
            // ---- Tool toolbar: pen / eraser / thickness / redo ----
            _buildSignatureToolbar(context, provider, busy),

            SizedBox(height: 8),
            // Helper hint below the box.
            Text(
              hasSignature
                  ? 'Looks good. Tap Submit to accept the agreement.'
                  : 'Tip: tap Expand for a larger signing area.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: hasSignature ? Color(0xFF6A8F2F) : Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 10),

            // ---- Action buttons ----
            Row(
              children: [
                // Undo last stroke.
                _signatureIconButton(
                  icon: Icons.undo_rounded,
                  tooltip: 'Undo',
                  onTap: (busy || !hasSignature)
                      ? null
                      : () => provider.undoSignature(),
                ),
                SizedBox(width: 8),
                // Clear all.
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (busy || !hasSignature)
                        ? null
                        : () => provider.clearSignature(),
                    icon: Icon(Icons.refresh_rounded,
                        size: 16,
                        color: hasSignature
                            ? Color(0xFF6B7280)
                            : Color(0xFFBCC2C9)),
                    label: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasSignature
                              ? Color(0xFF6B7280)
                              : Color(0xFFBCC2C9)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Submit (disabled until something is drawn).
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: (busy || !hasSignature)
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            provider.submitSignatureAsAgreement(context);
                          },
                    icon: busy
                        ? SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.check_circle_rounded, size: 17),
                    label: Text(
                      busy ? 'Submitting...' : 'Submit Signature',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF9AC444),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Color(0xFFCFE0AC),
                      disabledForegroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Square icon-only button used for the Undo action.
  Widget _signatureIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 42,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Icon(icon,
              size: 18,
              color: enabled ? Color(0xFF6B7280) : Color(0xFFBCC2C9)),
        ),
      ),
    );
  }

  // Toolbar with pen / eraser tools, pen thickness and redo. Compact so it
  // fits under the signing box on a phone.
  Widget _buildSignatureToolbar(
      BuildContext context, FoodRegistrationProvider provider, bool busy) {
    final bool isEraser = provider.signatureTool == DrawTool.eraser;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFEEF0F2)),
      ),
      child: Row(
        children: [
          // Tools group scrolls horizontally if the phone is narrow, so the
          // bar never overflows; Redo stays pinned on the right.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Pen / Eraser toggle.
                  _toolToggle(
                    icon: Icons.edit_rounded,
                    label: 'Pen',
                    selected: !isEraser,
                    onTap: busy
                        ? null
                        : () => provider.setSignatureTool(DrawTool.pen),
                  ),
                  SizedBox(width: 6),
                  _toolToggle(
                    icon: Icons.auto_fix_normal_rounded,
                    label: 'Eraser',
                    selected: isEraser,
                    onTap: busy
                        ? null
                        : () => provider.setSignatureTool(DrawTool.eraser),
                  ),
                  SizedBox(width: 10),
                  Container(width: 1, height: 22, color: Color(0xFFE5E7EB)),
                  SizedBox(width: 10),
                  // Pen thickness — disabled while erasing.
                  _thicknessDot(2.0, 'Thin', provider, busy, isEraser),
                  SizedBox(width: 6),
                  _thicknessDot(2.5, 'Medium', provider, busy, isEraser),
                  SizedBox(width: 6),
                  _thicknessDot(4.0, 'Bold', provider, busy, isEraser),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          // Redo last undone stroke.
          _signatureIconButton(
            icon: Icons.redo_rounded,
            tooltip: 'Redo',
            onTap: (busy || !provider.signatureController.canRedo)
                ? null
                : () => provider.redoSignature(),
          ),
        ],
      ),
    );
  }

  Widget _toolToggle({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final Color active = Color(0xFF9AC444);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? active.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? active : Color(0xFFD1D5DB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? Color(0xFF6A8F2F) : Color(0xFF6B7280)),
            SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? Color(0xFF6A8F2F) : Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A dot whose size reflects the pen thickness; tap to select it.
  Widget _thicknessDot(double width, String tooltip,
      FoodRegistrationProvider provider, bool busy, bool isEraser) {
    final bool selected = !isEraser &&
        (provider.signatureController.penWidth - width).abs() < 0.01;
    final double dot = 6 + width * 1.6;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: (busy || isEraser)
            ? null
            : () => provider.setSignaturePenWidth(width),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Color(0xFF9AC444).withValues(alpha: 0.14) : null,
            border: Border.all(
              color: selected ? Color(0xFF9AC444) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEraser ? Color(0xFFBCC2C9) : Color(0xFF374151),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Opens a distraction-free full-screen canvas that shares the same
  // controller, so strokes drawn here also appear in the inline pad. The
  // "Rotate" action turns the SIGNING SURFACE 90° (not the whole app), so the
  // user can hold the phone sideways and sign across its long edge. Because
  // only the display is rotated, the captured signature stays upright.
  void _openFullScreenSignature(
      BuildContext context, FoodRegistrationProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          bool rotated = false;
          return StatefulBuilder(
            builder: (ctx, setSheet) {
              return AnimatedBuilder(
                animation: provider.signatureController,
                builder: (ctx, _) {
                  final bool hasSignature = provider.hasSignature;
                  return Scaffold(
                    backgroundColor: Color(0xFFF3F4F6),
                    appBar: AppBar(
                      backgroundColor: Colors.white,
                      elevation: 0.5,
                      centerTitle: false,
                      title: Text(
                        'Sign Agreement',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827)),
                      ),
                      leading: IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Color(0xFF6B7280)),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      actions: [
                        // Rotate the signing surface (not the device).
                        IconButton(
                          tooltip:
                              rotated ? 'Reset orientation' : 'Rotate signature',
                          icon: Icon(
                            rotated
                                ? Icons.crop_portrait_rounded
                                : Icons.screen_rotation_rounded,
                            color:
                                rotated ? Color(0xFF6A8F2F) : Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: () => setSheet(() => rotated = !rotated),
                        ),
                        TextButton(
                          onPressed: hasSignature
                              ? () => provider.clearSignature()
                              : null,
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: hasSignature
                                  ? Color(0xFF6B7280)
                                  : Color(0xFFBCC2C9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    body: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(rotated ? 12 : 20),
                        child: Column(
                          children: [
                            // Signing surface. Rotated = fill the screen and
                            // turn 90°; normal = centered wide card.
                            Expanded(
                              child: rotated
                                  ? RotatedBox(
                                      quarterTurns: 1,
                                      child: _fullScreenSigningCard(
                                          provider, hasSignature),
                                    )
                                  : Center(
                                      child: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(maxHeight: 260),
                                        child: AspectRatio(
                                          aspectRatio: 1.6,
                                          child: _fullScreenSigningCard(
                                              provider, hasSignature),
                                        ),
                                      ),
                                    ),
                            ),
                            SizedBox(height: 14),
                            // Pen / eraser / thickness toolbar.
                            _buildSignatureToolbar(ctx, provider, false),
                            SizedBox(height: 10),
                            // Live helper text.
                            Text(
                              hasSignature
                                  ? 'Great — tap Done to use this signature.'
                                  : rotated
                                      ? 'Turn your phone sideways and sign across the screen.'
                                      : 'Tap the rotate icon for a wider signing area.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: hasSignature
                                    ? Color(0xFF6A8F2F)
                                    : Color(0xFF9CA3AF),
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: hasSignature
                                    ? () => Navigator.of(ctx).pop()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF9AC444),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Color(0xFFCFE0AC),
                                  disabledForegroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  'Done',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
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
            },
          );
        },
      ),
    );
  }

  // The white signing card (ink surface + empty-state guide). Fills whatever
  // box it's given, so it works both inside the centered card and inside the
  // rotated, full-bleed layout.
  Widget _fullScreenSigningCard(
      FoodRegistrationProvider provider, bool hasSignature) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: hasSignature ? Color(0xFF9AC444) : Color(0xFFD1D5DB),
            width: hasSignature ? 1.6 : 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: SignatureCanvas(controller: provider.signatureController),
          ),
          if (!hasSignature)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, 34),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Draw your signature here',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Text('✗',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFFB0B6BE),
                                  fontWeight: FontWeight.w700)),
                          SizedBox(width: 10),
                          Expanded(
                            child: CustomPaint(
                              painter:
                                  _DashedLinePainter(color: Color(0xFFCBD2D9)),
                              size: Size(double.infinity, 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step badge
        Container(
          width: 26,
          height: 26,
          margin: EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(number,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
              SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Color(0xFF6B7280))),
              SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() => Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          SizedBox(width: 13),
          Container(width: 1, height: 20, color: Color(0xFFE5E7EB)),
        ]),
      );

  Widget _buildExistingAgreementCard(
      BuildContext context, FoodRegistrationProvider provider) {
    final isApproved = provider.agreementStatus == 1;
    final isRejected = provider.agreementStatus == 2;
    final statusColor = isApproved
        ? Color(0xFF059669)
        : isRejected
            ? Color(0xFFDC2626)
            : Color(0xFFF59E0B);
    final statusBg = isApproved
        ? Color(0xFFECFDF5)
        : isRejected
            ? Color(0xFFFEE2E2)
            : Color(0xFFFEF3C7);
    final statusText = isApproved
        ? 'Approved'
        : isRejected
            ? 'Rejected'
            : 'Pending Review';
    final statusIcon = isApproved
        ? Icons.check_circle_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.access_time_rounded;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF9AC444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description_rounded,
                    color: Color(0xFF9AC444), size: 22),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seller Agreement',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827))),
                    SizedBox(height: 5),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          SizedBox(width: 4),
                          Text(statusText,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isApproved) ...[
            SizedBox(height: 14),
            Divider(color: Color(0xFFE5E7EB)),
            SizedBox(height: 10),
            Text(
              isRejected
                  ? 'Your agreement has been rejected. Please re-sign and submit a new agreement.'
                  : 'Your agreement is under review. You may re-sign if needed.',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isRejected ? Color(0xFFDC2626) : Color(0xFF6B7280),
                  height: 1.4),
            ),
            SizedBox(height: 14),
            _buildStepRow(
              number: '1',
              color: Color(0xFF3B82F6),
              title: 'Download Agreement',
              subtitle: 'Get the blank agreement template',
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: provider.isDownloadingAgreement
                      ? null
                      : () => provider.downloadAgreement(context),
                  icon: provider.isDownloadingAgreement
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF3B82F6)))
                      : Icon(Icons.download_rounded,
                          size: 17, color: Color(0xFF3B82F6)),
                  label: Text(
                    provider.isDownloadingAgreement
                        ? 'Downloading...'
                        : 'Download Template',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            _buildStepDivider(),
            _buildStepRow(
              number: '2',
              color: Color(0xFF9AC444),
              title: 'Sign Digitally',
              subtitle: 'Draw your signature in the box below',
              child: _buildSignaturePad(context, provider),
            ),
          ],
          SizedBox(height: 16),
          Divider(color: Color(0xFFE5E7EB)),
          SizedBox(height: 12),
          Builder(builder: (_) {
            final enabled = provider.justSubmittedSignature &&
                provider.agreementPdfUrl != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 18,
                        color: enabled
                            ? Color(0xFF059669)
                            : Color(0xFF9CA3AF)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        enabled
                            ? 'Your signed agreement is ready.'
                            : 'Submit your signature to enable.',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? Color(0xFF065F46)
                                : Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: enabled
                        ? () => launchUrl(Uri.parse(provider.agreementPdfUrl!))
                        : null,
                    icon: Icon(Icons.picture_as_pdf_rounded,
                        size: 17, color: Colors.white),
                    label: Text(
                      'View Signed Agreement',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF059669),
                      disabledBackgroundColor: Color(0xFFD1D5DB),
                      disabledForegroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Draws a thin dashed horizontal line, used as the "sign here" baseline so
/// the empty pad reads like a paper signature field.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  static const double _dashWidth = 5;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    double startX = 0;
    final double y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + _dashWidth, y), paint);
      startX += _dashWidth + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
