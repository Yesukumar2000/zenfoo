import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/sellerReturnRequestResponse.dart';
import 'package:project/provider/sellerOrderReturnRequestProvider.dart';
import 'package:project/screens/mainHomeScreen/orderListScreen/widget/sellerReturnDetailsScreen.dart';

class SellerReturnRequestCard extends StatefulWidget {
  final SellerReturnRequest request;
  final VoidCallback? refresh;

  const SellerReturnRequestCard({
    super.key,
    required this.request,
    this.refresh,
  });

  @override
  State<SellerReturnRequestCard> createState() => _SellerReturnRequestCardState();
}

class _SellerReturnRequestCardState extends State<SellerReturnRequestCard> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final product = r.products!.first;
    final status = r.returnStatus!.toLowerCase();

    Color statusColor =
        status == "approved" ? const Color(0xff34C759)
      : status == "rejected" ? const Color(0xffFF3B30)
      : const Color(0xffFF9500);

    return InkWell(
      onTap: () async {
        final provider = context.read<SellerOrderReturnRequestProvider>();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ReturnDetailsScreen(request: r, provider: provider),
          ),
        );
        // Detail screen returns true after a successful approve.
        if (result == true) widget.refresh?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: .05),
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// STATUS + ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "#${r.report?.orderId ?? r.returnId}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// DATE
            Text(
              r.date!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 12),

            /// PRODUCT
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(product.image!,
                      height: 55, width: 55, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${product.quantity}x ${product.productName}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(product.measurement ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600))
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),

            /// REPORT TYPE
            Text.rich(
              TextSpan(
                text: "Report type : ",
                style: TextStyle(color: Colors.grey.shade600),
                children: [
                  TextSpan(
                    text: r.report!.reportType,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black),
                  )
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// BUTTONS
            if (status == "pending")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : approve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff34C759),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("Approve", style: TextStyle(color: Colors.white)),
                ),
              )
              // Reject Return button commented out
              // const SizedBox(width: 10),
              // Expanded(
              //   child: OutlinedButton(
              //     onPressed: () {},
              //     style: OutlinedButton.styleFrom(
              //       side: const BorderSide(color: Color(0xffFF3B30)),
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(30)),
              //     ),
              //     child: const Text("Reject Return",
              //         style: TextStyle(color: Color(0xffFF3B30))),
              //   ),
              // ),
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final provider =
                        context.read<SellerOrderReturnRequestProvider>();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReturnDetailsScreen(request: r, provider: provider),
                      ),
                    );
                    if (result == true) widget.refresh?.call();
                  },
                  child: const Text("View Details"),
                ),
              )
          ],
        ),
      ),
    );
  }

  Future<void> approve() async {
    setState(() => loading = true);

    final ok = await context
        .read<SellerOrderReturnRequestProvider>()
        .updateReturnRequestStatus(
          returnId: widget.request.returnId!,
          context: context,
        );

    setState(() => loading = false);

    if (ok) widget.refresh?.call();
  }
}

