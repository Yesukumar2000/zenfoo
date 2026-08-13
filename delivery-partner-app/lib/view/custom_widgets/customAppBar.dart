import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Color? titleColor;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final bool? isPopup;
  final List<Widget>? actions;

  const CustomAppBar(
      {super.key,
      this.title,
      this.onBack,
      this.isPopup = true,
      this.actions,
      this.backgroundColor,
      this.titleColor});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 12),

          /// BACK BUTTON
          if (isPopup ?? true)
            InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: onBack ?? () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),

          const SizedBox(width: 14),

          /// TITLE
          if (title != null)
            Text(
              title ?? '',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: titleColor ?? Colors.white,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
