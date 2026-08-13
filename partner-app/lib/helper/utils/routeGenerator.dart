import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/cashCollectionListProvider.dart';
import 'package:project/provider/fundTransferListProvider.dart';
import 'package:project/provider/geminiProvider.dart';
import 'package:project/provider/tagsProvider.dart';
import 'package:project/repositories/geminiApi.dart';
import 'package:project/screens/Login/login_screen.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/cashCollectionListScreen.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/fundTransferListScreen.dart';
import 'package:project/screens/mapScreen/mapScreen.dart';
import 'package:project/screens/ordersScreen/chat_with_admin_for_order.dart';
import 'package:project/screens/profileScreen/edit_personal_profile_screen.dart';
import 'package:project/screens/profileScreen/edit_store_profile_screen.dart';
import 'package:project/screens/resgistration/food/food_registration_provider.dart';
import 'package:project/screens/stockManagementScreen/product_stock_management_screen.dart';
import 'package:project/screens/categoryScreen/add_category_screen.dart';
import 'package:project/screens/categoryScreen/category_list_screen.dart' as CategoryManagement;
import 'package:project/provider/category_list_provider.dart' as CategoryManagementProvider;
import 'package:project/models/category_model.dart' as CategoryModels;

const String splashScreen = 'splashScreen';
const String accountTypeScreen = 'accountTypeScreen';
const String loginScreen = 'loginScreen';
const String underMaintenanceScreen = 'underMaintenanceScreen';
const String mainHomeScreen = 'mainHomeScreen';
const String categoryListScreen = 'categoryListScreen';
const String productListScreen = 'productListScreen';
const String productStockManagementScreen = 'productStockManagementScreen';
const String productStockManagementScreenNew = 'productStockManagementScreenNew';
const String productBulkOperationScreen = 'productBulkOperationScreen';
const String productBulkUpdateScreen = 'productBulkUpdateScreen';
const String productAddUpdateScreen = 'productAddUpdateScreen';
const String webViewScreen = 'webViewScreen';
const String editSellerProfileScreen = 'editSellerProfileScreen';
const String editDeliveryBoyProfileScreen = 'editDeliveryBoyProfileScreen';
const String orderDetail = 'orderDetail';
const String notificationsAndMailSettingsScreenScreen =
    'notificationsAndMailSettingsScreenScreen';
// const String confirmLocationScreen = 'confirmLocationScreen';
const String htmlEditorScreen = 'htmlEditorScreen';
const String taxesListScreen = 'taxesListScreen';
const String brandListScreen = 'brandListScreen';
const String countriesListScreen = 'countriesListScreen';
const String productTypeScreen = 'productTypeScreen';
const String statusesListScreen = 'statusesListScreen';
const String measurementUnitListScreen = 'measurementUnitListScreen';
const String productStockStatusScreen = 'productStockStatusScreen';
const String walletHistoryListScreen = 'walletHistoryListScreen';
const String withdrawalRequestsListScreen = 'withdrawalRequestsListScreen';
const String cityListScreen = 'cityListScreen';
const String ratingAndReviewScreen = 'ratingAndReviewScreen';
const String fullScreenProductImageScreen = 'fullScreenProductImageScreen';
const String orderTrackerScreen = 'orderTrackerScreen';
const String tagsListScreen = 'tagsListScreen';
const String cashCollectionScreen = 'cashCollection';
const String fundTransferScreen = 'fundTransfer';
const String mapScreen = 'mapScreen';
const String chatWithAdminScreen = 'chat_with_admin';
const String editPersonalProfileScreen = 'editPersonalProfileScreen';
const String editStoreProfileScreen = 'editStoreProfileScreen';
const String addCategoryScreen = 'addCategoryScreen';
const String categoryManagementScreen = 'categoryManagementScreen';

