import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/sellerReturnRequestResponse.dart';
import 'package:project/provider/sellerOrderReturnRequestProvider.dart';

class ReturnDetailsScreen extends StatefulWidget {
  final SellerReturnRequest request;

  // The provider is scoped to the list screen and is NOT available on this
  // pushed route, so the caller passes its instance in.
  final SellerOrderReturnRequestProvider provider;

  const ReturnDetailsScreen({
    super.key,
    required this.request,
    required this.provider,
  });

  @override
  State<ReturnDetailsScreen> createState() => _ReturnDetailsScreenState();
}

class _ReturnDetailsScreenState extends State<ReturnDetailsScreen> {
  bool loading = false;

  SellerReturnRequest get request => widget.request;

  @override
  Widget build(BuildContext context) {
    final p = request.products!.first;
    final status = (request.returnStatus ?? "").toLowerCase();
    final isPending = status == "pending";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          request.returnStatus?.isNotEmpty == true
              ? "${request.returnStatus![0].toUpperCase()}${request.returnStatus!.substring(1)}"
              : "Return Request",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("#${request.returnId}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(request.date ?? "")
              ],
            ),

            const SizedBox(height: 14),

            /// PRODUCT
            Row(
              children: [
                if (p.image != null && p.image!.isNotEmpty)
                  Image.network(p.image!, height: 60),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${p.quantity}x ${p.productName}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(p.measurement ?? "")
                  ],
                )
              ],
            ),

            const SizedBox(height: 20),

            /// REASON
            const Text("Reason", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(request.report?.description ?? ""),

            const SizedBox(height: 20),

            /// CUSTOMER
            const Text("Customer Details",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            if (request.customer?.name != null) Text(request.customer!.name!),
            if (request.customer?.mobile != null)
              Text(request.customer!.mobile!),
            if (request.customerAddress?.fullAddress != null)
              Text(request.customerAddress!.fullAddress!),

            const SizedBox(height: 20),

            /// ATTACHMENTS
            if (request.deliveryImages?.customerGivenImages?.isNotEmpty ??
                false) ...[
              const Text("Attachments",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(
                children: request.deliveryImages!.customerGivenImages!
                    .map((e) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            image: DecorationImage(
                                image: NetworkImage(e), fit: BoxFit.cover),
                          ),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 30),

            /// ACTIONS
            if (isPending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff34C759),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: loading ? null : _approve,
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Approve",
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            // Reject Return button commented out
            // const SizedBox(width: 12),
            // Expanded(
            //   child: OutlinedButton(
            //     style: OutlinedButton.styleFrom(
            //       side: const BorderSide(color: Color(0xffFF3B30)),
            //       shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(30)),
            //     ),
            //     onPressed: () {},
            //     child: const Text("Reject Return",
            //         style: TextStyle(color: Color(0xffFF3B30))),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve() async {
    setState(() => loading = true);

    final ok = await widget.provider.updateReturnRequestStatus(
      returnId: request.returnId!,
      context: context,
    );

    if (!mounted) return;
    setState(() => loading = false);

    // Pop with a result so the list screen can refresh.
    if (ok) Navigator.pop(context, true);
  }
}
