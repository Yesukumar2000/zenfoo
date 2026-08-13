import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class CustomShimmer extends StatelessWidget {
  final double? height;
  final double? width;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;

  const CustomShimmer(
      {Key? key, this.height, this.width, this.borderRadius, this.margin})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Shimmer.fromColors(
      enabled: true,
      baseColor: colorScheme.shimmerBase,
      highlightColor: colorScheme.shimmerHighlight,
      child: Container(
        width: width,
        margin: margin ?? EdgeInsets.zero,
        height: height ?? 10,
        decoration: BoxDecoration(
            color: colorScheme.shimmerContent,
            borderRadius: BorderRadius.circular(borderRadius ?? 10)),
      ),
    );
  }
}