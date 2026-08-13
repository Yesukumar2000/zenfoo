import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/view/custom_widgets/customAppBar.dart';

class CustomGradientScaffold extends StatelessWidget {
  final Widget? leading;
  final String? title;
  final List<Widget>? action;
  final Key? scaffoldKey;

  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;

  final Widget body;
  final Widget? bottomNavigationBar;

  final double headerHeight;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;
  final Color? statusBarColor;
  final bool? isSafeArea;

  final bool? statusBarBrightnessLight;
  const CustomGradientScaffold({
    super.key,
    this.leading,
    this.title,
    this.action,
    required this.body,
    this.bottomNavigationBar,
    this.headerHeight = 160,
    this.gradientColors = const [
      AppColors.primaryColor,
      // Color(0xFF9AC444),
      AppColors.primaryColor,
      Colors.white,
    ],
    this.gradientStops = const [0.1, 0.3, 1.0],
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.scaffoldKey,
    this.drawer,
    this.appBar,
    this.statusBarColor,
    this.isSafeArea,
    this.statusBarBrightnessLight,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: statusBarBrightnessLight != null
            ? (statusBarBrightnessLight! ? Brightness.light : Brightness.dark)
            : (isDarkMode ? Brightness.light : Brightness.dark),
      ),
      child: SafeArea(
        top: isSafeArea ?? true,
        child: Scaffold(
          key: scaffoldKey,
          drawer: drawer,
          backgroundColor: Colors.white,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          floatingActionButtonAnimator: floatingActionButtonAnimator,
          body: Stack(
            children: [
              // ---------------------- GRADIENT BACKGROUND ----------------------
              Container(
                height: headerHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    stops: gradientStops,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // ---------------------- PAGE CONTENT ----------------------
              Column(
                children: [
                  appBar ??
                      AppBar(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        title: Text(
                          title ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  // ---------------------- BODY ----------------------
                  Expanded(child: body),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
