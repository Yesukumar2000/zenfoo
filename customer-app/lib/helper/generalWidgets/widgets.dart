import 'dart:ui' show ImageFilter;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

Widget gradientBtnWidget(BuildContext context, double borderRadius,
    {required Function callback,
    String title = "",
    Widget? otherWidgets,
    double? height,
    double? width,
    Color? color1,
    Color? color2}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
  return GestureDetector(
    onTap: () {
      callback();
    },
    child: Container(
      height: height ?? 45,
      width: width,
      alignment: Alignment.center,
      decoration: DesignConfig.boxGradient(
        borderRadius,
        color1: color1,
        color2: color2,
      ),
      child: otherWidgets ??= CustomTextLabel(
        text: title,
        softWrap: true,
        style: Theme.of(context).textTheme.titleMedium!.merge(TextStyle(
            color: colorScheme.buttonPrimaryText,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500)),
      ),
    ),
  );
}

getDarkLightIcon({
  double? height,
  double? width,
  required String image,
  Color? iconColor,
  BoxFit? boxFit,
  EdgeInsetsDirectional? padding,
  bool? isActive,
}) {
  String dark =
      (Constant.session.getBoolData(SessionManager.isDarkTheme)) == true
          ? "_dark"
          : "";
  String active = (isActive ??= false) == true ? "_active" : "";

  return defaultImg(
      height: height,
      width: width,
      image: "$image$active${dark}${AppAssets.icon}",
      iconColor: iconColor,
      boxFit: boxFit,
      padding: padding);
}

List getHomeBottomNavigationBarIcons({required bool isActive}) {
  return [
    getDarkLightIcon(
        image: "home",
        isActive: isActive,
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0)),
    getDarkLightIcon(
        image: "category",
        isActive: isActive,
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0)),
    getDarkLightIcon(
        image: "wishlist",
        isActive: isActive,
        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0)),
    getDarkLightIcon(
        image: "profile",
        isActive: isActive,
        padding: EdgeInsetsDirectional.zero),
  ];
}

String getStorePlaceholderUrl({int? storeId, bool isMeat = false, bool isSuperMart = false}) {
  // is_meat=1 covers store IDs 14 (Chicken & Meat), 18 (Mutton), 19 (Fish), 20 (Camel)
  if (isMeat && Constant.storePlaceholderImgMeat.isNotEmpty) return Constant.storePlaceholderImgMeat;
  // is_super_mart=1 covers store ID 17
  if (isSuperMart && Constant.storePlaceholderImgSupermart.isNotEmpty) return Constant.storePlaceholderImgSupermart;
  if (storeId != null) {
    switch (storeId) {
      case 15: return Constant.storePlaceholderImgFood.isNotEmpty ? Constant.storePlaceholderImgFood : "";
      case 13: return Constant.storePlaceholderImgVeg.isNotEmpty ? Constant.storePlaceholderImgVeg : "";
      case 12: return Constant.storePlaceholderImgGrocery.isNotEmpty ? Constant.storePlaceholderImgGrocery : "";
      case 17: return Constant.storePlaceholderImgSupermart.isNotEmpty ? Constant.storePlaceholderImgSupermart : "";
      // meat stores by ID (fallback if isMeat flag not passed)
      case 14:
      case 18:
      case 19:
      case 20: return Constant.storePlaceholderImgMeat.isNotEmpty ? Constant.storePlaceholderImgMeat : "";
    }
  }
  return "";
}

Widget setNetworkImg({
  double? height,
  double? width,
  String image = AppAssets.placeholderIcon,
  Color? iconColor,
  BoxFit? boxFit,
  BorderRadius? borderRadius,
  int? storeId,
  bool isMeat = false,
  bool isSuperMart = false,
  // Fills the tile behind a BoxFit.contain image with a blurred, zoomed copy of
  // the same photo. Without it a square photo in a taller tile leaves bare bands
  // above and below — invisible on a white-background packshot, but obvious on
  // the food photography, which mostly has a dark background. This keeps the
  // product uncropped AND leaves no dead space.
  bool fillBackdrop = false,
}) {
  if (image.trim().isNotEmpty && !image.contains("http")) {
    image = "${Constant.hostUrl}storage/$image";
  }

  final String placeholderUrl = getStorePlaceholderUrl(storeId: storeId, isMeat: isMeat, isSuperMart: isSuperMart);
  if (image.trim().isEmpty || image == "null" || image.contains("storage/null")) {
    print("🔍 imgPlaceholder | storeId=$storeId isMeat=$isMeat isSuperMart=$isSuperMart → placeholderUrl=$placeholderUrl");
  }

  return image.trim().isEmpty
      ? imgErrorWidget(
          height: height,
          width: width,
          placeholderImageUrl: placeholderUrl.isNotEmpty ? placeholderUrl : null,
        )
      : ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (fillBackdrop)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      // The backdrop is decoration; it must never show a
                      // shimmer or a broken-image icon of its own.
                      placeholder: (context, url) => const SizedBox.shrink(),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              if (fillBackdrop)
                Positioned.fill(
                  child: Container(color: Colors.white.withValues(alpha: 0.35)),
                ),
              CachedNetworkImage(
            imageUrl: image,
            height: height,
            width: width,
            fit: boxFit,
            placeholder: (context, url) => CustomShimmer(
              height: height,
              width: width,
              borderRadius: borderRadius != null
                  ? (borderRadius.topLeft.x +
                          borderRadius.topRight.x +
                          borderRadius.bottomLeft.x +
                          borderRadius.bottomRight.x) /
                      4
                  : 0,
            ),
            errorWidget: (context, url, error) => imgErrorWidget(
              height: height,
              width: width,
              placeholderImageUrl: placeholderUrl.isNotEmpty ? placeholderUrl : null,
            ),
              ),
            ],
          ),
        );
}

