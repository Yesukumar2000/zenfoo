import 'package:project/helper/styles/product_card_metrics.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/notesProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/categoryProducts/widgets/product_card.dart';
import 'package:project/screens/notes/notesListScreen.dart';

class ProductSearchScreen extends StatefulWidget {
  final String? initialSearchText;
  // When set, the search is scoped to this seller's products only
  // (e.g. searching from within a super-mart store).
  final int? sellerId;

  const ProductSearchScreen({
    Key? key,
    this.initialSearchText,
    this.sellerId,
  }) : super(key: key);

  @override
  State<ProductSearchScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductSearchScreen> {
  // search provider controller
  final TextEditingController edtSearch = TextEditingController();

  //give delay to live search
  Timer? delayTimer;

  ScrollController scrollController = ScrollController();

  scrollListener() async {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      if (context.read<ProductSearchProvider>().hasMoreData) {
        Map<String, String> params = await Constant.getProductsDefaultParams();

        params[ApiAndParams.search] = edtSearch.text.trim();
        if (widget.sellerId != null) {
          params[ApiAndParams.sellerId] = widget.sellerId.toString();
        }

        await context
            .read<ProductSearchProvider>()
            .getProductSearchProvider(context: context, params: params);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.primaryFocus?.unfocus();

    // Set initial search text if provided
    if (widget.initialSearchText != null &&
        widget.initialSearchText!.isNotEmpty) {
      edtSearch.text = widget.initialSearchText!;
      // Trigger search after a brief delay to ensure provider is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        callApi(isReset: true);
      });
    }

    edtSearch.addListener(searchTextListener);
    scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void searchTextListener() {
    if (edtSearch.text.trim().isEmpty) {
      delayTimer?.cancel();
      // Forget the last query, so retyping the same thing searches again.
      context.read<ProductSearchProvider>().clearSearchedText();
      return;
    }

    if (delayTimer?.isActive ?? false) delayTimer?.cancel();

    delayTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final query = edtSearch.text.trim();
      if (query.isEmpty) return;

      // Compare the query itself, not its length. Length matched for any two
      // searches with the same character count — "ghee" after "milk" — and the
      // API was never called, which read as the search bar dying after the
      // first use.
      if (query != context.read<ProductSearchProvider>().searchedText) {
        context.read<ProductSearchProvider>().setSearchLength(edtSearch.text);
        callApi(isReset: true);
      }
    });
  }

  callApi({required bool isReset}) async {
    if (isReset) {
      context.read<ProductSearchProvider>().offset = 0;

      context.read<ProductSearchProvider>().products = [];
    }

    Map<String, String> params = await Constant.getProductsDefaultParams();

    params[ApiAndParams.sort] = ApiAndParams.productListSortTypes[
        context.read<ProductSearchProvider>().currentSortByOrderIndex];
    params[ApiAndParams.search] = edtSearch.text.trim().toString();
    // Scope the search to a single store when opened from a super mart.
    if (widget.sellerId != null) {
      params[ApiAndParams.sellerId] = widget.sellerId.toString();
    }

    await context
        .read<ProductSearchProvider>()
        .getProductSearchProvider(context: context, params: params);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    List lblSortingDisplayList = [
      sortingDefaultLabel,
      sortingNewestFirstLabel,
      sortingOldestFirstLabel,
      sortingPriceHighToLowLabel,
      sortingPriceLowToHighLabel,
      sortingDiscountHighToLowLabel,
      sortingPopularityLabel,
    ];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'product_search_label'),
          title: getTranslatedValue(context, 'search_products_title'),
          showBackButton: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notes button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                            create: (context) => NotesProvider(),
                          ),
                        ],
                        child: const NotesListScreen(),
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsetsDirectional.only(end: 8),
                  padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        getTranslatedValue(context, 'notes_button_text'),
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              // AppHeader(
              //   label: 'Discover',
              //   title: getTranslatedValue(context, searchLabel),
              //   showBackButton: true,
              //   trailing: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       // Notes button
              //       GestureDetector(
              //         onTap: () {
              //           HapticFeedback.lightImpact();
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //               builder: (context) => MultiProvider(
              //                 providers: [
              //                   ChangeNotifierProvider(
              //                     create: (context) => NotesProvider(),
              //                   ),
              //                 ],
              //                 child: const NotesListScreen(),
              //               ),
              //             ),
              //           );
              //         },
              //         child: Container(
              //           margin: EdgeInsetsDirectional.only(end: 8),
              //           padding: EdgeInsetsDirectional.symmetric(
              //               horizontal: 10, vertical: 8),
              //           decoration: BoxDecoration(
              //             color: colorScheme.buttonPrimaryText
              //                 .withValues(alpha: 0.25),
              //             borderRadius: BorderRadius.circular(10),
              //             border: Border.all(
              //               color: colorScheme.buttonPrimaryText
              //                   .withValues(alpha: 0.3),
              //               width: 1,
              //             ),
              //           ),
              //           child: Row(
              //             mainAxisSize: MainAxisSize.min,
              //             children: [
              //               Icon(
              //                 Icons.edit_note_rounded,
              //                 color: colorScheme.buttonPrimaryText,
              //                 size: 16,
              //               ),
              //               SizedBox(width: 4),
              //               Text(
              //                 'Notes',
              //                 style: GoogleFonts.inter(
              //                   color: colorScheme.buttonPrimaryText,
              //                   fontSize: 13,
              //                   fontWeight: FontWeight.w600,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),

              //       // Sort button
              //       if (context.watch<ProductSearchProvider>().products.length >
              //           0)
              //         GestureDetector(
              //           onTap: () {
              //             showModalBottomSheet<void>(
              //               context: context,
              //               isScrollControlled: true,
              //               backgroundColor: Colors.transparent,
              //               builder: (BuildContext context1) {
              //                 return Container(
              //                   decoration: BoxDecoration(
              //                     color: colorScheme.surface,
              //                     borderRadius: BorderRadius.only(
              //                       topLeft: Radius.circular(24),
              //                       topRight: Radius.circular(24),
              //                     ),
              //                   ),
              //                   child: SafeArea(
              //                     child: Column(
              //                       mainAxisSize: MainAxisSize.min,
              //                       children: [
              //                         // Drag Handle
              //                         Container(
              //                           margin:
              //                               EdgeInsets.only(top: 12, bottom: 8),
              //                           width: 40,
              //                           height: 4,
              //                           decoration: BoxDecoration(
              //                             color: colorScheme.border,
              //                             borderRadius:
              //                                 BorderRadius.circular(2),
              //                           ),
              //                         ),

              //                         // Header
              //                         Padding(
              //                           padding:
              //                               EdgeInsets.fromLTRB(20, 8, 20, 16),
              //                           child: Row(
              //                             children: [
              //                               Container(
              //                                 padding: EdgeInsets.all(10),
              //                                 decoration: BoxDecoration(
              //                                   color:
              //                                       colorScheme.surfaceVariant,
              //                                   borderRadius:
              //                                       BorderRadius.circular(12),
              //                                 ),
              //                                 child: Icon(
              //                                   Icons.sort_rounded,
              //                                   color: colorScheme.primary,
              //                                   size: 24,
              //                                 ),
              //                               ),
              //                               SizedBox(width: 12),
              //                               Expanded(
              //                                 child: Column(
              //                                   crossAxisAlignment:
              //                                       CrossAxisAlignment.start,
              //                                   children: [
              //                                     Text(
              //                                       getTranslatedValue(
              //                                           context, sortByLabel),
              //                                       style: GoogleFonts.inter(
              //                                         fontSize: 18,
              //                                         fontWeight:
              //                                             FontWeight.w700,
              //                                         color: colorScheme
              //                                             .textPrimary,
              //                                         height: 1.2,
              //                                         letterSpacing: -0.4,
              //                                       ),
              //                                     ),
              //                                     SizedBox(height: 2),
              //                                     Text(
              //                                       'Choose how to sort products',
              //                                       style: GoogleFonts.inter(
              //                                         fontSize: 13,
              //                                         fontWeight:
              //                                             FontWeight.w500,
              //                                         color: colorScheme
              //                                             .textSecondary,
              //                                         height: 1.2,
              //                                         letterSpacing: -0.2,
              //                                       ),
              //                                     ),
              //                                   ],
              //                                 ),
              //                               ),
              //                               IconButton(
              //                                 onPressed: () =>
              //                                     Navigator.pop(context),
              //                                 icon: Icon(
              //                                   Icons.close_rounded,
              //                                   color:
              //                                       colorScheme.iconSecondary,
              //                                 ),
              //                               ),
              //                             ],
              //                           ),
              //                         ),

              //                         // Sort Options
              //                         Padding(
              //                           padding:
              //                               EdgeInsets.fromLTRB(20, 0, 20, 20),
              //                           child: Column(
              //                             children: List.generate(
              //                               ApiAndParams
              //                                   .productListSortTypes.length,
              //                               (index) {
              //                                 final isSelected = context
              //                                         .read<
              //                                             ProductSearchProvider>()
              //                                         .currentSortByOrderIndex ==
              //                                     index;
              //                                 return GestureDetector(
              //                                   onTap: () async {
              //                                     Navigator.pop(context);
              //                                     context
              //                                         .read<
              //                                             ProductSearchProvider>()
              //                                         .products = [];
              //                                     context
              //                                         .read<
              //                                             ProductSearchProvider>()
              //                                         .offset = 0;
              //                                     context
              //                                         .read<
              //                                             ProductSearchProvider>()
              //                                         .currentSortByOrderIndex = index;
              //                                     callApi(isReset: true);
              //                                   },
              //                                   child: Container(
              //                                     margin: EdgeInsets.only(
              //                                         bottom: 8),
              //                                     padding: EdgeInsets.all(16),
              //                                     decoration: BoxDecoration(
              //                                       color: isSelected
              //                                           ? colorScheme.primary
              //                                               .withValues(
              //                                                   alpha: 0.1)
              //                                           : colorScheme
              //                                               .cardBackground,
              //                                       borderRadius:
              //                                           BorderRadius.circular(
              //                                               12),
              //                                       border: Border.all(
              //                                         color: isSelected
              //                                             ? colorScheme.primary
              //                                             : colorScheme.border,
              //                                         width: 1.5,
              //                                       ),
              //                                     ),
              //                                     child: Row(
              //                                       children: [
              //                                         Icon(
              //                                           isSelected
              //                                               ? Icons
              //                                                   .radio_button_checked
              //                                               : Icons
              //                                                   .radio_button_off,
              //                                           color: isSelected
              //                                               ? colorScheme
              //                                                   .primary
              //                                               : colorScheme
              //                                                   .iconSecondary,
              //                                           size: 22,
              //                                         ),
              //                                         SizedBox(width: 12),
              //                                         Expanded(
              //                                           child: Text(
              //                                             getTranslatedValue(
              //                                                 context,
              //                                                 lblSortingDisplayList[
              //                                                     index]),
              //                                             style:
              //                                                 GoogleFonts.inter(
              //                                               fontSize: 15,
              //                                               fontWeight:
              //                                                   isSelected
              //                                                       ? FontWeight
              //                                                           .w600
              //                                                       : FontWeight
              //                                                           .w500,
              //                                               color: isSelected
              //                                                   ? colorScheme
              //                                                       .primary
              //                                                   : colorScheme
              //                                                       .textPrimary,
              //                                               height: 1.2,
              //                                               letterSpacing: -0.2,
              //                                             ),
              //                                           ),
              //                                         ),
              //                                       ],
              //                                     ),
              //                                   ),
              //                                 );
              //                               },
              //                             ),
              //                           ),
              //                         ),
              //                       ],
              //                     ),
              //                   ),
              //                 );
              //               },
              //             );
              //           },
              //           child: Container(
              //             padding: EdgeInsetsDirectional.symmetric(
              //                 horizontal: 10, vertical: 8),
              //             decoration: BoxDecoration(
              //               color: colorScheme.buttonPrimaryText
              //                   .withValues(alpha: 0.25),
              //               borderRadius: BorderRadius.circular(10),
              //               border: Border.all(
              //                 color: colorScheme.buttonPrimaryText
              //                     .withValues(alpha: 0.3),
              //                 width: 1,
              //               ),
              //             ),
              //             child: Row(
              //               mainAxisSize: MainAxisSize.min,
              //               children: [
              //                 Icon(
              //                   Icons.sort_rounded,
              //                   color: colorScheme.buttonPrimaryText,
              //                   size: 16,
              //                 ),
              //                 SizedBox(width: 4),
              //                 Text(
              //                   getTranslatedValue(context, sortByLabel),
              //                   style: GoogleFonts.inter(
              //                     color: colorScheme.buttonPrimaryText,
              //                     fontSize: 13,
              //                     fontWeight: FontWeight.w600,
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ),
              //     ],
              //   ),
              // ),

              searchWidget(),
              getSizedBox(
                height: Constant.size5,
              ),
              Expanded(
                child: setRefreshIndicator(
                  refreshCallback: () async {
                    context
                        .read<CartListProvider>()
                        .getAllCartItems(context: context);
                    if (context
                            .read<ProductSearchProvider>()
                            .searchedTextLength >
                        0) {
                      context.read<ProductSearchProvider>().offset = 0;
                      context.read<ProductSearchProvider>().products = [];
                    }

                    callApi(isReset: true);
                  },
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    controller: scrollController,
                    child: Consumer<ProductSearchProvider>(
                      builder: (context, productSearchProvider, _) {
                        List<ProductListItem> products =
                            productSearchProvider.products;

                        if (productSearchProvider.productSearchState ==
                            ProductSearchState.loading) {
                          return getProductListShimmer(
                              context: context, isGrid: true);
                        } else if (productSearchProvider.productSearchState ==
                                ProductSearchState.loaded ||
                            productSearchProvider.productSearchState ==
                                ProductSearchState.loadingMore) {
                          return SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 12,
                                right: 12,
                                top: 8,
                                bottom: 80, // Space for cart overlay
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: productGridGutter,
                                  crossAxisSpacing: productGridGutter,
                                  mainAxisExtent: productCardExtent,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  return MiniProductCardContainer(
                                    product: products[index],
                                    disableHero: false,
                                  );
                                },
                              ),
                            ),
                          );
                        } else if (productSearchProvider.productSearchState ==
                                ProductSearchState.initial ||
                            context
                                    .read<ProductSearchProvider>()
                                    .searchedTextLength ==
                                0) {
                          return DefaultBlankItemMessageScreen(
                            title: "",
                            description: enterTextToSearchTheProductsLabel,
                            image: "no_search_found_icon",
                          );
                        } else if (productSearchProvider.productSearchState ==
                            ProductSearchState.empty) {
                          return DefaultBlankItemMessageScreen(
                            title: emptyProductListMessageLabel,
                            description: emptyProductListDescriptionLabel,
                            image: "no_product_icon",
                          );
                        } else {
                          return NoInternetConnectionScreen(
                              height: context.height * 0.65,
                              message: productSearchProvider.message,
                              callback: () {
                                callApi(isReset: false);
                              });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (context.watch<CartProvider>().totalItemsCount > 0)
            PositionedDirectional(
              bottom: 0,
              start: 0,
              end: 0,
              child: SafeArea(top: false, child: CartOverlay()),
            ),
        ],
      ),
    );
  }

  //Start search widget
  searchWidget() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      color: colorScheme.background,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.inputBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search Icon
            Padding(
              padding: EdgeInsetsDirectional.only(start: 16, end: 12),
              child: Icon(
                Icons.search_rounded,
                color: colorScheme.iconSecondary,
                size: 22,
              ),
            ),

            // Text Field
            Expanded(
              child: TextField(
                autofocus: true,
                controller: edtSearch,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: getTranslatedValue(context, productSearchHintLabel),
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.inputPlaceholder,
                    height: 1.4,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // Voice Search Icon
            GestureDetector(
              onTap: () async {
                if (Platform.isIOS) {
                  // Request microphone permission directly
                  final result = await Permission.microphone.request();
                  if (result.isGranted) {
                    bottomSheetVoiceRecognition();
                  } else if (result.isPermanentlyDenied) {
                    if (!Constant.session.getBoolData(SessionManager
                        .keyPermissionMicrophoneHidePromptPermanently)) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Wrap(
                            children: [
                              PermissionHandlerBottomSheet(
                                titleJsonKey: microphonePermissionTitleLabel,
                                messageJsonKey:
                                    microphonePermissionMessageLabel,
                                sessionKeyForAskNeverShowAgain: SessionManager
                                    .keyPermissionMicrophoneHidePromptPermanently,
                              ),
                            ],
                          );
                        },
                      ).then((value) {
                        if (value == true) {
                          openAppSettings();
                        }
                      });
                    }
                  } else if (result.isDenied) {
                    // If denied, show a message to enable in settings
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Wrap(
                          children: [
                            PermissionHandlerBottomSheet(
                              titleJsonKey: microphonePermissionTitleLabel,
                              messageJsonKey: microphonePermissionMessageLabel,
                              sessionKeyForAskNeverShowAgain: SessionManager
                                  .keyPermissionMicrophoneHidePromptPermanently,
                            ),
                          ],
                        );
                      },
                    ).then((value) {
                      if (value == true) {
                        openAppSettings();
                      }
                    });
                  }
                } else {
                  await hasMicrophonePermissionGiven().then((value) async {
                    if (value is PermissionStatus) {
                      if (value.isGranted) {
                        bottomSheetVoiceRecognition();
                      } else if (value.isDenied) {
                        await Permission.microphone.request();
                      } else if (value.isPermanentlyDenied) {
                        if (!Constant.session.getBoolData(SessionManager
                            .keyPermissionMicrophoneHidePromptPermanently)) {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Wrap(
                                children: [
                                  PermissionHandlerBottomSheet(
                                    titleJsonKey:
                                        microphonePermissionTitleLabel,
                                    messageJsonKey:
                                        microphonePermissionMessageLabel,
                                    sessionKeyForAskNeverShowAgain: SessionManager
                                        .keyPermissionMicrophoneHidePromptPermanently,
                                  ),
                                ],
                              );
                            },
                          ).then((value) {
                            if (value == true) {
                              openAppSettings();
                            }
                          });
                        }
                      }
                    }
                  });
                }
              },
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 12, end: 16),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: defaultImg(
                    image: AppAssets.voiceSearchIcon,
                    iconColor: colorScheme.primary,
                    height: 20,
                    width: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bottomSheetVoiceRecognition() {
    showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        shape: DesignConfig.setRoundedBorderSpecific(20, istop: true),
        builder: (context) {
          return ChangeNotifierProvider<VoiceSearchProvider>(
            create: (context) => VoiceSearchProvider(),
            child: SpeechToTextSearch(),
          );
        }).then((value) {
      if (value != null && value.trim().isNotEmpty) {
        final query = value.trim();
        edtSearch.text = query;
        edtSearch.selection =
            TextSelection.fromPosition(TextPosition(offset: query.length));
        // Run the search right away instead of relying on the debounce
        // listener (which waits 500ms and dedupes by text length).
        context.read<ProductSearchProvider>().setSearchLength(query);
        callApi(isReset: true);
      }
    });
  }
}
