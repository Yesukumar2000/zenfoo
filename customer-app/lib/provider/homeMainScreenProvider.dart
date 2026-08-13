import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/mainHomeScreen/categories_page.dart';
import 'package:project/screens/mainHomeScreen/supermart_screen.dart';
import 'package:project/screens/reorder/reorderScreen.dart';
import 'package:project/provider/reorderProvider.dart';

class HomeMainScreenProvider extends ChangeNotifier {
  int currentPage = 0;

  List<ScrollController> scrollController = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];

  //total pageListing
  List<Widget> pages = [];

  // Navbar offset for CartOverlay translation
  double navBarOffset = 0;

  setPages() {
    pages = [
      ChangeNotifierProvider<ProductListProvider>(
        create: (context) {
          return ProductListProvider();
        },
        child: HomeScreen(
          scrollController: scrollController[0],
        ),
      ),
      CategoriesPage(
        scrollController: scrollController[1],
      ),
      SupermartScreen(
        scrollController: scrollController[2],
      ),
      // Keeps its own ReorderProvider, exactly as before. The home screen's
      // "Buy it again" rail reads a separate app-root instance (main.dart)
      // rather than sharing this one, so nothing about this tab changes.
      ChangeNotifierProvider<ReorderProvider>(
        create: (context) {
          return ReorderProvider();
        },
        child: ReorderScreen(
          scrollController: scrollController[3],
        ),
      ),
      // WishListScreen(
      //   scrollController: scrollController[2],
      // ),
      // ProfileScreen(
      //   scrollController: scrollController[3],
      // )
    ];
  }

  //change current screen based on bottom menu selection
  Future selectBottomMenu(int index) async {
    try {
      if (index == currentPage && scrollController[currentPage].offset > 0) {
        scrollController[currentPage].animateTo(0,
            duration: const Duration(milliseconds: 400), curve: Curves.linear);
      }

      currentPage = index;
    } catch (_) {}
    notifyListeners();
  }

  getCurrentPage() {
    return currentPage;
  }

  getPages() {
    return pages;
  }

  @override
  void dispose() {
    for (var controller in scrollController) {
      controller.dispose();
    }
    super.dispose();
  }
}