Widget defaultImg({
  double? height,
  double? width,
  required String image,
  Color? iconColor,
  BoxFit? boxFit,
  EdgeInsetsDirectional? padding,
  bool? requiredRTL = true,
}) {
  return Padding(
    padding: padding ?? const EdgeInsets.all(0),
    child: (image.contains("png") ||
            image.contains("jpeg") ||
            image.contains("jpg"))
        ? Image.asset(Constant.getAssetsPath(0, image))
        : SvgPicture.asset(
            Constant.getAssetsPath(1, image),
            width: width,
            height: height,
            colorFilter: iconColor != null
                ? ColorFilter.mode(iconColor, BlendMode.srcIn)
                : null,
            fit: boxFit ?? BoxFit.contain,
            matchTextDirection: requiredRTL ?? true,
          ),
  );
}

/// Zomato/Swiggy/Zepto-style fallback shown when a network image fails to load
/// or has no URL. Uses a light grey background with a centered icon.
///
/// Use [icon] to pick the context-appropriate icon:
///   - Product/food  → Icons.restaurant_menu_rounded (default)
///   - Store         → Icons.storefront_rounded
///   - Category      → Icons.category_rounded
///   - Profile       → Icons.person_rounded
Widget imgErrorWidget({
  double? height,
  double? width,
  IconData icon = Icons.restaurant_menu_rounded,
  double iconSize = 32,
  BorderRadius? borderRadius,
  String? placeholderImageUrl,
}) {
  Widget child;
  if (placeholderImageUrl != null && placeholderImageUrl.isNotEmpty) {
    final img = CachedNetworkImage(
      imageUrl: placeholderImageUrl,
      fit: BoxFit.contain,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      placeholder: (_, __) => Container(color: const Color(0xFFF0F0F0), child: Center(child: Icon(icon, color: const Color(0xFFBDBDBD), size: iconSize))),
      errorWidget: (_, __, ___) => Container(color: const Color(0xFFF0F0F0), child: Center(child: Icon(icon, color: const Color(0xFFBDBDBD), size: iconSize))),
    );
    child = (height == null && width == null)
        ? SizedBox.expand(child: img)
        : Container(height: height, width: width, color: const Color(0xFFF0F0F0), child: img);
  } else {
    child = Container(
      height: height,
      width: width,
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Icon(icon, color: const Color(0xFFBDBDBD), size: iconSize),
      ),
    );
  }
  if (borderRadius != null) {
    child = ClipRRect(borderRadius: borderRadius, child: child);
  }
  return child;
}

Widget getSizedBox({double? height, double? width, Widget? child}) {
  return SizedBox(
    height: height ?? 0,
    width: width ?? 0,
    child: child,
  );
}

Widget getDivider(
    {BuildContext? context,
    Color? color,
    double? endIndent,
    double? height,
    double? indent,
    double? thickness}) {
  return Builder(
    builder: (builderContext) {
      final colorScheme = context != null
          ? context.watch<app_theme.ThemeProvider>().colorScheme
          : builderContext.watch<app_theme.ThemeProvider>().colorScheme;
      return Divider(
        color: color ?? colorScheme.border,
        endIndent: endIndent ?? 0,
        indent: indent ?? 0,
        height: height,
        thickness: thickness,
      );
    },
  );
}

Widget getLoadingIndicator({BuildContext? context}) {
  return Builder(
    builder: (builderContext) {
      final colorScheme = context != null
          ? context.watch<app_theme.ThemeProvider>().colorScheme
          : builderContext.watch<app_theme.ThemeProvider>().colorScheme;
      return CircularProgressIndicator(
        backgroundColor: Colors.transparent,
        color: colorScheme.primary,
        strokeWidth: 2,
      );
    },
  );
}

