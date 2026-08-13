import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;


Widget buildDottedDivider(BuildContext context) {
  final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

  return Row(
    children: [
      getSizedBox(width: Constant.size20),
      Expanded(
        child: DashedDivider(height: 1),
      ),
      CircleAvatar(
        backgroundColor: colorScheme.background,
        radius: 15,
        child: CustomTextLabel(
          jsonKey: or_Label,
          style: TextStyle(color: colorScheme.textSecondary, fontSize: 12),
        ),
      ),
      Expanded(
        child: DashedDivider(height: 1),
      ),
      getSizedBox(width: Constant.size20),
    ],
  );
}