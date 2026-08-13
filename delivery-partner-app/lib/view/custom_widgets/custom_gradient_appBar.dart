import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';

class CustomGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? title;
  final Color? titleColor;
  final VoidCallback? onBack;
  final Widget? leading;
  final Color? backgroundColor;
  final bool? isPopup;
  final double? leadingWidth;
  final List<Widget>? actions;
  final Widget? titleWidget;

  const CustomGradientAppBar(
      {super.key,
      this.title,
      this.onBack,
      this.isPopup = true,
      this.actions,
      this.backgroundColor,
      this.titleColor,
      this.leading,
      this.leadingWidth,
      this.titleWidget});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      leadingWidth: leadingWidth,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      titleSpacing: 0,
      leading: leading,
      title: titleWidget ??
          Text(title ?? '', style: Theme.of(context).textTheme.titleLarge),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