// CategorySimmer
Widget getCategoryShimmer(
    {required BuildContext context, int? count, EdgeInsets? padding}) {
  return GridView.builder(
    itemCount: count,
    padding: padding ??
        EdgeInsets.symmetric(
            horizontal: Constant.size10, vertical: Constant.size10),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (BuildContext context, int index) {
      return CustomShimmer(
        width: context.width,
        height: context.height,
        borderRadius: 8,
      );
    },
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 0.8,
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10),
  );
}

// CategorySimmer
Widget getRatingPhotosShimmer(
    {required BuildContext context, int? count, EdgeInsets? padding}) {
  return GridView.builder(
    itemCount: count,
    padding: padding ??
        EdgeInsets.symmetric(
            horizontal: Constant.size10, vertical: Constant.size10),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (BuildContext context, int index) {
      return CustomShimmer(
        width: context.width,
        height: context.height,
        borderRadius: 8,
      );
    },
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 0.8,
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10),
  );
}

// BrandSimmer
Widget getBrandShimmer(
    {required BuildContext context, int? count, EdgeInsets? padding}) {
  return GridView.builder(
    itemCount: count,
    padding: padding ??
        EdgeInsets.symmetric(
            horizontal: Constant.size10, vertical: Constant.size10),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (BuildContext context, int index) {
      return CustomShimmer(
        width: context.width,
        height: context.height,
        borderRadius: 8,
      );
    },
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 0.8,
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10),
  );
}

// BrandSimmer
Widget getSellerShimmer(
    {required BuildContext context, int? count, EdgeInsets? padding}) {
  return GridView.builder(
    itemCount: count,
    padding: padding ??
        EdgeInsets.symmetric(
            horizontal: Constant.size10, vertical: Constant.size10),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (BuildContext context, int index) {
      return CustomShimmer(
        width: context.width,
        height: context.height,
        borderRadius: 8,
      );
    },
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 0.8,
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10),
  );
}

AppBar getAppBar(
    {required BuildContext context,
    bool? centerTitle,
    required Widget title,
    List<Widget>? actions,
    Color? backgroundColor,
    bool? showBackButton,
    GestureTapCallback? onTap}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
  return AppBar(
    leading: showBackButton ?? true
        ? GestureDetector(
            onTap: onTap ??
                () {
                  Navigator.pop(context);
                },
            child: Container(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: SizedBox(
                  child: defaultImg(
                    boxFit: BoxFit.contain,
                    image: AppAssets.icArrowBackIcon,
                    iconColor: colorScheme.textPrimary,
                  ),
                  height: 10,
                  width: 10,
                ),
              ),
            ),
          )
        : null,
    automaticallyImplyLeading: true,
    elevation: 0,
    titleSpacing: 0,
    title: Row(
      children: [
        if (showBackButton == false || !Navigator.of(context).canPop())
          getSizedBox(
            width: 10,
          ),
        Expanded(child: title),
      ],
    ),
    centerTitle: centerTitle ?? false,
    surfaceTintColor: Colors.transparent,
    backgroundColor: backgroundColor ?? colorScheme.surface,
    actions: actions ?? [],
  );
}

Widget getProductListShimmer(
    {required BuildContext context, required bool isGrid}) {
  return isGrid
      ? GridView.builder(
          itemCount: 6,
          padding: EdgeInsets.symmetric(
              horizontal: Constant.size10, vertical: Constant.size10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return const CustomShimmer(
              width: double.maxFinite,
              height: double.maxFinite,
            );
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 0.7,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
        )
      : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(20, (index) {
              return const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(10, 0, 10, 10),
                child: CustomShimmer(
                  width: double.maxFinite,
                  height: 125,
                ),
              );
            }),
          ),
        );
}

Widget getProductItemShimmer(
    {required BuildContext context, required bool isGrid}) {
  return isGrid
      ? GridView.builder(
          itemCount: 2,
          padding: EdgeInsets.symmetric(
              horizontal: Constant.size10, vertical: Constant.size10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return const CustomShimmer(
              width: double.maxFinite,
              height: double.maxFinite,
            );
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 0.7,
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
        )
      : const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(10, 0, 10, 10),
          child: CustomShimmer(
            width: double.maxFinite,
            height: 125,
          ),
        );
}

