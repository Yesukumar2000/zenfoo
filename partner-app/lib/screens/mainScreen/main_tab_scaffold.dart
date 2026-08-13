import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart'
    hide ProductListScreen, ProfileScreen;
import 'package:project/helper/widgets/universal_scaffold.dart';
import 'package:project/provider/sellerOrderReturnRequestProvider.dart';
import 'package:project/provider/themeProvider.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/sellerOrderReturnRequestListScreen.dart';
import 'package:project/screens/mainScreen/bottom_nav_provider.dart';
import 'package:project/screens/mainScreen/custom_bottom_nav.dart';
import 'package:project/screens/newHome/food_dashboard.dart';
import 'package:project/screens/newHome/food_dashboard_provider.dart';
import 'package:project/screens/ordersScreen/orders_screen.dart';

import '../newProductsScreen/product_list.dart';
import '../newProductsScreen/sweet_shop_product_list.dart';
import '../profileScreen/profile_screen.dart';

class MainTabScaffold extends StatefulWidget {
  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<BottomNavProvider>();
    final idx = navProvider.selected;
    final isSweetHouse = Constant.session.getIsSweetHouse();
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return PopScope(
      // This is the root screen, so never let the system pop the route
      // (which would close the app) without our explicit handling.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        // Back from any non-Home tab returns to the Home tab first.
        if (idx != 0) {
          navProvider.select(0);
          return;
        }
        // On the Home tab, require a double back press to exit the app.
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          showMessage(
            context,
            getTranslatedValue(context, pressBackAgainToExitLabel),
            MessageType.success,
          );
        } else {
          SystemNavigator.pop(); // Exit app
        }
      },
      child: UniversalScaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          top: false,
          child: Center(
            child: [
              ChangeNotifierProvider(
                create: (_) => FoodDashboardProvider(),
                child: FoodDashboard(),
              ),
              ChangeNotifierProvider(
                create: (context) => SellerOrderReturnRequestProvider(),
                child: SellerOrderReturnRequestListScreen(),
              ),
              OrdersScreen(),
              // Use SweetShopProductListScreen for sweet house, otherwise ProductListScreen
              isSweetHouse ? SweetShopProductListScreen() : ProductListScreen(),
              ProfileScreen()
            ][idx],
          ),
        ),
        bottomNavigationBar: CustomBottomNav(),
      ),
    );
  }
}
