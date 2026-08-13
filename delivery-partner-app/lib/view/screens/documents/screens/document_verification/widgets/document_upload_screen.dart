import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/view/custom_widgets/customAppBar.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_gradient_scaffold.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/document_verification/widgets/document_upload_box.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class DocumentUploadScreen extends StatelessWidget {
  final String appBarTitle;
  final List<Widget> uploadBoxes;
  final void Function() onSubmit;

  const DocumentUploadScreen({
    super.key,
    required this.appBarTitle,
    required this.uploadBoxes,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CustomGradientScaffold(
      title: appBarTitle,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: AppDimensions.getSize(40),
            ),
            Column(
              children: List.generate(
                  uploadBoxes.length, (index) => uploadBoxes[index]),
            ),
            const Spacer(),
            CustomButton(text: 'Submit', onPressed: onSubmit),
          ],
        ),
      ),
    );
  }
}
