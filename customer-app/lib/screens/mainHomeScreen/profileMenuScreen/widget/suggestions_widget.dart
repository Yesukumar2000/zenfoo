import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const int _maxLength = 200;
  static const int _minLength = 5;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final provider = context.read<SuggestionProvider>();
      provider.reset();
      provider.getSuggestions(context: context);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final trigger = 0.7 * _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels > trigger) {
      final provider = context.read<SuggestionProvider>();
      if (provider.hasMoreData) {
        provider.getSuggestions(context: context);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.length < _minLength) return;

    final success = await context
        .read<SuggestionProvider>()
        .submitSuggestion(context: context, text: text);

    if (success && mounted) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: getTranslatedValue(context, 'feedback'),
            title: getTranslatedValue(context, 'add_suggestions'),
            showBackButton: true,
          ),
          Expanded(
            child: Consumer<SuggestionProvider>(
              builder: (context, provider, _) {
                return ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  children: [
                    // Input field
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.inputBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.inputBorder),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 120),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          maxLength: _maxLength,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.textPrimary,
                            height: 1.3,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: getTranslatedValue(
                                context, 'add_your_suggestions'),
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: colorScheme.inputPlaceholder,
                              height: 1.3,
                            ),
                            counterText:
                                "${_controller.text.length}/$_maxLength",
                            counterStyle: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_controller.text.trim().length < _minLength ||
                                provider.isSubmitting)
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.primary,
                          disabledBackgroundColor:
                              colorScheme.buttonDisabledBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: provider.isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.buttonPrimaryText,
                                ),
                              )
                            : Text(
                                getTranslatedValue(context, 'submit'),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.buttonPrimaryText,
                                  height: 1.02,
                                  letterSpacing: -0.55,
                                ),
                              ),
                      ),
                    ),
                    // Previous suggestions
                    if (provider.listState == SuggestionState.loading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (provider.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        getTranslatedValue(context, 'previous_suggestions'),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...provider.suggestions
                          .map((s) => _SuggestionCard(
                              suggestion: s, colorScheme: colorScheme))
                          .toList(),
                      if (provider.listState == SuggestionState.loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final dynamic colorScheme;

  const _SuggestionCard(
      {required this.suggestion, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion.suggestion,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: suggestion.adminResponse != null
                  ? colorScheme.primary.withOpacity(0.08)
                  : colorScheme.textSecondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  suggestion.adminResponse != null
                      ? Icons.support_agent_rounded
                      : Icons.hourglass_empty_rounded,
                  size: 14,
                  color: suggestion.adminResponse != null
                      ? colorScheme.primary
                      : colorScheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    suggestion.adminResponse ??
                        getTranslatedValue(context, 'admin_not_responded'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: suggestion.adminResponse != null
                          ? colorScheme.textSecondary
                          : colorScheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
