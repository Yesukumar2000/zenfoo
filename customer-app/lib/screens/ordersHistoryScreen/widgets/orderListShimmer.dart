import 'package:project/helper/utils/generalImports.dart';

class OrderListShimmer extends StatelessWidget {
  const OrderListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 6,
      itemBuilder: (context, index) => const OrderContainerShimmer(),
    );
  }
}
