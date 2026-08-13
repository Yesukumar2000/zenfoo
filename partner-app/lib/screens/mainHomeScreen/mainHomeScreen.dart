import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/awsomeNotification.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/deliveryBoyOrderReturnRequestProvider.dart';
import 'package:project/provider/sellerOrderReturnRequestProvider.dart';
import 'package:project/provider/pickupOrdersProvider.dart';
import 'package:project/provider/new_orders_provider.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/deliveryBoyOrderReturnRequestListScreen.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/sellerOrderReturnRequestListScreen.dart';

class MainHomeScreen extends StatefulWidget {
  final int initialTabIndex;
  MainHomeScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<MainHomeScreen> {
  NetworkStatus networkStatus = NetworkStatus.Online;
  late int currentPage;
  List lblHomeBottomMenu = [];

  //total pageListing
  List<Widget> pages = [];

  DateTime? lastBackPressed;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    currentPage = widget.initialTabIndex;
    checkConnectionState();
    LocalAwesomeNotification().init(context);

    // Start Firebase listener for real-time order notifications
    _startFirebaseOrderListener();

    if (Constant.session.isSeller()) {
      pages = [
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => DashboardProvider(),
            ),
            ChangeNotifierProvider(
              create: (context) => SettingsProvider(),
            ),
          ],
          child: HomeScreen(
            changeTab: (index) {
              selectBottomMenu(index);
            },
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SellerOrderReturnRequestProvider(),
          child: SellerOrderReturnRequestListScreen(),
        ),
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => SellerOrdersProvider(),
            ),
            ChangeNotifierProvider(
              create: (context) => SellerPickupOrdersProvider(),
            ),
          ],
          child: OrderListScreen(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProductListProvider(),
          child: ProductListScreen(
            currentFilterIndex: 0,
          ),
        ),
        ProfileScreen()
      ];
    } else {
      pages = [
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => DeliveryBoyOrdersProvider(),
            ),
            ChangeNotifierProvider(
              create: (context) => DashboardProvider(),
            ),
            ChangeNotifierProvider(
              create: (context) => SettingsProvider(),
            ),
          ],
          child: HomeScreen(
            changeTab: (index) {
              selectBottomMenu(index);
            },
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DeliveryBoyOrderReturnRequestProvider(),
          child: DeliveryBoyOrderReturnRequestListScreen(),
        ),
        ProfileScreen()
      ];
    }

    Future.delayed(Duration.zero).then((value) async {
      if (Constant.session.isUserLoggedIn()) {
        await getNotificationSettingsRepository(params: {}).then(
          (value) async {
            if (value[ApiAndParams.status].toString() == "1") {
              late AppNotificationSettings notificationSettings =
                  AppNotificationSettings.fromJson(value);
              // if (notificationSettings.data!.isEmpty) {
              final isSeller = Constant.session.isSeller();
              final dataLength = notificationSettings.data?.length ?? 0;
              final maxLength = isSeller ? 11 : 8;

              if (dataLength >= 1 && dataLength <= maxLength) {
                await updateNotificationSettingsRepository(
                  params: {
                    ApiAndParams.statusIds: (Constant.session.isSeller())
                        ? "1,2,3,4,5,6,7,8,9,10,11"
                        : "1,2,3,4,5,6,7,8",
                    ApiAndParams.mobileStatuses: (Constant.session.isSeller())
                        ? "1,1,1,1,1,1,1,1,1,1,1"
                        : "1,1,1,1,1,1,1,1",
                    ApiAndParams.mailStatuses: (Constant.session.isSeller())
                        ? "1,1,1,1,1,1,1,1,1,1,1"
                        : "1,1,1,1,1,1,1,1"
                  },
                );
              }
            }
          },
        );
      }
    });

    super.initState();
  }

  //internet connection checking
  checkConnectionState() async {
    networkStatus =
        await checkInternet() ? NetworkStatus.Online : NetworkStatus.Offline;
    Connectivity().onConnectivityChanged.listen((status) {
      if (mounted) {
        setState(() {
          networkStatus = getNetworkStatus(status[0]);
        });
      }
    });
  }

  // Retry all APIs when internet connection is restored
  Future<void> retryAllAPIs() async {
    if (Constant.session.isUserLoggedIn()) {
      try {
        // Retry notification settings API
        await getNotificationSettingsRepository(params: {}).then(
          (value) async {
            if (value[ApiAndParams.status].toString() == "1") {
              late AppNotificationSettings notificationSettings =
                  AppNotificationSettings.fromJson(value);
              final isSeller = Constant.session.isSeller();
              final dataLength = notificationSettings.data?.length ?? 0;
              final maxLength = isSeller ? 11 : 8;

              if (dataLength >= 1 && dataLength <= maxLength) {
                await updateNotificationSettingsRepository(
                  params: {
                    ApiAndParams.statusIds: (Constant.session.isSeller())
                        ? "1,2,3,4,5,6,7,8,9,10,11"
                        : "1,2,3,4,5,6,7,8",
                    ApiAndParams.mobileStatuses: (Constant.session.isSeller())
                        ? "1,1,1,1,1,1,1,1,1,1,1"
                        : "1,1,1,1,1,1,1,1",
                    ApiAndParams.mailStatuses: (Constant.session.isSeller())
                        ? "1,1,1,1,1,1,1,1,1,1,1"
                        : "1,1,1,1,1,1,1,1"
                  },
                );
              }
            }
          },
        );

        // Trigger refresh of all pages/providers
        if (mounted) {
          setState(() {
            // This will trigger rebuild of all pages
          });
        }

        // Show success message
        if (mounted) {
          showMessage(
              context,
              getTranslatedValue(context, connectionRestoredSuccessfullyLabel),
              MessageType.success);
        }
      } catch (e) {
        // Show error message if retry fails
        if (mounted) {
          showMessage(
              context,
              getTranslatedValue(context, failedToRestoreConnectionLabel),
              MessageType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox();
    if (Constant.session.isSeller()) {
      lblHomeBottomMenu = [
        getTranslatedValue(
          context,
          homeBottomMenuHomeLabel,
        ),
        getTranslatedValue(
          context,
          homeBottomMenuReturnLabel,
        ),
        getTranslatedValue(
          context,
          homeBottomMenuOrdersLabel,
        ),
        getTranslatedValue(
          context,
          homeBottomMenuProductsLabel,
        ),
        getTranslatedValue(
          context,
          homeBottomMenuProfileLabel,
        ),
      ];
    } else {
      lblHomeBottomMenu = [
        getTranslatedValue(
          context,
          homeBottomMenuHomeLabel,
        ),
        getTranslatedValue(
          context,
          homeBottomMenuReturnLabel,
        ),
        getTranslatedValue(
          context,
          homeBottomMenuProfileLabel,
        ),
      ];
    }
    return Scaffold(
      bottomNavigationBar: homeBottomNavigation(
        context: context,
        selectBottomMenu: selectBottomMenu,
        totalPage: pages.length,
        selectedIndex: currentPage,
        lblHomeBottomMenu: lblHomeBottomMenu,
      ),
      body: networkStatus == NetworkStatus.Online
          ? PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  return;
                } else {
                  if (currentPage != 0) {
                    if (mounted) {
                      setState(() {
                        currentPage = 0;
                      });
                    }
                  } else {
                    final now = DateTime.now();
                    if (lastBackPressed == null ||
                        now.difference(lastBackPressed!) >
                            const Duration(seconds: 2)) {
                      lastBackPressed = now;
                      showMessage(
                          context,
                          getTranslatedValue(
                              context, pressBackAgainToExitLabel),
                          MessageType.success);
                    } else {
                      SystemNavigator.pop(); // Exit app
                    } //return;
                  }
                }
              },
              child: IndexedStack(
                index: currentPage,
                children: pages,
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // No Internet Image
                  defaultImg(image: AppAssets.noInternetIcon),
                  getSizedBox(
                    height: 30,
                  ),
                  // No Internet Title
                  CustomTextLabel(
                    jsonKey: noInternetMessageTitleLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorsRes.mainTextColor,
                    ),
                  ),
                  getSizedBox(height: 30),
                  // Retry Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: gradientBtnWidget(
                      context,
                      10,
                      title: getTranslatedValue(context, tryAgainLabel),
                      callback: () async {
                        // Check internet connection first
                        bool isConnected = await checkInternet();
                        if (isConnected) {
                          setState(() {
                            networkStatus = NetworkStatus.Online;
                          });
                          // Retry all APIs
                          await retryAllAPIs();
                        } else {
                          showMessage(
                              context,
                              getTranslatedValue(
                                  context, noInternetMessageTitleLabel),
                              MessageType.warning);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  //change current screen based on bottom menu selection
  selectBottomMenu(int index) {
    if (mounted) {
      currentPage = index;
      setState(() {});
    }
  }

  /// Start Firebase listener for real-time order notifications
  void _startFirebaseOrderListener() {
    try {
      // Use keyUserId because setUserData() converts "id" to "user_id" when storing
      final sellerIdStr = Constant.session.getData(SessionManager.keyUserId);
      final sellerId = int.tryParse(sellerIdStr) ?? 0;

      if (sellerId != 0) {
        final provider = Provider.of<NewOrdersProvider>(context, listen: false);
        provider.startFirebaseListener(sellerId: sellerId);
        debugPrint(
            '✅ Firebase order listener started from MainHomeScreen for seller $sellerId');
      } else {
        debugPrint('⚠️ Seller ID not found in session: "$sellerIdStr"');
      }
    } catch (e) {
      debugPrint('Error starting Firebase order listener: $e');
    }
  }
}
