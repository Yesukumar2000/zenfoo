import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/view/screens/auth/login_screen.dart';
import 'package:zenfoo_partner/view/screens/auth/otp_verification_screen.dart';
import 'package:zenfoo_partner/view/screens/bottom_nav_screen.dart';
import 'package:zenfoo_partner/view/screens/delivery/chat_with_admin_screen.dart';
import 'package:zenfoo_partner/view/screens/documents/multi_step_form_screen.dart';
import 'package:zenfoo_partner/view/screens/documents/verifying_details_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/earnings_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/help_center_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/support_chat_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/profile_screen.dart';
import 'package:zenfoo_partner/view/splash_screen.dart';
import 'package:zenfoo_partner/widgets/order_listener_widget.dart';

/// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: AppRouterName.splash,
  routes: [
    GoRoute(
      path: AppRouterName.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRouterName.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRouterName.otpVerify,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OTPVerificationScreen(
          mobile: extra?['mobile'] ?? '',
          otp: extra?['otp'] ?? '',
          userId: extra?['userId'] ?? '',
          isUserExist: extra?['isUserExist'] ?? false,
        );
      },
    ),
    GoRoute(
      path: AppRouterName.multiStepForm,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MultiStepFormScreen(
          initialStep: extra?['initialStep'] ?? 0,
        );
      },
    ),
    GoRoute(
      path: AppRouterName.verifyingDetails,
      builder: (context, state) => const VerifyingDetailsScreen(),
    ),
    GoRoute(
      path: AppRouterName.bottomNavScreen,
      builder: (context, state) => const OrderListenerWidget(
        child: BottomNavBarScreen(),
      ),
    ),
    GoRoute(
      path: AppRouterName.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRouterName.earnings,
      builder: (context, state) => const EarningsScreen(),
    ),
    GoRoute(
      path: AppRouterName.helpCenter,
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: AppRouterName.supportChat,
      builder: (context, state) => const SupportChatScreen(),
    ),
    GoRoute(
      path: AppRouterName.chatWithAdmin,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ChatWithAdminScreen(
          orderId: extra?['orderId'] ?? 0,
        );
      },
    ),
  ],
);
