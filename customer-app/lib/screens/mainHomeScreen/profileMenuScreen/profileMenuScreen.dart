import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/generalWidgets/appUpdateDialog.dart';
import 'package:project/helper/generalWidgets/bottomSheetChangePasswordContainer.dart';
// import 'package:project/helper/generalWidgets/themeModeSelectorSheet.dart'; // Appearance block hidden
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/appUpdateProvider.dart';
import 'package:project/provider/bookmarkListProvider.dart';
import 'package:project/provider/reportsProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/provider/userOffersProvider.dart';
import 'package:project/screens/bookmarks/bookmarkListScreen.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/policiesScreen.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/reportsScreen/my_reports_screen.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/rewardsScreen/rewards_screen.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/widget/zenfo_money_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ScrollController scrollController;

  const ProfileScreen({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List personalDataMenu = [];
  List settingsMenu = [];
  List otherInformationMenu = [];
  List deleteMenuItem = [];
  bool _isSharing = false; // Add this in your state
  bool _showUpdateBanner = false;

  @override
  void initState() {
    Future.delayed(Duration.zero).then((value) {
      setProfileMenuList();
      _checkForUpdates();
    });
    super.initState();
  }

  /// Check for app updates
  Future<void> _checkForUpdates() async {
    if (!mounted) return;

    try {
      final updateProvider = context.read<AppUpdateProvider>();
      await updateProvider.checkForUpdates(context);

      if (mounted && updateProvider.isUpdateAvailable) {
        // Check if user has dismissed this version
        final dismissedVersion = Constant.session
            .getData(SessionManager.keyUpdateBannerDismissedVersion);
        final currentAvailableVersion =
            updateProvider.updateInfo?.newVersion ?? '';

        if (dismissedVersion != currentAvailableVersion) {
          setState(() {
            _showUpdateBanner = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  /// Dismiss the update banner
  void _dismissUpdateBanner() {
    final updateProvider = context.read<AppUpdateProvider>();
    final version = updateProvider.updateInfo?.newVersion ?? '';

    // Save the dismissed version
    Constant.session.setData(
      SessionManager.keyUpdateBannerDismissedVersion,
      version,
      false,
    );

    setState(() {
      _showUpdateBanner = false;
    });
  }

  /// Show update dialog and perform update
  void _showUpdateDialog() {
    final updateProvider = context.read<AppUpdateProvider>();
    if (updateProvider.updateInfo == null) return;

    showDialog(
      context: context,
      barrierDismissible: !updateProvider.updateInfo!.isForceUpdate,
      builder: (context) => AppUpdateDialog(
        currentVersion: updateProvider.updateInfo!.currentVersion,
        newVersion: updateProvider.updateInfo!.newVersion,
        isForceUpdate: updateProvider.updateInfo!.isForceUpdate,
        onUpdatePressed: () {
          Navigator.pop(context);
          updateProvider.performUpdate();
        },
        onLaterPressed: () {
          Navigator.pop(context);
          _dismissUpdateBanner();
        },
      ),
    );
  }

  void shareApp(BuildContext context) async {
    if (_isSharing) return; // Prevent multiple clicks
    _isSharing = true;

    try {
      String shareAppMessage =
          getTranslatedValue(context, shareAppMessageLabel);

      if (Platform.isAndroid) {
        shareAppMessage = "$shareAppMessage${Constant.playStoreUrl}";
      } else if (Platform.isIOS) {
        shareAppMessage = "$shareAppMessage${Constant.appStoreUrl}";
      }

      await SharePlus.instance.share(
        ShareParams(text: shareAppMessage, subject: "Share app"),
      );
    } catch (e) {
      debugPrint("Error sharing app: $e");
    } finally {
      _isSharing = false; // Re-enable sharing after the dialog is closed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: PreferredSize(
              preferredSize: Size(double.infinity, double.maxFinite),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppHeader(
                    title: getTranslatedValue(context, 'manage_your_profile'),
                    showBackButton: true,
                  ),
                ],
              )),
          backgroundColor: colorScheme.background,
          body: Container(
            decoration: BoxDecoration(
              gradient: colorScheme.screenGradient,
            ),
            child: CustomScrollView(
            controller: widget.scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              // ========= Gradient header with back button =========
              // SliverAppBar(
              //   pinned: true,
              //   floating: true,
              //   elevation: 0,
              //   automaticallyImplyLeading: false,
              //   toolbarHeight: 72,
              //   backgroundColor: Colors.transparent,
              //   flexibleSpace: Container(
              //     decoration: BoxDecoration(
              //       gradient: colorScheme.surfaceGradient,
              //     ),
              //     child: SafeArea(
              //       bottom: false,
              //       child: Padding(
              //         padding: const EdgeInsets.symmetric(
              //             horizontal: 16, vertical: 14),
              //         child: Row(
              //           children: [
              //             // Back button (same visual language as cart)
              //             GestureDetector(
              //               onTap: () {
              //                 HapticFeedback.lightImpact();
              //                 Navigator.pop(context);
              //               },
              //               child: Container(
              //                 width: 40,
              //                 height: 40,
              //                 decoration: BoxDecoration(
              //                   color:
              //                       colorScheme.surface.withValues(alpha: 0.25),
              //                   borderRadius: BorderRadius.circular(12),
              //                   border: Border.all(
              //                     color: colorScheme.border,
              //                     width: 1,
              //                   ),
              //                 ),
              //                 child: Center(
              //                   child: Icon(
              //                     Icons.arrow_back_ios_new_rounded,
              //                     color: colorScheme.iconPrimary,
              //                     size: 18,
              //                   ),
              //                 ),
              //               ),
              //             ),
              //             const SizedBox(width: 12),
              //             Expanded(
              //               child: Column(
              //                 crossAxisAlignment: CrossAxisAlignment.start,
              //                 mainAxisAlignment: MainAxisAlignment.center,
              //                 mainAxisSize: MainAxisSize.min,
              //                 children: [
              //                   Text(
              //                     getTranslatedValue(context, profileLabel),
              //                     style: GoogleFonts.inter(
              //                       color: colorScheme.textPrimary,
              //                       fontSize: 18,
              //                       fontWeight: FontWeight.w700,
              //                       height: 1.2,
              //                       letterSpacing: -0.3,
              //                     ),
              //                   ),
              //                   const SizedBox(height: 2),
              //                   Text(
              //                     getTranslatedValue(
              //                         context, manageYourAccountLabel),
              //                     style: GoogleFonts.inter(
              //                       color: colorScheme.textSecondary,
              //                       fontSize: 12,
              //                       fontWeight: FontWeight.w500,
              //                       height: 1.2,
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              // ========= Profile header card =========
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: const ProfileHeader(),
                ),
              ),

              SliverToBoxAdapter(
                child: Consumer<UserProfileProvider>(
                  builder: (context, userProfileProvider, _) {
                    // Show shimmer if profile is loading
                    if (userProfileProvider.profileState ==
                        ProfileState.loading) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          children: [
                            _buildQuickWidgetShimmer(),
                            const SizedBox(height: 16),
                            _buildCardShimmer(height: 80),
                            const SizedBox(height: 16),
                            _buildCardShimmer(height: 64),
                            const SizedBox(height: 16),
                            _buildCardShimmer(height: 250),
                            const SizedBox(height: 16),
                            _buildCardShimmer(height: 200),
                            const SizedBox(height: 16),
                            _buildCardShimmer(height: 350),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Update banner
                          if (_showUpdateBanner)
                            Consumer<AppUpdateProvider>(
                              builder: (context, updateProvider, _) {
                                return Column(
                                  children: [
                                    UpdateAvailableBanner(
                                      onDismiss: _dismissUpdateBanner,
                                      onUpdate: _showUpdateDialog,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              },
                            ),

                          // Quick actions section
                          // const SizedBox(height: 16),
                          const QuickUseWidget(),
                          const SizedBox(height: 16),

                          const AgeVerificationToggle(),

                          // Appearance (theme selector) - hidden
                          // const SizedBox(height: 16),
                          // GestureDetector(
                          //   onTap: () {
                          //     showThemeSelector(context);
                          //   },
                          //   child: Consumer<app_theme.ThemeProvider>(
                          //     builder: (context, themeProvider, _) {
                          //       return AppearanceSelectorTile(
                          //         themeProvider: themeProvider,
                          //       );
                          //     },
                          //   ),
                          // ),

                          const SizedBox(height: 16),

                          YourInformationCard(
                            onAddressBook: () async {
                              final result = await showAddressesBottomSheet(context);

                              // If an address was selected, fetch estimated time without waiting
                              if (result != null && mounted) {
                                final homeProvider = context.read<HomeScreenProvider>();
                                // Don't await - load in background for smooth UI
                                homeProvider.loadEta(context);
                              }
                              setState(() {});
                            },
                            onNotifications: () {
                              Navigator.pushNamed(
                                  context, notificationListScreen);
                            },
                            onWishlist: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MultiProvider(
                                    providers: [
                                      ChangeNotifierProvider(
                                          create: (context) =>
                                              BookmarkListProvider()),
                                    ],
                                    child: BookmarkListScreen(
                                        // scrollController: ScrollController(),
                                        ),
                                  ),
                                ),
                              );
                            },
                            onReports: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MultiProvider(
                                    providers: [
                                      ChangeNotifierProvider(
                                        create: (context) => ReportsProvider(),
                                      ),
                                    ],
                                    child: MyReportsScreen(),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          ZenfooMoneyCard(
                            onWallet: () {
                              final walletBalance = num.tryParse(
                                      Constant.session.getData(
                                          SessionManager.keyWalletBalance)) ??
                                  0;
                              if (walletBalance == 0) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ZenfooMoneyScreen(),
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(
                                    context, walletHistoryListScreen);
                              }
                            },
                            onReferAndEarn: () {
                              Navigator.pushNamed(context, referAndEarn);
                            },
                            onRewards: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MultiProvider(
                                    providers: [
                                      ChangeNotifierProvider(
                                        create: (context) =>
                                            UserOffersProvider(),
                                      ),
                                    ],
                                    child: const RewardsScreen(),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          OtherInformationSection(),

                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  setProfileMenuList() {
    personalDataMenu = [];
    settingsMenu = [];
    otherInformationMenu = [];
    deleteMenuItem = [];

    personalDataMenu = [
      if (Constant.session.isUserLoggedIn())
        {
          "icon": AppAssets.walletHistoryIcon,
          "label": myWalletLabel,
          "value": Consumer<SessionManager>(
            builder: (context, sessionManager, child) {
              return CustomTextLabel(
                text:
                    "${sessionManager.getData(SessionManager.keyWalletBalance)}"
                        .currency,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  color: ColorsRes.mainTextColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          "clickFunction": (context) {
            Navigator.pushNamed(context, walletHistoryListScreen);
          },
          "isResetLabel": false
        },
      if (Constant.session.isUserLoggedIn())
        {
          "icon": AppAssets.notificationIcon,
          "label": notificationLabel,
          "clickFunction": (context) {
            Navigator.pushNamed(context, notificationListScreen);
          },
          "isResetLabel": false
        },
      if (Constant.session.isUserLoggedIn())
        {
          "icon": AppAssets.transactionIcon,
          "label": transactionHistoryLabel,
          "clickFunction": (context) {
            Navigator.pushNamed(context, transactionListScreen);
          },
          "isResetLabel": false
        },
    ];

    settingsMenu = [
      if (Constant.session.isUserLoggedIn() &&
          (/* Constant.session.getData(SessionManager.keyLoginType) == "phone" */ context
                      .read<AppSettingsProvider>()
                      .settingsData!
                      .phoneAuthPassword ==
                  "1" ||
              Constant.session.getData(SessionManager.keyLoginType) == "email"))
        {
          "icon": AppAssets.passwordIcon,
          "label": changePasswordLabel,
          "clickFunction": (context) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
              backgroundColor: Theme.of(context).cardColor,
              builder: (BuildContext context) {
                return Wrap(
                  children: [
                    BottomSheetChangePasswordContainer(),
                  ],
                );
              },
            );
          },
          "isResetLabel": false
        },
      {
        "icon": AppAssets.themeIcon,
        "label": changeThemeLabel,
        "clickFunction": (context) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            // useSafeArea: true,
            shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
            backgroundColor: Theme.of(context).cardColor,
            builder: (BuildContext context) {
              return Wrap(
                children: [
                  BottomSheetThemeListContainer(),
                ],
              );
            },
          );
        },
        "isResetLabel": true,
      },
      if (context.read<LanguageProvider>().languages.length > 1)
        {
          "icon": AppAssets.translateIcon,
          "label": changeLanguageLabel,
          "clickFunction": (context) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
              backgroundColor: Theme.of(context).cardColor,
              builder: (BuildContext context) {
                return Wrap(
                  children: [
                    BottomSheetLanguageListContainer(),
                  ],
                );
              },
            );
          },
          "isResetLabel": true,
        },
      if (Constant.session.isUserLoggedIn())
        {
          "icon": AppAssets.settingsIcon,
          "label": notificationsSettingsLabel,
          "clickFunction": (context) {
            Navigator.pushNamed(
                context, notificationsAndMailSettingsScreenScreen);
          },
          "isResetLabel": false
        },
    ];

    otherInformationMenu = [
      if (Constant.session.isUserLoggedIn())
        {
          "icon": AppAssets.referFriendIcon,
          "label": referAndEarnLabel,
          "clickFunction": (context) {
            Navigator.pushNamed(context, referAndEarn);
          },
          "isResetLabel": false
        },
      {
        "icon": AppAssets.contactIcon,
        "label": contactUsLabel,
        "clickFunction": (context) {
          Navigator.pushNamed(
            context,
            webViewScreen,
            arguments: getTranslatedValue(
              context,
              contactUsLabel,
            ),
          );
        }
      },
      {
        "icon": AppAssets.aboutIcon,
        "label": aboutUsLabel,
        "clickFunction": (context) {
          Navigator.pushNamed(
            context,
            webViewScreen,
            arguments: getTranslatedValue(
              context,
              aboutUsLabel,
            ),
          );
        },
        "isResetLabel": false
      },
      {
        "icon": AppAssets.rateUsIcon,
        "label": rateUsLabel,
        "clickFunction": (BuildContext context) {
          launchUrl(
              Uri.parse(Platform.isAndroid
                  ? Constant.playStoreUrl
                  : Constant.appStoreUrl),
              mode: LaunchMode.externalApplication);
        },
      },
      {
        "icon": AppAssets.shareIcon,
        "label": shareAppLabel,
        "clickFunction": (BuildContext context) {
          /* String shareAppMessage = getTranslatedValue(
            context,
            shareAppMessageLabel,
          );
          if (Platform.isAndroid) {
            shareAppMessage = "$shareAppMessage${Constant.playStoreUrl}";
          } else if (Platform.isIOS) {
            shareAppMessage = "$shareAppMessage${Constant.appStoreUrl}";
          }
          // Share.share(shareAppMessage, subject: "Share app");
          SharePlus.instance.share(ShareParams(text: shareAppMessage, subject: "Share app")); */
          shareApp(context);
        },
      },
      {
        "icon": AppAssets.faqIcon,
        "label": faqLabel,
        "clickFunction": (context) {
          Navigator.pushNamed(context, faqListScreen);
        }
      },
      {
        "icon": AppAssets.termsIcon,
        "label": termsAndConditionsLabel,
        "clickFunction": (context) {
          Navigator.pushNamed(context, webViewScreen,
              arguments: getTranslatedValue(
                context,
                termsAndConditionsLabel,
              ));
        }
      },
      {
        "icon": AppAssets.privacyIcon,
        "label": policiesLabel,
        "clickFunction": (context) {
          Navigator.pushNamed(context, webViewScreen,
              arguments: getTranslatedValue(
                context,
                policiesLabel,
              ));
        }
      },
      if (Constant.session.isUserLoggedIn())
        {
          "icon": AppAssets.logoutIcon,
          "label": logoutLabel,
          "clickFunction": Constant.session.logoutUser,
          "isResetLabel": false
        },
    ];

    deleteMenuItem = [
      if (Constant.session.isUserLoggedIn())
        {
          "icon": AppAssets.deleteUserAccountIcon,
          "label": deleteUserAccountLabel,
          "clickFunction": Constant.session.deleteUserAccount,
          "isResetLabel": false
        },
    ];
    setState(() {});
  }

  // Shimmer widgets
  Widget _buildCardShimmer({required double height}) {
    return CustomShimmer(
      height: height,
      width: double.infinity,
      borderRadius: 16,
    );
  }

  Widget _buildQuickWidgetShimmer() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
            child: CustomShimmer(
              height: 110,
              width: double.infinity,
              borderRadius: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget menuItemsContainer({
    required String title,
    required List menuItem,
    Color? iconColor,
    Color? fontColor,
  }) {
    if (menuItem.isEmpty) return const SizedBox.shrink();

    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return GradientBorderCard(
          gradient: colorScheme.cardGradient,
          borderGradient: colorScheme.borderGradient,
          shadows: colorScheme.cardShadow,
          borderRadius: 18,
          padding: EdgeInsetsDirectional.only(
            start: 16,
            end: 16,
            top: title.isNotEmpty ? 14 : 8,
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 10),
                  child: Row(
                    children: [
                      GradientAccentBar(
                          gradient: colorScheme.accentBarGradient),
                      const SizedBox(width: 10),
                      Flexible(
                        child: CustomTextLabel(
                          jsonKey: title,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  menuItem.length,
                  (index) => Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            menuItem[index]['clickFunction'](context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                                vertical: 14, horizontal: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GradientIconTile(
                                  gradient: iconColor != null
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            iconColor.withValues(alpha: 0.18),
                                            iconColor.withValues(alpha: 0.06),
                                          ],
                                        )
                                      : colorScheme.iconTileGradient,
                                  child: defaultImg(
                                    image: menuItem[index]['icon'],
                                    iconColor:
                                        iconColor ?? colorScheme.iconSecondary,
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: CustomTextLabel(
                                    jsonKey: menuItem[index]['label'],
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          fontColor ?? colorScheme.textPrimary,
                                      letterSpacing: -0.3,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                                if (menuItem[index]['value'] != null) ...[
                                  menuItem[index]['value'],
                                  const SizedBox(width: 8),
                                ],
                                GradientIconTile(
                                  padding: 6,
                                  borderRadius: 8,
                                  gradient: colorScheme.iconTileGradient,
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color:
                                        fontColor ?? colorScheme.iconSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (index != menuItem.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: colorScheme.divider,
                          indent: 52, // align under text (after icon)
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AgeVerificationToggle extends StatefulWidget {
  const AgeVerificationToggle({super.key});

  @override
  State<AgeVerificationToggle> createState() => _AgeVerificationToggleState();
}

class _AgeVerificationToggleState extends State<AgeVerificationToggle> {
  bool _isEnabled = false;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadAgeVerificationStatus();
  }

  Future<void> _loadAgeVerificationStatus() async {
    try {
      final response = await getChildrenAllowed(context: context);
      if (response['status'] == 1) {
        setState(() {
          _isEnabled = response['is_children_allowed'] == 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading age verification status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAgeVerification(bool value) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await updateChildrenAllowed(
        context: context,
        isChildrenAllowed: value ? 1 : 0,
      );

      if (response['status'] == 1) {
        setState(() {
          _isEnabled = value;
          _isUpdating = false;
        });

        // Show success message
        showMessage(
          context,
          value ? 'Age verification enabled' : 'Age verification disabled',
          MessageType.success,
        );
      } else {
        setState(() {
          _isUpdating = false;
        });

        // Show error message
        showMessage(
          context,
          response['message'] ?? 'Failed to update age verification',
          MessageType.error,
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      debugPrint('Error updating age verification: $e');
      showMessage(
        context,
        'Failed to update age verification',
        MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        if (_isLoading) {
          return GradientBorderCard(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            borderRadius: 18,
            gradient: colorScheme.cardGradient,
            borderGradient: colorScheme.borderGradient,
            shadows: colorScheme.cardShadow,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ),
            ),
          );
        }

        return GradientBorderCard(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          borderRadius: 18,
          gradient: _isEnabled
              ? colorScheme.heroGradient
              : colorScheme.cardGradient,
          borderGradient: _isEnabled
              ? colorScheme.borderGradientStrong
              : colorScheme.borderGradient,
          shadows: colorScheme.cardShadow,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildTextContent(colorScheme),
              ),
              const SizedBox(width: 14),
              _isUpdating
                  ? SizedBox(
                      width: 52.79,
                      height: 31,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(colorScheme.primary),
                          ),
                        ),
                      ),
                    )
                  : _buildToggleSwitch(colorScheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextContent(dynamic colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextLabel(
          jsonKey: 'above_18_plus',
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        CustomTextLabel(
          jsonKey: 'required_for_age_restricted_products',
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch(dynamic colorScheme) {
    return GestureDetector(
      onTap: () => _updateAgeVerification(!_isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52.79,
        padding: const EdgeInsets.symmetric(horizontal: 4.67, vertical: 4.20),
        decoration: ShapeDecoration(
          gradient: _isEnabled
              ? colorScheme.buttonGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceVariant,
                    colorScheme.borderStrong,
                  ],
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(250),
          ),
          shadows: _isEnabled
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 23.12,
            height: 23.59,
            decoration: ShapeDecoration(
              color: colorScheme.cardBackground,
              shape: CircleBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderWithGradientBar extends StatelessWidget {
  final Widget child;

  // Allows stacking your profile card etc as `child` below the gradient
  const HeaderWithGradientBar({required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double
          .infinity, // or MediaQuery.of(context).size.width for responsiveness
      height: 250, // adjust as needed
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9AC444), Color(0xFFF6F6F6)],
        ),
      ),
      child: Stack(
        children: [
          // Back button (customize as needed)
          Positioned(
            left: 24,
            top: 50,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    Icon(Icons.arrow_back, color: Color(0xFF7DB435), size: 28),
              ),
            ),
          ),
          // Profile card (centered horizontally, margin from top)
          Positioned(
            left: 12,
            right: 12,
            top: 110,
            child: child, // pass your Figma style profile card here
          ),
        ],
      ),
    );
  }
}

class SettingsGroupCard extends StatelessWidget {
  final String title;
  final List<SettingsItemData> items;

  const SettingsGroupCard({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return GradientBorderCard(
          margin: const EdgeInsets.only(bottom: 12),
          borderRadius: 18,
          gradient: colorScheme.cardGradient,
          borderGradient: colorScheme.borderGradient,
          shadows: colorScheme.cardShadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GradientAccentBar(gradient: colorScheme.accentBarGradient),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.border,
              ),
              // Rows
              Column(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isLast = index == items.length - 1;
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            item.onTap();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                GradientIconTile(
                                  gradient: colorScheme.iconTileGradient,
                                  child: Icon(
                                    item.icon,
                                    size: 20,
                                    color: colorScheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                if (item.trailingText != null) ...[
                                  Text(
                                    item.trailingText!,
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                GradientIconTile(
                                  padding: 6,
                                  borderRadius: 8,
                                  gradient: colorScheme.iconTileGradient,
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: colorScheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 52, // align with text, not icon
                          color: colorScheme.border,
                        ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsItemData {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;

  SettingsItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
  });
}

class AppearanceSelectorTile extends StatelessWidget {
  final app_theme.ThemeProvider themeProvider;

  const AppearanceSelectorTile({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final themeName = themeProvider.getThemeModeName(themeProvider.themeMode);
    final themeIcon = themeProvider.getThemeModeIcon(themeProvider.themeMode);
    final colorScheme = themeProvider.colorScheme;

    return GradientBorderCard(
      width: double.infinity,
      height: 64,
      borderRadius: 18,
      gradient: colorScheme.cardGradient,
      borderGradient: colorScheme.borderGradient,
      shadows: colorScheme.cardShadow,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: icon + label
          Row(
            children: [
              GradientIconTile(
                gradient: colorScheme.iconTileGradient,
                child: Icon(
                  themeIcon,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                getTranslatedValue(context, 'appearance'),
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Right: current theme mode + chevron
          Row(
            children: [
              GradientBorderCard(
                height: 32,
                borderRadius: 9,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gradient: colorScheme.iconTileGradient,
                borderGradient: colorScheme.borderGradient,
                child: Center(
                  child: Text(
                    themeName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: colorScheme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class YourInformationCard extends StatelessWidget {
  final VoidCallback? onAddressBook;
  final VoidCallback? onNotifications;
  final VoidCallback? onWishlist;
  final VoidCallback? onReports;

  const YourInformationCard({
    super.key,
    this.onAddressBook,
    this.onNotifications,
    this.onWishlist,
    this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return GradientBorderCard(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          gradient: colorScheme.cardGradient,
          borderGradient: colorScheme.borderGradient,
          shadows: colorScheme.cardShadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _SectionHeading(
                label: getTranslatedValue(context, 'your_information'),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),

              _SettingsRow(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedAddressBook,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
                label: getTranslatedValue(context, 'address_book'),
                onTap: onAddressBook,
                colorScheme: colorScheme,
              ),
              _GradientDivider(colorScheme: colorScheme),

              _SettingsRow(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
                label: getTranslatedValue(context, 'notification'),
                onTap: onNotifications,
                colorScheme: colorScheme,
              ),
              _GradientDivider(colorScheme: colorScheme),

              _SettingsRow(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedBookmark01,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
                label: getTranslatedValue(context, 'your_wishlist'),
                onTap: onWishlist,
                colorScheme: colorScheme,
              ),
              _GradientDivider(colorScheme: colorScheme),

              _SettingsRow(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFile02,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
                label: getTranslatedValue(context, 'my_reports'),
                onTap: onReports,
                colorScheme: colorScheme,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Hairline separator that fades out towards both ends instead of running
/// edge to edge as a hard line.
class _GradientDivider extends StatelessWidget {
  final dynamic colorScheme;

  const _GradientDivider({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.border.withValues(alpha: 0.0),
            colorScheme.borderStrong,
            colorScheme.border.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
    );
  }
}

/// Card heading: gradient accent bar + title, shared by every profile card.
class _SectionHeading extends StatelessWidget {
  final String label;
  final dynamic colorScheme;

  const _SectionHeading({
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GradientAccentBar(gradient: colorScheme.accentBarGradient),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final dynamic colorScheme;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              GradientIconTile(
                gradient: colorScheme.iconTileGradient,
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GradientIconTile(
                padding: 6,
                borderRadius: 8,
                gradient: colorScheme.iconTileGradient,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ZenfooMoneyCard extends StatelessWidget {
  final VoidCallback? onWallet;
  final VoidCallback? onReferAndEarn;
  final VoidCallback? onRewards;

  const ZenfooMoneyCard({
    super.key,
    this.onWallet,
    this.onReferAndEarn,
    this.onRewards,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return GradientBorderCard(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          gradient: colorScheme.cardGradient,
          borderGradient: colorScheme.borderGradient,
          shadows: colorScheme.cardShadow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(
                label: getTranslatedValue(context, 'zenfoo_money_and_rewards'),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _MoneyRow(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet01,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
                label: getTranslatedValue(context, 'wallet'),
                onTap: onWallet,
                colorScheme: colorScheme,
              ),
              _GradientDivider(colorScheme: colorScheme),
              _MoneyRow(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoneyBag01,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
                label: getTranslatedValue(context, 'refer_and_earn_label'),
                onTap: onReferAndEarn,
                colorScheme: colorScheme,
              ),
              _GradientDivider(colorScheme: colorScheme),
              _MoneyRow(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedGift,
                  size: 20,
                  color: colorScheme.textSecondary,
                ),
                label: getTranslatedValue(context, 'your_collected_rewards'),
                onTap: onRewards,
                colorScheme: colorScheme,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final dynamic colorScheme;

  const _MoneyRow({
    required this.icon,
    required this.label,
    this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              GradientIconTile(
                gradient: colorScheme.iconTileGradient,
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GradientIconTile(
                padding: 6,
                borderRadius: 8,
                gradient: colorScheme.iconTileGradient,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtherInformationSection extends StatefulWidget {
  const OtherInformationSection({super.key});

  @override
  State<OtherInformationSection> createState() =>
      _OtherInformationSectionState();
}

class _OtherInformationSectionState extends State<OtherInformationSection> {
  String _appName = '';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appName = info.appName;
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Column(
          children: [
            // Card
            GradientBorderCard(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              gradient: colorScheme.cardGradient,
              borderGradient: colorScheme.borderGradient,
              shadows: colorScheme.cardShadow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(
                    label: getTranslatedValue(context, 'other_information'),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLanguageSquare,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'app_language'),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: DesignConfig.setRoundedBorderSpecific(20,
                            istop: true),
                        backgroundColor: Theme.of(context).cardColor,
                        builder: (context) =>
                            BottomSheetLanguageListContainer(),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  _GradientDivider(colorScheme: colorScheme),
                  _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedShare01,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'share_the_app'),
                    onTap: () {
                      String shareAppMessage =
                          getTranslatedValue(context, shareAppMessageLabel);
                      if (Platform.isAndroid) {
                        shareAppMessage =
                            "$shareAppMessage${Constant.playStoreUrl}";
                      } else if (Platform.isIOS) {
                        shareAppMessage =
                            "$shareAppMessage${Constant.appStoreUrl}";
                      }
                      SharePlus.instance.share(ShareParams(
                          text: shareAppMessage, subject: "Share app"));
                    },
                    colorScheme: colorScheme,
                  ),
                  _GradientDivider(colorScheme: colorScheme),
                
                   _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'about_us'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUs(),
                        ),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  _GradientDivider(colorScheme: colorScheme),
                  _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedContact,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'contact_us'),
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactUs(),
                        ),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  _GradientDivider(colorScheme: colorScheme),
                   _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'terms_and_conditions'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsAndConditions(),
                        ),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                  _GradientDivider(colorScheme: colorScheme),
                    _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'privacy_policy'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicy(),

                        ),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                
                  _GradientDivider(colorScheme: colorScheme),
                    _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'refund_policy'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RefundPolicy(),

                        ),
                      );
                    },
                    colorScheme: colorScheme,
                  ),
                
                  _GradientDivider(colorScheme: colorScheme),
                  
                  Consumer<AppUpdateProvider>(
                    builder: (context, updateProvider, _) {
                      return _OtherRow(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          size: 20,
                          color: colorScheme.textSecondary,
                        ),
                        label: getTranslatedValue(context, 'check_for_updates'),
                        onTap: updateProvider.isCheckingForUpdate
                            ? null
                            : () async {
                                await updateProvider.checkForUpdates(context);
                                if (mounted) {
                                  if (updateProvider.isUpdateAvailable &&
                                      updateProvider.updateInfo != null) {
                                    // Show update dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: !updateProvider
                                          .updateInfo!.isForceUpdate,
                                      builder: (context) => AppUpdateDialog(
                                        currentVersion: updateProvider
                                            .updateInfo!.currentVersion,
                                        newVersion: updateProvider
                                            .updateInfo!.newVersion,
                                        isForceUpdate: updateProvider
                                            .updateInfo!.isForceUpdate,
                                        onUpdatePressed: () {
                                          Navigator.pop(context);
                                          updateProvider.performUpdate();
                                        },
                                      ),
                                    );
                                  } else {
                                    // Show no update available message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          getTranslatedValue(
                                              context, 'no_updates_available'),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                        colorScheme: colorScheme,
                        isLoading: updateProvider.isCheckingForUpdate,
                      );
                    },
                  ),
                  _GradientDivider(colorScheme: colorScheme),
                  _OtherRow(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLogout01,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                    label: getTranslatedValue(context, 'log_out'),
                    onTap: () {
                      Constant.session.logoutUser(context);
                    },
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // App name + version footer
            if (_appName.isNotEmpty && _version.isNotEmpty)
              Text(
                '$_appName • v$_version',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                  height: 1.4,
                  letterSpacing: -0.2,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OtherRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final dynamic colorScheme;
  final bool isLoading;

  const _OtherRow({
    required this.icon,
    required this.label,
    this.onTap,
    required this.colorScheme,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            children: [
              GradientIconTile(
                gradient: colorScheme.iconTileGradient,
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(colorScheme.primary),
                        ),
                      )
                    : icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GradientIconTile(
                padding: 6,
                borderRadius: 8,
                gradient: colorScheme.iconTileGradient,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
