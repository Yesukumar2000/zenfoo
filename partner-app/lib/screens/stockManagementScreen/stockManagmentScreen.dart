import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';

class StockManagementScreen extends StatefulWidget {
  StockManagementScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<StockManagementScreen> {
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();

  scrollListener() {
    // nextPageTrigger will have a value equivalent to 70% of the list size.
    var nextPageTrigger = 0.7 * scrollController.position.maxScrollExtent;

// _scrollController fetches the next paginated data when the current position of the user on the screen has surpassed
    if (scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        if (context.read<ProductStockManagementProvider>().hasMoreData &&
            context
                    .read<ProductStockManagementProvider>()
                    .stockManagementState !=
                StockManagementState.loadingMore) {
          callApi(isReset: false);
        }
      }
    }
  }

  callApi({required bool isReset}) async {
    try {
      if (isReset) {
        context.read<ProductStockManagementProvider>().offset = 0;

        context
            .read<ProductStockManagementProvider>()
            .productsStockManagementData = [];
        context
            .read<ProductStockManagementProvider>()
            .productsStockManagementData = [];
      }

      Map<String, String> params = {};
      print("searchController.text.trim().isNotEmpty:${searchController.text.trim().isNotEmpty}");

      if (searchController.text.trim().isNotEmpty) {
        params[ApiAndParams.search] = searchController.text.toString();
      }

      await context
          .read<ProductStockManagementProvider>()
          .getProductVariantsProvider(context: context, params: params);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    //fetch productList from api
    Future.delayed(Duration.zero).then((value) async {
      searchController.addListener(() {
        Future.delayed(Duration(seconds: 1)).then((value) async {
          callApi(isReset: true);
        });
      });
      scrollController.addListener(scrollListener);
      callApi(isReset: true);
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ProductStockManagementProvider>().offset = 0;
          context
              .read<ProductStockManagementProvider>()
              .productsStockManagementData = [];
          await callApi(isReset: true);
        },
        color: Color(0xFF9AC444),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            // App Header
            SliverToBoxAdapter(
              child: AppHeader(
                label: 'Inventory',
                title: 'Stock Management',
                showBackButton: false,
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Container(
                  height: 48,
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: -0.3,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Product List
            productWidget(),
          ],
        ),
      ),
    );
  }

  Widget productWidget() {
    return Consumer<ProductStockManagementProvider>(
      builder: (context, productStockManagementProvider, _) {
        if (productStockManagementProvider.stockManagementState ==
                StockManagementState.initial ||
            productStockManagementProvider.stockManagementState ==
                StockManagementState.loading) {
          return getProductListShimmer(context: context, isGrid: false);
        } else if (productStockManagementProvider.stockManagementState ==
                StockManagementState.loaded ||
            productStockManagementProvider.stockManagementState ==
                StockManagementState.loadingMore) {
          List<ProductsStockManagementData> products =
              productStockManagementProvider.productsStockManagementData;
          return Column(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  products.length,
                  (productIndex) {
                    ProductsStockManagementData product =
                        productStockManagementProvider
                            .productsStockManagementData[productIndex];
                    return ChangeNotifierProvider<ProductStockUpdateProvider>(
                      create: (BuildContext context) {
                        return ProductStockUpdateProvider();
                      },
                      builder: (context, child) {
                        return ProductStockItemContainer(
                          product: product,
                        );
                      },
                    );
                  },
                ),
              ),
              if (productStockManagementProvider.stockManagementState ==
                  StockManagementState.loadingMore)
                getProductItemShimmer(context: context, isGrid: false),
            ],
          );
        } else if (productStockManagementProvider.stockManagementState ==
            StockManagementState.empty) {
          return DefaultBlankItemMessageScreen(
            title: getTranslatedValue(context, emptyProductListMessageLabel),
            description:
                getTranslatedValue(context, emptyProductListDescriptionLabel),
            image: "no_product_icon",
          );
        } else {
          return DefaultBlankItemMessageScreen(
            title: getTranslatedValue(context, emptyProductListMessageLabel),
            description:
                getTranslatedValue(context, emptyProductListDescriptionLabel),
            image: "no_product_icon",
          );
        }
      },
    );
  }

  Future<List<List<String>>> getSizeListSizesAndIds(List sizeList) async {
    List<String> sizes = [];
    List<String> unitIds = [];

    for (int i = 0; i < sizeList.length; i++) {
      if (i % 2 == 0) {
        sizes.add(sizeList[i].toString().split("-")[0]);
      } else {
        unitIds.add(sizeList[i].toString().split("-")[1]);
      }
    }
    return [sizes, unitIds];
  }

  String getFiltersItemsList(List<String> param) {
    String ids = "";
    for (int i = 0; i < param.length; i++) {
      ids += "${param[i]}${i == (param.length - 1) ? "" : ","}";
    }
    return ids;
  }
}
