import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';

class ProfileMenuItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final dynamic icon; // HugeIconData
  final VoidCallback onTap;
  final AppColorScheme colorScheme;
  final bool showArrow;

  const ProfileMenuItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    required this.colorScheme,
    this.showArrow = true,
    super.key,
  });

  @override
  State<ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<ProfileMenuItem>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Set loading state
    setState(() => _isLoading = true);
    _rotationController.repeat();

    try {
      // Execute the callback
      await Future.microtask(() => widget.onTap());
    } finally {
      // Reset loading state if still mounted
      if (mounted) {
        setState(() => _isLoading = false);
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// LEFT: Icon + Text
            Expanded(
              child: Row(
                children: [
                  /// Icon
                  HugeIcon(
                    icon: widget.icon,
                    color: _isLoading
                        ? widget.colorScheme.textSecondary
                        : widget.colorScheme.textPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),

                  /// Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            color: _isLoading
                                ? widget.colorScheme.textSecondary
                                : widget.colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: GoogleFonts.inter(
                              color: widget.colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT: Arrow or Loading
            const SizedBox(width: 12),
            if (_isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: RotationTransition(
                  turns: _rotationController,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.colorScheme.primary,
                    size: 20,
                  ),
                ),
              )
            else if (widget.showArrow)
              Icon(
                Icons.arrow_forward_rounded,
                color: widget.colorScheme.textSecondary.withValues(alpha: 0.5),
                size: 20,
              )
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
