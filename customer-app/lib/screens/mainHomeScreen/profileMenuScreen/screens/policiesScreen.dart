import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/repositories/policiesApi.dart';
import 'package:flutter_html/flutter_html.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  State<AboutUs> createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  bool _isLoading = true;
  String _htmlContent = '';

  @override
  void initState() {
    super.initState();
    _fetchAboutUs();
  }

  Future<void> _fetchAboutUs() async {
    try {
      final response = await getAboutUsApi(context: context);

      if (response != null && response.isNotEmpty) {
        setState(() {
          _htmlContent = response;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching about us: $e');
    }

    // Fallback to Constant.aboutUs if API fails
    setState(() {
      _htmlContent = Constant.aboutUs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, 'information'),
            title: getTranslatedValue(context, aboutUsLabel),
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _htmlContent.isEmpty
                    ? Center(
                        child: Text(
                          getTranslatedValue(context, 'no_data_found'),
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: colorScheme.screenGradient,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: GradientBorderCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 18,
                            gradient: colorScheme.cardGradient,
                            borderGradient: colorScheme.borderGradient,
                            shadows: colorScheme.cardShadow,
                            child: Html(
                              data: _htmlContent,
                              style: {
                                "body": Style(
                                  color: colorScheme.textPrimary,
                                  fontSize: FontSize(14),
                                  lineHeight: const LineHeight(1.5),
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "*": Style(color: colorScheme.textPrimary),
                              },
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}




class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  bool _isLoading = true;
  String _htmlContent = '';

  @override
  void initState() {
    super.initState();
    _fetchContactUs();
  }

  Future<void> _fetchContactUs() async {
    try {
      final response = await getContactUsApi(context: context);

      if (response != null && response.isNotEmpty) {
        setState(() {
          _htmlContent = response;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching about us: $e');
    }

    // Fallback to Constant.contactUs if API fails
    setState(() {
      _htmlContent = Constant.contactUs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, 'information'),
            title: getTranslatedValue(context, contactUsLabel),
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _htmlContent.isEmpty
                    ? Center(
                        child: Text(
                          getTranslatedValue(context, 'no_data_found'),
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: colorScheme.screenGradient,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: GradientBorderCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 18,
                            gradient: colorScheme.cardGradient,
                            borderGradient: colorScheme.borderGradient,
                            shadows: colorScheme.cardShadow,
                            child: Html(
                              data: _htmlContent,
                              style: {
                                "body": Style(
                                  color: colorScheme.textPrimary,
                                  fontSize: FontSize(14),
                                  lineHeight: const LineHeight(1.5),
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "*": Style(color: colorScheme.textPrimary),
                              },
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}


class TermsAndConditions extends StatefulWidget {
  const TermsAndConditions({super.key});

  @override
  State<TermsAndConditions> createState() => _TermsAndConditionsState();
}

class _TermsAndConditionsState extends State<TermsAndConditions> {
  bool _isLoading = true;
  String _htmlContent = '';

  @override
  void initState() {
    super.initState();
    _fetchTermsAndConditions();
  }

  Future<void> _fetchTermsAndConditions() async {
    try {
      final response = await getTermsAndConditionsApi(context: context);

      if (response != null && response.isNotEmpty) {
        setState(() {
          _htmlContent = response;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching terms and conditions: $e');
    }

    // Fallback to Constant.termsAndConditions if API fails
    setState(() {
      _htmlContent = Constant.termsConditions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, 'information'),
            title: getTranslatedValue(context, termsAndConditionsLabel),
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _htmlContent.isEmpty
                    ? Center(
                        child: Text(
                          getTranslatedValue(context, 'no_data_found'),
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: colorScheme.screenGradient,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: GradientBorderCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 18,
                            gradient: colorScheme.cardGradient,
                            borderGradient: colorScheme.borderGradient,
                            shadows: colorScheme.cardShadow,
                            child: Html(
                              data: _htmlContent,
                              style: {
                                "body": Style(
                                  color: colorScheme.textPrimary,
                                  fontSize: FontSize(14),
                                  lineHeight: const LineHeight(1.5),
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "*": Style(color: colorScheme.textPrimary),
                              },
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}




class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  bool _isLoading = true;
  String _htmlContent = '';

  @override
  void initState() {
    super.initState();
    _fetchPrivacyPolicy();
  }

  Future<void> _fetchPrivacyPolicy() async {
    try {
      final response = await getPrivacyPolicyApi(context: context);

      if (response != null && response.isNotEmpty) {
        setState(() {
          _htmlContent = response;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching privacy policy: $e');
    }

    // Fallback to Constant.privacyPolicy if API fails
    setState(() {
      _htmlContent = Constant.privacyPolicy;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, 'information'),
            title: getTranslatedValue(context, privacyPolicyLabel),
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _htmlContent.isEmpty
                    ? Center(
                        child: Text(
                          getTranslatedValue(context, 'no_data_found'),
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: colorScheme.screenGradient,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: GradientBorderCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 18,
                            gradient: colorScheme.cardGradient,
                            borderGradient: colorScheme.borderGradient,
                            shadows: colorScheme.cardShadow,
                            child: Html(
                              data: _htmlContent,
                              style: {
                                "body": Style(
                                  color: colorScheme.textPrimary,
                                  fontSize: FontSize(14),
                                  lineHeight: const LineHeight(1.5),
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "*": Style(color: colorScheme.textPrimary),
                              },
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}


class RefundPolicy extends StatefulWidget {
  const RefundPolicy({super.key});

  @override
  State<RefundPolicy> createState() => _RefundPolicyState();
}

class _RefundPolicyState extends State<RefundPolicy> {
  bool _isLoading = true;
  String _htmlContent = '';

  @override
  void initState() {
    super.initState();
    _fetchRefundPolicy();
  }

  Future<void> _fetchRefundPolicy() async {
    try {
      final response = await getRefundPolicyApi(context: context);

      if (response != null && response.isNotEmpty) {
        setState(() {
          _htmlContent = response;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching privacy policy: $e');
    }

    // Fallback to Constant.privacyPolicy if API fails
    setState(() {
      _htmlContent = Constant.privacyPolicy;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, 'information'),
            title: getTranslatedValue(context, refundPolicyLabel),
            showBackButton: true,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _htmlContent.isEmpty
                    ? Center(
                        child: Text(
                          getTranslatedValue(context, 'no_data_found'),
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: colorScheme.screenGradient,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: GradientBorderCard(
                            padding: const EdgeInsets.all(16),
                            borderRadius: 18,
                            gradient: colorScheme.cardGradient,
                            borderGradient: colorScheme.borderGradient,
                            shadows: colorScheme.cardShadow,
                            child: Html(
                              data: _htmlContent,
                              style: {
                                "body": Style(
                                  color: colorScheme.textPrimary,
                                  fontSize: FontSize(14),
                                  lineHeight: const LineHeight(1.5),
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "*": Style(color: colorScheme.textPrimary),
                              },
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}