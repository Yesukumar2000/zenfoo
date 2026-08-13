import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/widget/suggestions_widget.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/widget/zenfo_money_screen.dart';
import 'package:project/screens/customerSupportScreen/helpSupportScreen.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class QuickUseWidget extends StatelessWidget {
  const QuickUseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Constant.session.isUserLoggedIn()) return SizedBox.shrink();

    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _QuickActionFigmaBox(
                image: 'assets/images/orders.png',
                jsonKey: ordersHistoryLabel,
                onTap: () => Navigator.pushNamed(context, orderHistoryScreen),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),
              _QuickActionFigmaBox(
                image: 'assets/images/zenfo_wallet.png',
                jsonKey: zenfooMoneyLabel,
                onTap: () {
                  final walletBalance = num.tryParse(Constant.session
                          .getData(SessionManager.keyWalletBalance)) ??
                      0;
                  if (walletBalance == 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ZenfooMoneyScreen(),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, walletHistoryListScreen);
                  }
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),
              _QuickActionFigmaBox(
                image: 'assets/images/faq.png',
                jsonKey: feedbackLabel,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SuggestionsScreen()));
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),
              _QuickActionFigmaBox(
                image: 'assets/images/help.png',
                jsonKey: helpLabel,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen(),
                    ),
                  );
                },
                colorScheme: colorScheme,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionFigmaBox extends StatelessWidget {
  final String image;
  final String jsonKey;
  final VoidCallback onTap;
  final dynamic colorScheme;

  const _QuickActionFigmaBox({
    required this.image,
    required this.jsonKey,
    required this.onTap,
    required this.colorScheme,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GradientBorderCard(
        height: 110,
        borderRadius: 16,
        gradient: colorScheme.cardGradient,
        borderGradient: colorScheme.borderGradient,
        shadows: colorScheme.cardShadow,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // image asset
            Image.asset(
              image,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            // Fixed height container for text to ensure symmetry
            SizedBox(
              height: 32, // Fixed height for 2 lines of text
              child: Center(
                child: Text(
                  getTranslatedValue(context, jsonKey),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:project/helper/utils/generalImports.dart';

// class QuickUseWidget extends StatelessWidget {
//   const QuickUseWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Constant.session.isUserLoggedIn()
//         ? Padding(
//             padding: const EdgeInsetsDirectional.all(10),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: QuickActionButtonWidget(
//                     icon: defaultImg(
//                       image: AppAssets.ordersIcon,
//                       iconColor: ColorsRes.mainTextColor,
//                       height: 23,
//                       width: 23,
//                     ),
//                     label: allOrdersLabel,
//                     onClickAction: () {
//                       Navigator.pushNamed(
//                         context,
//                         orderHistoryScreen,
//                       );
//                     },
//                     padding: const EdgeInsetsDirectional.only(
//                       end: 5,
//                     ),
//                     context: context,
//                   ),
//                 ),
//                 Expanded(
//                   child: QuickActionButtonWidget(
//                     icon: defaultImg(
//                       image: AppAssets.homeMapIcon,
//                       iconColor: ColorsRes.mainTextColor,
//                       height: 23,
//                       width: 23,
//                     ),
//                     label: addressLabel,
//                     onClickAction: () => Navigator.pushNamed(
//                       context,
//                       addressListScreen,
//                       arguments: "quick_widget",
//                     ),
//                     padding: const EdgeInsetsDirectional.only(
//                       start: 5,
//                       end: 5,
//                     ),
//                     context: context,
//                   ),
//                 ),
//                 Expanded(
//                   child: QuickActionButtonWidget(
//                     icon: defaultImg(
//                       image: AppAssets.cartIcon,
//                       iconColor: ColorsRes.mainTextColor,
//                       height: 23,
//                       width: 23,
//                     ),
//                     label: cartLabel,
//                     onClickAction: () {
//                       if (Constant.session.isUserLoggedIn()) {
//                         Navigator.pushNamed(context, cartScreen);
//                       } else {
//                         // loginUserAccount(context, "cart");
//                         Navigator.pushNamed(context, cartScreen);
//                       }
//                     },
//                     padding: const EdgeInsetsDirectional.only(
//                       start: 5,
//                     ),
//                     context: context,
//                   ),
//                 ),
//               ],
//             ),
//           )
//         : Container();
//   }
// }
