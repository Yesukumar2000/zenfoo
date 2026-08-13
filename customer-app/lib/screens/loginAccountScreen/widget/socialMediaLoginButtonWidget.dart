import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class SocialMediaLoginButtonWidget extends StatelessWidget {
  final String text;
  final String logo;
  final VoidCallback onPressed;
  final Color? logoColor;

  const SocialMediaLoginButtonWidget({
    super.key,
    required this.text,
    required this.logo,
    required this.onPressed,
    this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colorScheme.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Spacer(),
          defaultImg(
            image: logo,
            height: 24,
            width: 24,
            iconColor: logoColor,
            boxFit: BoxFit.fitWidth,
          ),
          getSizedBox(width: 10),
          CustomTextLabel(
            jsonKey: text,
            style: TextStyle(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