String currentRoute = splashScreen;

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    currentRoute = settings.name ?? "";

    switch (settings.name) {
      case splashScreen:
        return CupertinoPageRoute(
          builder: (_) => SplashScreen(),
        );

      case accountTypeScreen:
        return CupertinoPageRoute(
          builder: (_) => AccountTypeScreen(),
        );

      case loginScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<UserProfileProvider>(
            create: (context) => UserProfileProvider(),
            child: LoginPage(),
          ),
        );

      case underMaintenanceScreen:
        return CupertinoPageRoute(
          builder: (_) => const UnderMaintenanceScreen(),
        );

      case mainHomeScreen:
        return CupertinoPageRoute(
          builder: (_) => MainHomeScreen(),
        );

      case categoryListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<CategoryListProvider>(
            create: (context) => CategoryListProvider(),
            child: CategoryListScreen(from: settings.arguments as String),
          ),
        );

      case productListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<ProductListProvider>(
            create: (context) => ProductListProvider(),
            child: ProductListScreen(
              currentFilterIndex: settings.arguments as int,
            ),
          ),
        );

      case productStockManagementScreen:
        return CupertinoPageRoute(
          builder: (_) =>
              ChangeNotifierProvider<ProductStockManagementProvider>(
            create: (context) => ProductStockManagementProvider(),
            child: StockManagementScreen(),
          ),
        );

      case productStockManagementScreenNew:
        return CupertinoPageRoute(
          builder: (_) => ProductStockManagementScreen(),
        );

      case productBulkOperationScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<ProductBulkOperationsProvider>(
            create: (context) => ProductBulkOperationsProvider(),
            child: ProductBulkUploadScreen(
              from: settings.arguments as String,
            ),
          ),
        );

      case tagsListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<TagsListProvider>(
            create: (context) => TagsListProvider(),
            child: TagsListScreen(
              selectedTags: settings.arguments as List<TagsData>,
            ),
          ),
        );

      case productAddUpdateScreen:
        List<dynamic> productAddScreenArgs =
            settings.arguments as List<dynamic>;
        return CupertinoPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider<AddUpdateProductProvider>(
                create: (context) => AddUpdateProductProvider(),
              ),
              ChangeNotifierProvider<ProductStockStatusProvider>(
                create: (context) => ProductStockStatusProvider(),
              ),
              ChangeNotifierProvider(
                create: (_) => GeminiDescriptionProvider(
                  repository: GeminiRepository(),
                ),
              ),
            ],
            child: ProductAddScreen(
              productId: productAddScreenArgs[0] as String,
              from: productAddScreenArgs[1] as String,
            ),
          ),
        );

      case addCategoryScreen:
        return CupertinoPageRoute(
          builder: (_) => AddCategoryScreen(
            category: settings.arguments as CategoryModels.CategoryModel?,
          ),
        );

      case webViewScreen:
        return CupertinoPageRoute(
          builder: (_) => WebViewScreen(dataFor: settings.arguments as String),
        );

      case editSellerProfileScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<UserProfileProvider>(
            create: (context) => UserProfileProvider(),
            child: EditSellerProfileScreen(from: settings.arguments as String),
          ),
        );

      case editDeliveryBoyProfileScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<UserProfileProvider>(
            create: (context) => UserProfileProvider(),
            child: EditDeliveryBoyProfileScreen(
                from: settings.arguments as String),
          ),
        );

      case editPersonalProfileScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<FoodRegistrationProvider>(
            create: (context) => FoodRegistrationProvider(context),
            child: EditPersonalProfileScreen(),
          ),
        );

      case editStoreProfileScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<FoodRegistrationProvider>(
            create: (context) => FoodRegistrationProvider(context),
            child: EditStoreProfileScreen(),
          ),
        );

      case orderDetail:
        List<dynamic> orderScreenArgs = settings.arguments as List<dynamic>;
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<OrderDetailProvider>(
            create: (context) => OrderDetailProvider(),
            child: OrderDetailScreen(
                orderId: orderScreenArgs[0] as String,
                from: orderScreenArgs[1] as String,
                isReturn: orderScreenArgs[2] as bool,
                returnOrderId: orderScreenArgs[3] as String),
          ),
        );

      case notificationsAndMailSettingsScreenScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<NotificationsSettingsProvider>(
            create: (context) => NotificationsSettingsProvider(),
            child: NotificationsAndMailSettingsScreenScreen(),
          ),
        );

      /* case confirmLocationScreen:
        List<dynamic> confirmLocationArguments =
            settings.arguments as List<dynamic>;
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<CityByLatLongProvider>(
            create: (context) => CityByLatLongProvider(),
            child: ConfirmLocation(
              address: confirmLocationArguments[0],
              from: confirmLocationArguments[1] as String,
            ),
          ),
        ); */

      case htmlEditorScreen:
        return CupertinoPageRoute(
          builder: (_) => HtmlEditorScreen(
            htmlContent: settings.arguments as String,
          ),
        );

      case brandListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => BrandProvider(),
            child: BrandListScreen(),
          ),
        );

      case taxesListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => TaxProvider(),
            child: TaxesListScreen(),
          ),
        );

      case countriesListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => CountriesProvider(),
            child: CountriesListScreen(),
          ),
        );

      case productTypeScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => ProductTypeProvider(),
            child: ProductTypeScreen(),
          ),
        );

      case statusesListScreen:
        return CupertinoPageRoute(
            builder: (_) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (context) => SellerOrdersProvider(),
                    ),
                    ChangeNotifierProvider(
                      create: (context) => DeliveryBoyOrdersProvider(),
                    ),
                    ChangeNotifierProvider(
                      create: (context) => OrderUpdateStatusProvider(),
                    ),
                  ],
                  child: StatusesListScreen(),
                ));

      case measurementUnitListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => MeasurementUnitsProvider(),
            child: MeasurementUnitListScreen(),
          ),
        );

      case productStockStatusScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => ProductStockStatusProvider(),
            child: ProductStockStatusScreen(),
          ),
        );

      case walletHistoryListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<WalletHistoryProvider>(
            create: (context) => WalletHistoryProvider(),
            child: const WalletHistoryListScreen(),
          ),
        );

      case withdrawalRequestsListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<WithdrawalRequestsProvider>(
            create: (context) => WithdrawalRequestsProvider(),
            child: const WithdrawalRequestsListScreen(),
          ),
        );

      case cityListScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<CityProvider>(
            create: (context) => CityProvider(),
            child: CityListScreen(
              isSingleCity: settings.arguments as bool?,
            ),
          ),
        );

      case ratingAndReviewScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<RatingListProvider>(
            create: (context) => RatingListProvider(),
            child: RatingAndReviewScreen(
              productId: settings.arguments as String,
            ),
          ),
        );

      case fullScreenProductImageScreen:
        List<dynamic> productFullScreenImagesScreen =
            settings.arguments as List<dynamic>;
        return CupertinoPageRoute(
          builder: (_) => ProductFullScreenImagesScreen(
            initialPage: productFullScreenImagesScreen[0] as int,
            images: productFullScreenImagesScreen[1] as List<String>,
          ),
        );

      case orderTrackerScreen:
        List<dynamic> orderTrackerScreenArguments =
            settings.arguments as List<dynamic>;
        return CupertinoPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => LiveOrderTrackingProvider(),
              ),
            ],
            child: OrderTrackerScreen(
              addressLatitude: orderTrackerScreenArguments[0] as double,
              addressLongitude: orderTrackerScreenArguments[1] as double,
              address: orderTrackerScreenArguments[2] as String,
              orderId: orderTrackerScreenArguments[3] as String,
              customerName: orderTrackerScreenArguments[4] as String,
              customerNumber: orderTrackerScreenArguments[5] as String,
            ),
          ),
        );

      case cashCollectionScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<CashCollectionProvider>(
            create: (context) => CashCollectionProvider(),
            child: const CashCollectionListScreen(),
          ),
        );
      case fundTransferScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<FundTransferProvider>(
            create: (context) => FundTransferProvider(),
            child: const FundTransferListScreen(),
          ),
        );

      case mapScreen:
        Map<String, dynamic>? args =
            settings.arguments as Map<String, dynamic>?;
        return CupertinoPageRoute(
          builder: (_) => MapScreen(
            initialLatitude: args?['latitude'],
            initialLongitude: args?['longitude'],
            initialAddress: args?['address'],
          ),
        );

      case categoryManagementScreen:
        return CupertinoPageRoute(
          builder: (_) => ChangeNotifierProvider<CategoryManagementProvider.CategoryListProvider>(
            create: (context) => CategoryManagementProvider.CategoryListProvider(),
            child: const CategoryManagement.CategoryListScreen(),
          ),
        );

      case chatWithAdminScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return CupertinoPageRoute(
          builder: (_) => ChatWithAdminScreen(
            orderId: int.tryParse(args?['orderId']?.toString() ?? '0') ?? 0,
            sellerId: int.tryParse(args?['sellerId']?.toString() ?? '0') ?? 0,
          ),
        );

      default:
        // If there is no such named route in the switch statement, e.g. /third
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return CupertinoPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const CustomTextLabel(text: 'Error'),
          ),
          body: const Center(
            child: CustomTextLabel(text: 'ERROR'),
          ),
        );
      },
    );
  }
}
