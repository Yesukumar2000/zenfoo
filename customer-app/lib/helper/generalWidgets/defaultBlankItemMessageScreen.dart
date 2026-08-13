import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class DefaultBlankItemMessageScreen extends StatelessWidget {
  final String image, title, description;
  final Function? callback;
  final String? buttonTitle;
  final double? height;
  final bool isTranslationKey;

  const DefaultBlankItemMessageScreen({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    this.callback,
    this.buttonTitle,
    this.height,
    this.isTranslationKey = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      height: height ?? context.height * 0.65,
      width: context.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Image
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: defaultImg(
                image: image,
                iconColor: colorScheme.primary.withValues(alpha: 0.6),
                width: 72,
                height: 72,
              ),
            ),
          ),

          // Title
          if (title.isNotEmpty)
            isTranslationKey
                ? CustomTextLabel(
                    jsonKey: title,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.55,
                      height: 1.3,
                    ),
                  )
                : Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.55,
                      height: 1.3,
                    ),
                  ),

          if (title.isNotEmpty) const SizedBox(height: 8),

          // Description
          isTranslationKey
              ? CustomTextLabel(
                  jsonKey: description,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.55,
                    height: 1.5,
                  ),
                )
              : Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.55,
                    height: 1.5,
                  ),
                ),

          // Button
          if (callback != null && buttonTitle != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                callback!();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isTranslationKey
                    ? CustomTextLabel(
                        jsonKey: buttonTitle,
                        softWrap: true,
                        style: GoogleFonts.inter(
                          color: colorScheme.buttonPrimaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.55,
                        ),
                      )
                    : Text(
                        buttonTitle!,
                        style: GoogleFonts.inter(
                          color: colorScheme.buttonPrimaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.55,
                        ),
                      ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
