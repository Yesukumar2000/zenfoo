import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/widgets/shimmer_loading_widget.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/terms_and_conditions_provider.dart';
import 'package:zenfoo_partner/services/status.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String apiEndpoint;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.apiEndpoint,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _fetchWebViewContent();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
        ),
      );
  }

  Future<void> _fetchWebViewContent() async {
    // If it's Terms and Conditions, use the dedicated provider
    final isTerms = widget.apiEndpoint == AppUrl.termsAndConditions ||
        widget.apiEndpoint == '/delivery-boy-terms-conditions' ||
        widget.title.toLowerCase().contains('terms');

    if (isTerms) {
      final termsProvider = context.read<TermsAndConditionsProvider>();
      await termsProvider.getTermsAndConditions();

      if (mounted) {
        if (isStatusSuccess(termsProvider.getTermsAndConditionsState.status)) {
          final htmlContent = termsProvider.htmlContent ?? '';
          setState(() {
            _htmlContent = htmlContent;
            _isLoading = false;
          });
          _loadHtmlContent(htmlContent);
        } else {
          setState(() {
            _errorMessage = termsProvider.getTermsAndConditionsState.message ??
                'Failed to load content';
            _isLoading = false;
          });
        }
      }
      return;
    }

    try {
      final apiService = ApiService();
      // Construct full URL if not already full
      final fullUrl = widget.apiEndpoint.startsWith('http')
          ? widget.apiEndpoint
          : '${AppUrl.baseUrl}${widget.apiEndpoint}';

      final response = await apiService.get(fullUrl, isToast: false);

      if (mounted) {
        if (isStatusSuccess(response.status)) {
          // The response.data might be a String (HTML) or a Map containing 'html'
          String htmlContent = '';
          if (response.data is String) {
            htmlContent = response.data;
          } else if (response.data is Map) {
            htmlContent = response.data['html'] ??
                response.data['content'] ??
                response.data['data']?.toString() ??
                '';
          }

          setState(() {
            _htmlContent = htmlContent;
            _isLoading = false;
          });
          _loadHtmlContent(htmlContent);
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load content';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  void _loadHtmlContent(String htmlContent) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    // Wrap the content with proper styling
    final styledHtml = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          line-height: 1.6;
          color: ${_colorToHex(colorScheme.textPrimary)};
          background-color: ${_colorToHex(colorScheme.background)};
          padding: 20px;
          margin: 0;
        }
        h1, h2, h3, h4, h5, h6 {
          color: ${_colorToHex(colorScheme.textPrimary)};
          margin-top: 20px;
          margin-bottom: 10px;
        }
        p {
          margin: 10px 0;
          color: ${_colorToHex(colorScheme.textSecondary)};
        }
        a {
          color: ${_colorToHex(colorScheme.primary)};
          text-decoration: none;
        }
        a:hover {
          text-decoration: underline;
        }
        ul, ol {
          margin: 10px 0;
          padding-left: 20px;
        }
        li {
          margin: 5px 0;
        }
        blockquote {
          border-left: 4px solid ${_colorToHex(colorScheme.primary)};
          padding-left: 15px;
          margin-left: 0;
          color: ${_colorToHex(colorScheme.textSecondary)};
        }
        code {
          background-color: ${_colorToHex(colorScheme.surfaceElevated)};
          padding: 2px 6px;
          border-radius: 4px;
          font-family: 'Courier New', monospace;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 15px 0;
        }
        th, td {
          border: 1px solid ${_colorToHex(colorScheme.border)};
          padding: 12px;
          text-align: left;
        }
        th {
          background-color: ${_colorToHex(colorScheme.surfaceElevated)};
        }
      </style>
    </head>
    <body>
      $htmlContent
    </body>
    </html>
    ''';

    _webViewController.loadHtmlString(styledHtml);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label:
                context.watch<LanguageProvider>().getTranslatedText('privacy'),
            title: widget.title,
            showBackButton: true,
          ),

          // CONTENT
          Expanded(
            child: _buildContent(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppColorScheme colorScheme) {
    if (_isLoading) {
      return SingleChildScrollView(
        child: ShimmerLoadingWidget(
          colorScheme: colorScheme,
          itemCount: 4,
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.inter(
                  color: colorScheme.error,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Failed to load content',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchWebViewContent();
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_htmlContent != null && _htmlContent!.isNotEmpty) {
      return WebViewWidget(controller: _webViewController);
    }

    return Center(
      child: Text(
        'No content available',
        style: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
