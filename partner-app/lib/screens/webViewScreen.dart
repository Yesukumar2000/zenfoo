import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/policyAndTermsProvider.dart';
import 'package:quill_html_editor/quill_html_editor.dart';

class WebViewScreen extends StatefulWidget {
  final String dataFor;

  WebViewScreen({Key? key, required this.dataFor}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Constant.session.isUserLoggedIn()) {
      } else {
        context.read<PolicyAndTermsProvider>().loadPolicyAndTerms(
              Constant.session.isSeller()
                  ? widget.dataFor == getTranslatedValue(context, privacyPolicyLabel)
                      ? ApiAndParams.apiSellerPrivacyPolicy
                      : ApiAndParams.apiSellerTermsConditions
                  : widget.dataFor == getTranslatedValue(context, privacyPolicyLabel)
                      ? ApiAndParams.apiDeliveryBoyPrivacyPolicy
                      : ApiAndParams.apiDeliveryBoyTermsConditions,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(
          title: CustomTextLabel(
            text: widget.dataFor,
            style: TextStyle(color: ColorsRes.mainTextColor),
          ),
          context: context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsDirectional.all(Constant.paddingOrMargin10),
          child: (Constant.session.isUserLoggedIn())
              ? _buildEditor(
                  text: widget.dataFor == getTranslatedValue(context, privacyPolicyLabel) ? Constant.privacyPolicy : Constant.termsConditions)
              : Consumer<PolicyAndTermsProvider>(
                  builder: (context, provider, child) {
                    switch (provider.state) {
                      case PolicyAndTermsState.initial:
                        return Center(
                          child: CircularProgressIndicator(color: ColorsRes.appColor),
                        );
                      case PolicyAndTermsState.loading:
                        return Center(
                          child: CircularProgressIndicator(color: ColorsRes.appColor),
                        );

                      case PolicyAndTermsState.error:
                        return Center(
                          child: CustomTextLabel(
                            text: getTranslatedValue(context, somethingWentWrongLabel),
                            style: TextStyle(color: ColorsRes.appColorRed),
                          ),
                        );

                      case PolicyAndTermsState.loaded:
                        return FutureBuilder(
                          future: Future.delayed(Duration(milliseconds: 100)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator(color: ColorsRes.appColor));
                            }
                            return _buildEditor(text: provider.content ?? "");
                          },
                        );
                    }
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEditor({required String text}) {
    return QuillHtmlEditor(
      text: text,
      hintText: getTranslatedValue(context, descriptionGoesHereLabel),
      isEnabled: false,
      ensureVisible: false,
      minHeight: 10,
      autoFocus: false,
      textStyle: TextStyle(color: ColorsRes.mainTextColor),
      hintTextStyle: TextStyle(color: ColorsRes.subTitleTextColor),
      hintTextAlign: TextAlign.start,
      padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
      hintTextPadding: const EdgeInsets.only(left: 20),
      backgroundColor: Theme.of(context).cardColor,
      inputAction: InputAction.newline,
      loadingBuilder: (context) {
        return Center(
          child: CircularProgressIndicator(
            color: ColorsRes.appColor,
          ),
        );
      },
      controller: QuillEditorController(),
    );
  }
}