Widget getSearchWidget({
  required BuildContext context,
}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

  final placeholderHints = [
    'Search for grocery items',
    'Search food',
    'Search snacks',
    'Search bakery',
    'Search vegetables',
  ];

  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, productSearchScreen);
    },
    child: Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Search icon
            Icon(Icons.search, color: colorScheme.iconSecondary, size: 24),
            const SizedBox(width: 8),
            // Animated hints/scrolling text
            Expanded(
              child: AnimatedTextKit(
                repeatForever: true,
                animatedTexts: placeholderHints.map((hint) {
                  return FadeAnimatedText(
                    hint,
                    textStyle: GoogleFonts.inter(
                      color: colorScheme.inputPlaceholder,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    duration: const Duration(seconds: 2),
                  );
                }).toList(),
                pause: const Duration(milliseconds: 800),
                isRepeatingAnimation: true,
                displayFullTextOnTap: true,
              ),
            ),
            // Mic icon
            SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                "assets/icons/mic.png",
                color: colorScheme.textPrimary,
              ),
            ),
            // Divider
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 24,
              color: colorScheme.border,
            ),
            // Note icon (receipt, list, etc.)
            SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                "assets/icons/note.png",
                color: colorScheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
// Compact tappable search bar used on store/category screens.
// It does not accept input itself — tapping it routes to a full search experience.
Widget getTapToSearchBar({
  required BuildContext context,
  required VoidCallback onTap,
  String hintKey = 'search_for_items',
  // When true, uses a shorter (less tall) layout. Opt-in so existing
  // callers keep their original height.
  bool compact = false,
}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
  final double verticalPadding = compact ? 6 : 12;
  final double verticalMargin = compact ? 7 : 12;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: verticalMargin),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.inputBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.only(
          start: 16, end: 8, top: verticalPadding, bottom: verticalPadding),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colorScheme.iconSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              getTranslatedValue(context, hintKey),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: colorScheme.inputPlaceholder,
                height: 1.4,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.mic_none_rounded, color: colorScheme.primary, size: 20),
          ),
        ],
      ),
    ),
  );
}

//Search widgets for the multiple screen
// Widget getSearchWidget({
//   required BuildContext context,
// }) {
//   return GestureDetector(
//     onTap: () {
//       Navigator.pushNamed(context, productSearchScreen);
//     },
//     child: Container(
//       color: Theme.of(context).cardColor,
//       padding: const EdgeInsetsDirectional.only(
//         start: 24,
//         end: 24,
//         bottom: 10,
//         top: 24,
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: DesignConfig.boxDecoration(Theme.of(context).scaffoldBackgroundColor, 10),
//               child: Consumer<LanguageProvider>(
//                 builder: (context, provider, child) {
//                   return ListTile(
//                     dense: true,
//                     title: TextField(
//                       enabled: false,
//                       decoration: InputDecoration(
//                         border: InputBorder.none,
//                         isDense: true,
//                         hintText: getTranslatedValue(context, productSearchHintLabel),
//                         hintStyle: TextStyle(
//                           color: ColorsRes.subTitleMainTextColor,
//                         ),
//                         iconColor: ColorsRes.subTitleMainTextColor,
//                       ),
//                     ),
//                     horizontalTitleGap: 0,
//                     contentPadding: EdgeInsets.zero,
//                     leading: IconButton(
//                       padding: EdgeInsets.zero,
//                       icon: Icon(
//                         Icons.search,
//                         color: ColorsRes.subTitleMainTextColor,
//                       ),
//                       onPressed: null,
//                     ),
//                     trailing: Padding(
//                       padding: const EdgeInsetsDirectional.only(end: 10),
//                       child: defaultImg(
//                         image: AppAssets.voiceSearchIcon,
//                         height: 24,
//                         iconColor: ColorsRes.subTitleMainTextColor,
//                         width: 24,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           SizedBox(width: Constant.size10),
//           ChangeNotifierProvider<ProductDetailProvider>(
//             create: (context) => ProductDetailProvider(),
//             builder: (context, child) {
//               return GestureDetector(
//                 onTap: () async {
//                   print("Tapped");
//                   await hasCameraPermissionGiven(context).then(
//                     (value) async {
//                       if (value.isGranted) {
//                         Navigator.pushNamed(context, barCodeScanner).then(
//                           (value) {
//                             if (value != "-1" && value != null) {
//                               Navigator.pushNamed(
//                                 context,
//                                 productDetailScreen,
//                                 arguments: [
//                                   value.toString(),
//                                   getTranslatedValue(navigatorKey.currentContext!, appNameLabel),
//                                   null,
//                                   "barcode",
//                                 ],
//                               );
//                             }
//                           },
//                         );
//                         /*
//                           if (value != "-1") {
//                             Navigator.pushNamed(
//                               context,
//                               productDetailScreen,
//                               arguments: [
//                                 value.toString(),
//                                 getTranslatedValue(
//                                     navigatorKey.currentContext!,
//                                     appNameLabel),
//                                 null,
//                                 "barcode",
//                               ],
//                             );
//                           }
//                         */
//                       } else if (value.isDenied) {
//                         await Permission.camera.request();
//                       } else if (value.isPermanentlyDenied) {
//                         if (!Constant.session.getBoolData(SessionManager.keyPermissionCameraHidePromptPermanently)) {
//                           showModalBottomSheet(
//                             context: context,
//                             builder: (context) {
//                               return Wrap(
//                                 children: [
//                                   PermissionHandlerBottomSheet(
//                                     titleJsonKey: cameraPermissionTitleLabel,
//                                     messageJsonKey: cameraPermissionMessageLabel,
//                                     sessionKeyForAskNeverShowAgain: SessionManager.keyPermissionCameraHidePromptPermanently,
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         }
//                       }
//                     },
//                   );
//                 },
//                 child: Container(
//                   decoration: DesignConfig.boxGradient(10),
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                   child: defaultImg(
//                     image: AppAssets.barcodeScannerIcon,
//                     iconColor: ColorsRes.appColorWhite,
//                     height: 24,
//                     width: 24,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     ),
//   );
// }

Widget setRefreshIndicator({
  required RefreshCallback refreshCallback,
  required Widget child,
  RefreshController? controller,
}) {
  if (controller == null) {
    controller = RefreshController();
  }

  return SmartRefresher(
    controller: controller,
    header: CustomHeader(
      builder: (context, mode) => Container(
        alignment: Alignment.center,
        height: 80,
        child: mode == RefreshStatus.refreshing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/animations/home.gif",
                      width: 40, height: 40),
                  SizedBox(width: 12),
                  Text('Getting the freshest data...',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              )
            : Text('↓ Pull to refresh', style: TextStyle(fontSize: 16)),
      ),
    ),
    footer: CustomFooter(
      builder: (context, mode) => Container(
        alignment: Alignment.center,
        height: 60,
        child: mode == LoadStatus.loading
            ? CircularProgressIndicator()
            : Text('↑ Pull up for more', style: TextStyle(fontSize: 15)),
      ),
    ),
    enablePullDown: true,
    enablePullUp: true,
    onRefresh: () async {
      await refreshCallback();
      controller!.refreshCompleted();
    },
    onLoading: () async {
      // For "load more" footer logic, you can add pagination etc.
      await Future.delayed(Duration(milliseconds: 1500));
      controller!.loadComplete();
    },
    child: child,
  );
}

