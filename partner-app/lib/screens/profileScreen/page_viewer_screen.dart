import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/models/page_model.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class PageViewerScreen extends StatefulWidget {
  final String pageType; // 'terms', 'privacy', 'about'
  final String title;

  const PageViewerScreen({
    Key? key,
    required this.pageType,
    required this.title,
  }) : super(key: key);

  @override
  State<PageViewerScreen> createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  PageModel? _pageData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPageContent();
  }

  Future<void> _fetchPageContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String apiName;
      switch (widget.pageType) {
        case 'terms':
          apiName = ApiAndParams.apiSellerTermsConditions;
          break;
        case 'privacy':
          apiName = ApiAndParams.apiSellerPrivacyPolicy;
          break;
        case 'about':
          apiName = ApiAndParams.apiPageAbout;
          break;
        default:
          apiName = '${ApiAndParams.apiPages}/${widget.pageType}';
      }

      final response = await sendApiRequest(
        apiName: apiName,
        params: {},
        isPost: false,
        privacyAndTerms: true,
      );

      if (response == null) {
        setState(() {
          _errorMessage = 'Failed to load content';
          _isLoading = false;
        });
        return;
      }

      // Check if response is HTML content directly (starts with < or contains HTML tags)
      if (response.trim().startsWith('<') || response.contains('<h2>') || response.contains('<h3>')) {
        // Direct HTML response from seller-terms-conditions or seller-privacy-policy
        setState(() {
          _pageData = PageModel(
            id: 0,
            pageType: widget.pageType,
            title: widget.pageType == 'terms'
                ? 'Terms and Conditions'
                : widget.pageType == 'privacy'
                    ? 'Privacy Policy'
                    : widget.title,
            content: response,
          );
          _isLoading = false;
        });
        return;
      }

      // JSON wrapped response
      final Map<String, dynamic> data = json.decode(response);

      if (data['status'] == 1 || data['status'] == '1') {
        if (data['data'] != null) {
          setState(() {
            _pageData = PageModel.fromJson(data['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                getTranslatedValue(context, noContentAvailableLabel);
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to load content';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return AppHeader(
                    label: _getPageCategory(context),
                    title: widget.title,
                    showBackButton: true,
                  );
                },
              ),
            ),
          ];
        },
        body: _buildBody(),
      ),
    );
  }

  String _getPageCategory(BuildContext context) {
    switch (widget.pageType) {
      case 'terms':
        return getTranslatedValue(context, legalLabel);
      case 'privacy':
        return getTranslatedValue(context, legalLabel);
      case 'about':
        return getTranslatedValue(context, informationLabel);
      default:
        return getTranslatedValue(context, pageLabel);
    }
  }

  Widget _buildShimmerLoading(app_theme.AppColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Shimmer.fromColors(
        baseColor: colorScheme.surface,
        highlightColor: colorScheme.surfaceVariant,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title shimmer
            Container(
              height: 28,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            // Date shimmer
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 24),
            // Divider shimmer
            Container(
              height: 1,
              width: double.infinity,
              color: colorScheme.surface,
            ),
            const SizedBox(height: 24),
            // Paragraph shimmers
            ...List.generate(8, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    if (_isLoading) {
      return _buildShimmerLoading(colorScheme);
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_pageData == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _fetchPageContent,
      color: ColorsRes.appColor,
      backgroundColor: colorScheme.cardBackground,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title
                Text(
                  _pageData!.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // Last updated
                Text(
                  '${getTranslatedValue(context, lastUpdatedLabel)}: ${_formatDate()}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Container(
                  height: 1,
                  color: colorScheme.border,
                ),
                const SizedBox(height: 24),
                // Content section
                Html(
                  data: _pageData!.content,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(15),
                      lineHeight: LineHeight(1.7),
                      color: colorScheme.textPrimary,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                    "h1": Style(
                      fontSize: FontSize(22),
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      margin: Margins.only(top: 24, bottom: 12),
                      letterSpacing: -0.5,
                    ),
                    "h2": Style(
                      fontSize: FontSize(20),
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      margin: Margins.only(top: 24, bottom: 12),
                      letterSpacing: -0.4,
                    ),
                    "h3": Style(
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                      margin: Margins.only(top: 20, bottom: 10),
                      letterSpacing: -0.3,
                    ),
                    "h4": Style(
                      fontSize: FontSize(16),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                      margin: Margins.only(top: 16, bottom: 8),
                      letterSpacing: -0.2,
                    ),
                    "p": Style(
                      fontSize: FontSize(15),
                      lineHeight: LineHeight(1.7),
                      color: colorScheme.textPrimary,
                      margin: Margins.only(bottom: 16),
                    ),
                    "ul": Style(
                      margin: Margins.only(bottom: 16, left: 4),
                      padding: HtmlPaddings.only(left: 20),
                    ),
                    "ol": Style(
                      margin: Margins.only(bottom: 16, left: 4),
                      padding: HtmlPaddings.only(left: 20),
                    ),
                    "li": Style(
                      fontSize: FontSize(15),
                      lineHeight: LineHeight(1.7),
                      color: colorScheme.textPrimary,
                      margin: Margins.only(bottom: 10),
                    ),
                    "strong": Style(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                    ),
                    "b": Style(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textPrimary,
                    ),
                    "em": Style(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.textPrimary,
                    ),
                    "a": Style(
                      color: ColorsRes.appColor,
                      textDecoration: TextDecoration.underline,
                    ),
                    "blockquote": Style(
                      margin: Margins.only(top: 16, bottom: 16, left: 16),
                      padding: HtmlPaddings.only(left: 16),
                      border: Border(
                        left: BorderSide(
                          color: ColorsRes.appColor.withValues(alpha: 0.3),
                          width: 4,
                        ),
                      ),
                      backgroundColor: colorScheme.surfaceVariant,
                    ),
                    "code": Style(
                      backgroundColor: colorScheme.surfaceVariant,
                      color: colorScheme.textPrimary,
                      padding:
                          HtmlPaddings.symmetric(horizontal: 6, vertical: 2),
                      fontSize: FontSize(14),
                      fontFamily: 'monospace',
                    ),
                    "pre": Style(
                      backgroundColor: colorScheme.surfaceVariant,
                      padding: HtmlPaddings.all(12),
                      margin: Margins.only(top: 12, bottom: 12),
                      border: Border.all(color: colorScheme.border),
                    ),
                  },
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Content',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPageContent,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsRes.appColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    // You can format the date as needed
    // For now, returning a placeholder
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }
}
