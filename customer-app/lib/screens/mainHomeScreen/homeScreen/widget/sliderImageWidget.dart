import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/categoryProducts/category_products_page.dart';

class SliderImageWidget extends StatefulWidget {
  final List<Sliders> sliders;
  const SliderImageWidget({Key? key, required this.sliders}) : super(key: key);

  @override
  State<SliderImageWidget> createState() => _SliderImageWidgetState();
}

class _SliderImageWidgetState extends State<SliderImageWidget> {
  late final PageController _pageController;
  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sliderTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (!mounted) return;

        final currIndex =
            context.read<SliderImagesProvider>().currentSliderImageIndex;
        if (currIndex < (widget.sliders.length - 1)) {
          context
              .read<SliderImagesProvider>()
              .setSliderCurrentIndexImage(currIndex + 1);
        } else {
          context.read<SliderImagesProvider>().setSliderCurrentIndexImage(0);
        }

        final nextIndex =
            context.read<SliderImagesProvider>().currentSliderImageIndex;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          print('PageController has no clients yet');
        }
      });
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (widget.sliders.length != 0)
        ? Column(
            children: [
              SizedBox(
                height: 172.h,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.sliders.length,
                  itemBuilder: (context, index) {
                    Sliders sliderData = widget.sliders[index];
                    return Padding(
                      padding: EdgeInsetsDirectional.all(10),
                      child: GestureDetector(
                        onTap: () {
                          callMethod(context
                              .read<SliderImagesProvider>()
                              .currentSliderImageIndex);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          child: ClipRRect(
                            borderRadius: Constant.borderRadius10,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: setNetworkImg(
                              image: sliderData.imageUrl ?? "",
                              boxFit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  onPageChanged: (value) {
                    context
                        .read<SliderImagesProvider>()
                        .setSliderCurrentIndexImage(value);
                  },
                ),
              ),
              getSizedBox(height: Constant.size2),
              Consumer<SliderImagesProvider>(
                builder: (context, sliderImagesProvider, child) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.sliders.length,
                        (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: Constant.size8,
                            width:
                                sliderImagesProvider.currentSliderImageIndex ==
                                        index
                                    ? 20
                                    : 8,
                            margin: EdgeInsets.symmetric(
                                horizontal: Constant.size2),
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              color: sliderImagesProvider
                                          .currentSliderImageIndex ==
                                      index
                                  ? Theme.of(context).primaryColor
                                  : ColorsRes.mainTextColor,
                              shape: BoxShape.rectangle,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          )
        : SizedBox.shrink();
  }

  Future<void> callMethod(int index) async {
    if (mounted) {
      final slider = widget.sliders[index];
      if (slider.type == "slider_url") {
        if (await canLaunchUrl(Uri.parse(slider.sliderUrl ?? ""))) {
          await launchUrl(Uri.parse(slider.sliderUrl ?? ""),
              mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch ${slider.sliderUrl}';
        }
      } else if (slider.type == "category") {
        // Navigate to CategoryProductScreen
        // sub_category_group_id = used for API call to fetch categories list
        // type_id = used as category_id to pre-select and fetch products
        // sub_category_name = used as title
        final subCategoryGroupId = int.tryParse(slider.subCategoryGroupId ?? '') ?? 0;
        final typeId = int.tryParse(slider.typeId ?? '') ?? 0;
        final title = slider.subCategoryName?.isNotEmpty == true
            ? (slider.subCategoryName??'')
            : ('');

        debugPrint('=== SLIDER CATEGORY TAP DEBUG ===');
        debugPrint('slider.subCategoryGroupId: ${slider.subCategoryGroupId}');
        debugPrint('slider.subCategoryName: ${slider.subCategoryName}');
        debugPrint('slider.typeId: ${slider.typeId}');
        debugPrint('slider.typeName: ${slider.typeName}');
        debugPrint('parsed subCategoryGroupId (for API): $subCategoryGroupId');
        debugPrint('parsed typeId (for pre-select): $typeId');
        debugPrint('title to use: $title');
        debugPrint('=================================');

        if (subCategoryGroupId > 0) {
          debugPrint('Navigating to CategoryProductScreen:');
          debugPrint('  subCategoryGroupId (API): $subCategoryGroupId');
          debugPrint('  initialSelectedCategoryId (pre-select): ${typeId > 0 ? typeId : null}');
          debugPrint('  title: $title');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryProductScreen(
                subCategoryGroupId: subCategoryGroupId,
                title: title,
                initialSelectedCategoryId: typeId > 0 ? typeId : null,
              ),
            ),
          );
        } else {
          // Fallback: if no categoryGroupId, check hasChild
          final hasChild = slider.category?.hasChild ?? false;
          if (hasChild) {
            Navigator.pushNamed(context, categoryListScreen, arguments: [
              ScrollController(),
              slider.typeName,
              slider.typeId.toString()
            ]);
          } else {
            Navigator.pushNamed(context, productListScreen, arguments: [
              "category",
              slider.typeId.toString(),
              slider.typeName
            ]);
          }
        }
      } else if (slider.type == "product") {
        Navigator.pushNamed(context, productDetailScreen,
            arguments: [slider.typeId.toString(), slider.typeName, null]);
      } else if (slider.type == "store") {
        // Handle store type slider - switch to the corresponding store tab
        final storeId = int.tryParse(slider.storeId ?? '') ?? 0;

        debugPrint('=== SLIDER STORE TAP DEBUG ===');
        debugPrint('slider.storeId: ${slider.storeId}');
        debugPrint('parsed storeId: $storeId');

        if (storeId > 0) {
          final homeProvider = context.read<HomeScreenProvider>();
          final storeGroups = homeProvider.storeGroups;

          // Find the index of the store in storeGroups that matches storeId
          int storeIndex = -1;
          for (int i = 0; i < storeGroups.length; i++) {
            if (storeGroups[i].id == storeId) {
              storeIndex = i;
              break;
            }
          }

          debugPrint('storeGroups count: ${storeGroups.length}');
          debugPrint('found storeIndex: $storeIndex');
          debugPrint('=================================');

          if (storeIndex > 0) {
            // Switch to the store tab
            homeProvider.setSelectedStoreTab(context, storeIndex);
          } else {
            debugPrint('Store not found in storeGroups or is "All" (index 0)');
          }
        }
      }
    }
  }
}
