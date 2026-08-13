import 'dart:io' as io;

import 'package:project/helper/utils/generalImports.dart';


class OrderInvoiceWidget extends StatelessWidget {
  final Order order;

  const OrderInvoiceWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderInvoiceProvider>(
      builder: (context, orderInvoiceProvider, child) {
        return GestureDetector(
          onTap: () {
            orderInvoiceProvider.getOrderInvoiceApiProvider(
              params: {ApiAndParams.orderId: order.id.toString()},
              context: context,
            ).then(
              (pdfContent) async {
                if (pdfContent == null) return;
                try {
                  final dir = await getApplicationDocumentsDirectory();
                  final targetFileName =
                      "${getTranslatedValue(context, appNameLabel)}-${getTranslatedValue(context, invoiceLabel)}-${order.displayNumber}.pdf";
                  final file = io.File("${dir.path}/$targetFileName");
                  await file.writeAsBytes(pdfContent);

                  final result = await OpenFile.open(file.path);
                  if (result.type != ResultType.done) {
                    if (context.mounted) {
                      showMessage(context, result.message, MessageType.warning);
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    showMessage(context, e.toString(), MessageType.warning);
                  }
                }
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextLabel(
                  jsonKey: downloadInvoiceLabel,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 6),
                if (orderInvoiceProvider.orderInvoiceState ==
                    OrderInvoiceState.loading)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                if (orderInvoiceProvider.orderInvoiceState !=
                    OrderInvoiceState.loading)
                  const Icon(
                    Icons.download_for_offline_outlined,
                    size: 18,
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}
