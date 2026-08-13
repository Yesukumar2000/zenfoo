import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

class CustomTextFormField extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showClearButton;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool readOnly;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final double? borderRadius;
  final bool autofocus;

  const CustomTextFormField({
    Key? key,
    required this.title,
    required this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.textInputAction,
    this.focusNode,
    this.readOnly = false,
    this.initialValue,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.words,
    this.borderRadius,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late TextEditingController _controller;
  bool _hasText = false;
  bool _hasFocus = false;
  bool _obscurePassword = true;
  String? _errorText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    _obscurePassword = widget.obscureText;

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
      // Clear error when user starts typing
      if (_hasText && _errorText != null) {
        _errorText = null;
      }
    });
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _onFocusChanged() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _clearText() {
    _controller.clear();
    setState(() {
      _hasText = false;
      _errorText = null;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  String? _validateField(String? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() {
        _errorText = error;
      });
      return error;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (widget.title.isNotEmpty) ...[
            Text(
              widget.title,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // TextFormField
          TextFormField(
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText && _obscurePassword,
            enabled: widget.enabled,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            textInputAction: widget.textInputAction,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            onTap: widget.onTap,
            onEditingComplete: widget.onEditingComplete,
            validator: _validateField,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.55,
              height: 1.02,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.inter(
                color: colorScheme.inputPlaceholder,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.55,
                height: 1.02,
              ),
              filled: true,
              fillColor:
                  hasError ? colorScheme.errorBg : colorScheme.inputBackground,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical:
                    widget.maxLines != null && widget.maxLines! > 1 ? 12 : 14,
              ),
              // Prefix Icon
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: widget.prefixIcon,
                    )
                  : null,
              prefixIconConstraints: widget.prefixIcon != null
                  ? const BoxConstraints(minWidth: 40, minHeight: 24)
                  : null,
              // Suffix Icon
              suffixIcon: _buildSuffixIcon(colorScheme),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 24),
              // Borders
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                borderSide: BorderSide(
                  color: hasError ? colorScheme.error : colorScheme.inputBorder,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                borderSide: BorderSide(
                  color: hasError
                      ? colorScheme.error
                      : colorScheme.inputFocusBorder,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
                borderSide: BorderSide(
                  color: colorScheme.borderStrong,
                  width: 1,
                ),
              ),
              // Remove default error text
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              counterText: '',
            ),
          ),
          // Error Text
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 14,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: GoogleFonts.inter(
                        color: colorScheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.55,
                        height: 1.02,
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

  Widget? _buildSuffixIcon(colorScheme) {
    List<Widget> suffixWidgets = [];

    // Add clear button if enabled and has text
    if (widget.showClearButton &&
        _hasText &&
        !widget.readOnly &&
        widget.enabled) {
      suffixWidgets.add(
        GestureDetector(
          onTap: _clearText,
          child: Icon(
            Icons.cancel,
            size: 18,
            color: colorScheme.iconSecondary,
          ),
        ),
      );
    }

    // Add password toggle if obscureText is true
    if (widget.obscureText) {
      suffixWidgets.add(
        GestureDetector(
          onTap: _togglePasswordVisibility,
          child: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: colorScheme.iconSecondary,
          ),
        ),
      );
    }

    // Add custom suffix icon
    if (widget.suffixIcon != null) {
      suffixWidgets.add(widget.suffixIcon!);
    }

    if (suffixWidgets.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: suffixWidgets
            .map((widget) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: widget,
                ))
            .toList(),
      ),
    );
  }
}

// USAGE EXAMPLES:

// Example 1: Basic text field
// CustomTextFormField(
//   title: 'Land Mark & Area Name',
//   hintText: 'Madhapur Police station',
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter a landmark';
//     }
//     return null;
//   },
// )

// Example 2: Email field with prefix icon
// CustomTextFormField(
//   title: 'Email Address',
//   hintText: 'Enter your email',
//   keyboardType: TextInputType.emailAddress,
//   prefixIcon: Icon(Icons.email_outlined, size: 20),
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter your email';
//     }
//     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//       return 'Please enter a valid email';
//     }
//     return null;
//   },
// )

// Example 3: Password field
// CustomTextFormField(
//   title: 'Password',
//   hintText: 'Enter your password',
//   obscureText: true,
//   prefixIcon: Icon(Icons.lock_outline, size: 20),
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter your password';
//     }
//     if (value.length < 6) {
//       return 'Password must be at least 6 characters';
//     }
//     return null;
//   },
// )

// Example 4: Multi-line text area
// CustomTextFormField(
//   title: 'Address',
//   hintText: 'Enter your full address',
//   maxLines: 4,
//   showClearButton: true,
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter your address';
//     }
//     return null;
//   },
// )

// Example 5: Phone number with custom suffix
// CustomTextFormField(
//   title: 'Phone Number',
//   hintText: 'Enter phone number',
//   keyboardType: TextInputType.phone,
//   prefixIcon: Icon(Icons.phone_outlined, size: 20),
//   suffixIcon: Icon(Icons.verified_outlined, size: 20),
//   maxLength: 10,
//   validator: (value) {
//     if (value == null || value.isEmpty) {
//       return 'Please enter your phone number';
//     }
//     if (value.length != 10) {
//       return 'Phone number must be 10 digits';
//     }
//     return null;
//   },
// )