Widget setNotificationIcon({required BuildContext context}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
  return IconButton(
    onPressed: () {
      Navigator.pushNamed(context, notificationListScreen);
    },
    icon: defaultImg(
      image: AppAssets.notificationIcon,
      iconColor: colorScheme.primary,
    ),
  );
}

Widget getOverallRatingSummary(
    {required BuildContext context,
    required ProductRatingData productRatingData,
    required String totalRatings}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

  // Calculate all star counts
  int fiveStarCount = productRatingData.fiveStarRating.toString().toInt;
  int fourStarCount = productRatingData.fourStarRating.toString().toInt;
  int threeStarCount = productRatingData.threeStarRating.toString().toInt;
  int twoStarCount = productRatingData.twoStarRating.toString().toInt;
  int oneStarCount = productRatingData.oneStarRating.toString().toInt;
  int totalCount = totalRatings.toString().toInt;

  /* print("🌟 Rating Summary Debug:");
  print("5★: $fiveStarCount, 4★: $fourStarCount, 3★: $threeStarCount, 2★: $twoStarCount, 1★: $oneStarCount");
  print("Total: $totalCount"); */

  // Calculate percentages
  double fiveStarPercentage = totalCount > 0 ? fiveStarCount / totalCount : 0.0;
  double fourStarPercentage = totalCount > 0 ? fourStarCount / totalCount : 0.0;
  double threeStarPercentage =
      totalCount > 0 ? threeStarCount / totalCount : 0.0;
  double twoStarPercentage = totalCount > 0 ? twoStarCount / totalCount : 0.0;
  double oneStarPercentage = totalCount > 0 ? oneStarCount / totalCount : 0.0;

  /* print("Percentages: 5★=${fiveStarPercentage.toStringAsFixed(2)}, 4★=${fourStarPercentage.toStringAsFixed(2)}, 3★=${threeStarPercentage.toStringAsFixed(2)}, 2★=${twoStarPercentage.toStringAsFixed(2)}, 1★=${oneStarPercentage.toStringAsFixed(2)}");
  print("Data Assignment Check:");
  print("Index 4 (5★): count=$fiveStarCount, percentage=${fiveStarPercentage.toStringAsFixed(3)}");
  print("Index 3 (4★): count=$fourStarCount, percentage=${fourStarPercentage.toStringAsFixed(3)}");
  print("Index 2 (3★): count=$threeStarCount, percentage=${threeStarPercentage.toStringAsFixed(3)}");
  print("Index 1 (2★): count=$twoStarCount, percentage=${twoStarPercentage.toStringAsFixed(3)}");
  print("Index 0 (1★): count=$oneStarCount, percentage=${oneStarPercentage.toStringAsFixed(3)}"); */

  return Row(
    children: [
      Column(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            maxRadius: 45,
            minRadius: 20,
            child: CustomTextLabel(
              text:
                  "${totalRatings}", //"${productRatingData.averageRating.toString().toDouble}",
              style: TextStyle(
                color: colorScheme.buttonPrimaryText,
                fontWeight: FontWeight.bold,
                fontSize: 35,
              ),
            ),
          ),
          getSizedBox(height: 10),
          CustomTextLabel(
            text: "${getTranslatedValue(context, ratingLabel)}\n$totalCount",
            style: TextStyle(
              color: colorScheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      Container(
        margin: EdgeInsetsDirectional.only(start: 20, end: 20),
        color: colorScheme.border,
        height: 165,
        width: 0.7,
      ),
      Expanded(
        child: Column(
          children: [
            PercentageWiseRatingBar(
              context: context,
              index: 4,
              totalRatings: fiveStarCount,
              ratingPercentage: fiveStarPercentage,
            ),
            PercentageWiseRatingBar(
              context: context,
              index: 3,
              totalRatings: fourStarCount,
              ratingPercentage: fourStarPercentage,
            ),
            PercentageWiseRatingBar(
              context: context,
              index: 2,
              totalRatings: threeStarCount,
              ratingPercentage: threeStarPercentage,
            ),
            PercentageWiseRatingBar(
              context: context,
              index: 1,
              totalRatings: twoStarCount,
              ratingPercentage: twoStarPercentage,
            ),
            PercentageWiseRatingBar(
              context: context,
              index: 0,
              totalRatings: oneStarCount,
              ratingPercentage: oneStarPercentage,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget PercentageWiseRatingBar({
  required double ratingPercentage,
  required int totalRatings,
  required int index,
  required BuildContext context,
}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

  print(
      "⭐ Creating ${index + 1} star bar: ratings=$totalRatings, percentage=$ratingPercentage");
  return Column(
    children: [
      Row(
        children: [
          CustomTextLabel(
            text: "${index + 1}",
          ),
          getSizedBox(width: 5),
          Icon(
            Icons.star_rounded,
            color: Colors.amber,
          ),
          getSizedBox(width: 5),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: colorScheme.textPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double fillWidth = 0.0;

                  if (totalRatings > 0) {
                    // Fixed percentage based on star level for visual hierarchy
                    // 5★=100%, 4★=90%, 3★=80%, 2★=70%, 1★=60%
                    double starLevelPercentage =
                        0.6 + ((index) * 0.1); // 0.6 to 1.0
                    fillWidth = constraints.maxWidth * starLevelPercentage;
                  } else {
                    // If no ratings for this star level, show empty
                    fillWidth = 0.0;
                  }

                  print(
                      "📊 ${index + 1} stars: actualPercentage=${ratingPercentage.toStringAsFixed(3)}, visualPercentage=${((0.6 + (index * 0.1)) * 100).toStringAsFixed(0)}%, finalWidth=${fillWidth.toStringAsFixed(1)}/${constraints.maxWidth.toStringAsFixed(1)}");

                  if (fillWidth <= 0) {
                    return SizedBox.shrink();
                  }

                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      width: fillWidth,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          getSizedBox(width: 10),
          CustomTextLabel(
            text: "$totalRatings",
            style: TextStyle(
              color: colorScheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      getSizedBox(height: 10),
    ],
  );
}

double calculatePercentage(
    {required int totalRatings, required int starsWiseRatings}) {
  if (totalRatings == 0) {
    return 0.0;
  }

  double percentage = (starsWiseRatings * 100) / totalRatings;
  double result = percentage / 100;
  print(
      "calculatePercentage: starsWise=$starsWiseRatings, total=$totalRatings, percentage=$percentage%, result=$result");
  return result;
}

Widget getRatingReviewItem(
    {required ProductRatingList rating, required BuildContext context}) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsetsDirectional.only(
              start: 5,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadiusDirectional.all(
                Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                CustomTextLabel(
                  text: rating.rate,
                  style: TextStyle(
                    color: colorScheme.buttonPrimaryText,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Icon(
                  Icons.star_rate_rounded,
                  color: Colors.amber,
                  size: 20,
                )
              ],
            ),
          ),
          getSizedBox(width: 7),
          CustomTextLabel(
            text: rating.user?.name.toString() ?? "",
            style: TextStyle(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15),
            softWrap: true,
          )
        ],
      ),
      getSizedBox(height: 10),
      if (rating.review.toString().length > 100)
        ExpandableText(
          text: rating.review.toString(),
          max: 0.2,
          color: colorScheme.textSecondary,
        ),
      if (rating.review.toString().length <= 100)
        CustomTextLabel(
          text: rating.review.toString(),
          style: TextStyle(
            color: colorScheme.textSecondary,
          ),
        ),
      getSizedBox(height: 10),
      if (rating.images != null && rating.images!.length > 0)
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            runSpacing: 10,
            spacing: constraints.maxWidth * 0.017,
            children: List.generate(
              rating.images!.length,
              (index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                        context, fullScreenProductImageScreen, arguments: [
                      index,
                      rating.images?.map((e) => e.imageUrl.toString()).toList()
                    ]);
                  },
                  child: ClipRRect(
                    borderRadius: Constant.borderRadius2,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: setNetworkImg(
                      image: rating.images?[index].imageUrl ?? "",
                      width: 50,
                      height: 50,
                      boxFit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      getSizedBox(height: 10),
      CustomTextLabel(
        text: rating.updatedAt.toString().formatDate(),
        style: TextStyle(
          color: colorScheme.textSecondary,
        ),
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

Widget CheckoutShimmer() {
  return _ModernCheckoutShimmer();
}

Widget DeliveryChargeShimmer() {
  return _ModernDeliveryChargeShimmer();
}

Widget DashedDivider({Color? color, double? height}) {
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
      final boxWidth = constraints.constrainWidth();
      const dashWidth = 5.0;
      final dashHeight = height;
      final dashCount = (boxWidth / (2 * dashWidth)).floor();
      return Flex(
        children: List.generate(dashCount, (_) {
          return SizedBox(
            width: dashWidth,
            height: dashHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color ?? colorScheme.border),
            ),
          );
        }),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        direction: Axis.horizontal,
      );
    },
  );
}

Widget getHomeScreenShimmer(BuildContext context) {
  return Padding(
    padding: EdgeInsets.symmetric(
        vertical: Constant.size10, horizontal: Constant.size10),
    child: Column(
      children: [
        CustomShimmer(
          height: context.height * 0.26,
          width: context.width,
        ),
        getSizedBox(
          height: Constant.size10,
        ),
        CustomShimmer(
          height: Constant.size10,
          width: context.width,
        ),
        getSizedBox(
          height: Constant.size10,
        ),
        getCategoryShimmer(
            context: context, count: 6, padding: EdgeInsets.zero),
        getSizedBox(
          height: Constant.size10,
        ),
        Column(
          children: List.generate(5, (index) {
            return Column(
              children: [
                const CustomShimmer(height: 50),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: Constant.size10,
                            horizontal: Constant.size5),
                        child: CustomShimmer(
                          height: 210,
                          width: context.width * 0.4,
                        ),
                      );
                    }),
                  ),
                )
              ],
            );
          }),
        )
      ],
    ),
  );
}

Widget ProductListViewListingWidget({required List<ProductListItem> products}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      products.length,
      (index) {
        return ProductListItemContainer(product: products[index]);
      },
    ),
  );
}

Widget ProductGridViewListingWidget({required List<ProductListItem> products}) {
  return GridView.builder(
    itemCount: products.length,
    padding: EdgeInsetsDirectional.only(
        start: Constant.size10,
        end: Constant.size10,
        bottom: Constant.size10,
        top: Constant.size5),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemBuilder: (BuildContext context, int index) {
      return ProductGridItemContainer(product: products[index]);
    },
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      childAspectRatio: 0.55,
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
  );
}

Widget ProductWidget({VoidCallback? voidCallBack, required String from}) {
  return Consumer<ProductListProvider>(
    builder: (context, productListProvider, _) {
      List<ProductListItem> products = productListProvider.products;
      if (productListProvider.productState == ProductState.initial ||
          productListProvider.productState == ProductState.loading) {
        return getProductListShimmer(
            context: context,
            isGrid: context
                .read<ProductChangeListingTypeProvider>()
                .getListingType());
      } else if (productListProvider.productState == ProductState.loaded ||
          productListProvider.productState == ProductState.loadingMore) {
        return Column(
          children: [
            (context
                            .read<ProductChangeListingTypeProvider>()
                            .getListingType() ==
                        true &&
                    from == "product_listing")
                ? /* GRID VIEW UI */ ProductGridViewListingWidget(
                    products: products)
                : /* LIST VIEW UI */ ProductListViewListingWidget(
                    products: products),
            if (productListProvider.productState == ProductState.loadingMore)
              getProductItemShimmer(
                  context: context,
                  isGrid: context
                      .read<ProductChangeListingTypeProvider>()
                      .getListingType()),
            if (context.watch<CartProvider>().totalItemsCount > 0)
              getSizedBox(height: 65),
          ],
        );
      } else if (productListProvider.productState == ProductState.empty &&
          from == "product_listing") {
        return DefaultBlankItemMessageScreen(
          title: emptyProductListMessageLabel,
          description: emptyProductListDescriptionLabel,
          image: "no_product_icon",
        );
      } else if (from != "product_listing") {
        return Container();
      } else {
        return NoInternetConnectionScreen(
          height: context.height * 0.65,
          message: productListProvider.message,
          callback: voidCallBack,
        );
      }
    },
  );
}

PinTheme getDefaultPinTheme(BuildContext context) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
  return PinTheme(
    width: 48,
    height: 48,
    textStyle: TextStyle(
      fontSize: 20,
      color: colorScheme.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      border: Border.all(
        color: colorScheme.inputBorder,
      ),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

PinTheme getFocusedPinTheme(BuildContext context) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
  return PinTheme(
    width: 48,
    height: 48,
    textStyle: TextStyle(
      fontSize: 20,
      color: colorScheme.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: colorScheme.inputBackground),
      borderRadius: BorderRadius.circular(10),
      color: colorScheme.inputBackground,
    ),
  ).copyDecorationWith(
    border: Border.all(color: colorScheme.primary),
    borderRadius: BorderRadius.circular(10),
  );
}

PinTheme getSubmittedPinTheme(BuildContext context) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
  return PinTheme(
    width: 48,
    height: 48,
    textStyle: TextStyle(
      fontSize: 20,
      color: colorScheme.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      color: colorScheme.inputBackground,
      borderRadius: BorderRadius.circular(10),
    ),
  ).copyWith(
    decoration: BoxDecoration(
      color: colorScheme.inputBackground,
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

Widget otpPinWidget(
    {required BuildContext context,
    required TextEditingController pinController,
    VoidCallback? onCompleted}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: AutofillGroup(
      child: Pinput(
        defaultPinTheme: getDefaultPinTheme(context),
        focusedPinTheme: getFocusedPinTheme(context),
        submittedPinTheme: getSubmittedPinTheme(context),
        /* onClipboardFound: (value) {
          pinController.setText(value);
        }, */
        controller: pinController,
        length: 4,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        hapticFeedbackType: HapticFeedbackType.heavyImpact,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          FilteringTextInputFormatter.singleLineFormatter
        ],
        autofocus: true,
        closeKeyboardWhenCompleted: true,
        pinAnimationType: PinAnimationType.slide,
        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
        animationCurve: Curves.bounceInOut,
        enableSuggestions: true,
        pinContentAlignment: AlignmentDirectional.center,
        isCursorAnimationEnabled: true,
        onCompleted: (value) {
          onCompleted?.call();
        },
      ),
    ),
  );
}

// Modern Animated Shimmer for Checkout Screen
class _ModernCheckoutShimmer extends StatefulWidget {
  const _ModernCheckoutShimmer({Key? key}) : super(key: key);

  @override
  State<_ModernCheckoutShimmer> createState() => _ModernCheckoutShimmerState();
}

class _ModernCheckoutShimmerState extends State<_ModernCheckoutShimmer>
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

  Widget _buildShimmerBox(double height, double width, BuildContext context,
      {double borderRadius = 12}) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isDark = colorScheme.isDark;

    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [
                  Color(0xFF2C2C2C),
                  Color(0xFF3C3C3C),
                  Color(0xFF2C2C2C),
                ]
              : [
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (builderContext, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address card shimmer
            _buildShimmerBox(150, double.maxFinite, builderContext),
            // Section title shimmer
            _buildShimmerBox(25, 250, builderContext, borderRadius: 10),
            // Time slots horizontal shimmer
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  5,
                  (index) => _buildShimmerBox(80, 80, builderContext,
                      borderRadius: 10),
                ),
              ),
            ),
            // Payment methods shimmer
            _buildShimmerBox(45, double.maxFinite, builderContext,
                borderRadius: 10),
            _buildShimmerBox(45, double.maxFinite, builderContext,
                borderRadius: 10),
            _buildShimmerBox(45, double.maxFinite, builderContext,
                borderRadius: 10),
            // Billing section title shimmer
            _buildShimmerBox(25, 250, builderContext, borderRadius: 10),
          ],
        );
      },
    );
  }
}

// Modern Animated Shimmer for Delivery Charge
class _ModernDeliveryChargeShimmer extends StatefulWidget {
  const _ModernDeliveryChargeShimmer({Key? key}) : super(key: key);

  @override
  State<_ModernDeliveryChargeShimmer> createState() =>
      _ModernDeliveryChargeShimmerState();
}

class _ModernDeliveryChargeShimmerState
    extends State<_ModernDeliveryChargeShimmer>
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

  Widget _buildShimmerLine(double height, BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isDark = colorScheme.isDark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? [
                  Color(0xFF2C2C2C),
                  Color(0xFF3C3C3C),
                  Color(0xFF2C2C2C),
                ]
              : [
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildShimmerLine(20, context)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerLine(20, context)),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(child: _buildShimmerLine(20, context)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerLine(20, context)),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(child: _buildShimmerLine(22, context)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildShimmerLine(22, context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
