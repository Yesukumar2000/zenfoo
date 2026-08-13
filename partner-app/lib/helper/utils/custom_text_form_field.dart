import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/styles/typography.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

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
  final List<TextInputFormatter>? inputFormatters;
  final String? initialValue;
  final TextCapitalization? textCapitalization;

  /// Small grey line under the field, shown while there is no error. Use it to
  /// spell out the expected format, e.g. "12 digits, as printed on your card".
  final String? helperText;

  /// Defaults to [AutovalidateMode.onUserInteraction] whenever a [validator]
  /// is supplied, so the vendor sees the problem while typing instead of only
  /// after tapping Next.
  final AutovalidateMode? autovalidateMode;

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
    this.inputFormatters,
    this.initialValue,
    this.textCapitalization,
    this.helperText,
    this.autovalidateMode,
  }) : super(key: key);

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
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

    // Animation setup for smooth focus transitions
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CustomTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(widget.controller, oldWidget.controller)) {
      final oldInternalController = oldWidget.controller == null;
      _controller.removeListener(_onTextChanged);
      if (oldInternalController) {
        _controller.dispose();
      }
      _controller = widget.controller ??
          TextEditingController(text: widget.initialValue);
      _controller.addListener(_onTextChanged);
      _hasText = _controller.text.isNotEmpty;
    }

    if (!identical(widget.focusNode, oldWidget.focusNode)) {
      final oldInternalFocusNode = oldWidget.focusNode == null;
      _focusNode.removeListener(_onFocusChanged);
      if (oldInternalFocusNode) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
      _hasFocus = _focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _animationController.dispose();
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
      // Without a validator there is nothing to re-check, so clear the error
      // as soon as the user types. With a validator the field re-validates
      // itself on every change, so leave _errorText to _validateField.
      if (widget.validator == null && _hasText && _errorText != null) {
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
      if (_hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
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
    if (widget.validator == null) return null;
    final error = widget.validator!(value);
    // With autovalidation the framework runs the validator during build, so
    // the state update has to wait until the frame is done.
    if (error != _errorText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && error != _errorText) {
          setState(() => _errorText = error);
        }
      });
    }
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null && _errorText!.isNotEmpty;
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Title with modern styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.title,
              style: AppTypography.bodyMedium(
                color: hasError
                    ? colorScheme.error
                    : (_hasFocus
                        ? colorScheme.primary
                        : colorScheme.textPrimary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Modern TextFormField with animations
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.surface,
                    boxShadow: _hasFocus && !hasError
                        ? [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ]
                        : hasError
                            ? [
                                BoxShadow(
                                  color:
                                      colorScheme.error.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ]
                            : [],
                  ),
                  child: TextFormField(
                    textCapitalization:
                        widget.textCapitalization ?? TextCapitalization.none,
                    controller: _controller,
                    focusNode: _focusNode,
                    inputFormatters: widget.inputFormatters,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText && _obscurePassword,
                    enabled: widget.enabled,
                    maxLines: widget.obscureText ? 1 : widget.maxLines,
                    maxLength: widget.maxLength,
                    textInputAction: widget.textInputAction,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    onEditingComplete: widget.onEditingComplete,
                    validator: _validateField,
                    autovalidateMode: widget.autovalidateMode ??
                        (widget.validator != null
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled),
                    style: AppTypography.bodyLarge(
                      color: colorScheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: AppTypography.bodyLarge(
                        color: colorScheme.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: hasError
                          ? colorScheme.error.withValues(alpha: 0.05)
                          : (_hasFocus
                              ? colorScheme.surface
                              : colorScheme.cardBackground),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      // Prefix Icon with better spacing
                      prefixIcon: widget.prefixIcon != null
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(left: 16, right: 12),
                              child: IconTheme(
                                data: IconThemeData(
                                  color: _hasFocus
                                      ? colorScheme.primary
                                      : colorScheme.textTertiary,
                                  size: 22,
                                ),
                                child: widget.prefixIcon!,
                              ),
                            )
                          : null,
                      prefixIconConstraints: widget.prefixIcon != null
                          ? const BoxConstraints(minWidth: 50, minHeight: 24)
                          : null,
                      // Suffix Icon
                      suffixIcon: _buildSuffixIcon(),
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 50, minHeight: 24),
                      // Modern Borders with smooth transitions
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              hasError ? colorScheme.error : colorScheme.border,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasError
                              ? colorScheme.error
                              : colorScheme.primary,
                          width: 2.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.error,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.error,
                          width: 2.5,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.border,
                          width: 1.5,
                        ),
                      ),
                      // Remove default error text
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      counterText: '',
                    ),
                  ),
                ),
              );
            },
          ),

          // Modern Error Message with icon and animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: hasError ? null : 0,
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: AppTypography.label(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Format hint — replaced by the error message when the field is wrong
          if (!hasError &&
              widget.helperText != null &&
              widget.helperText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: colorScheme.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.helperText!,
                      style: AppTypography.label(
                        color: colorScheme.textTertiary,
                        fontWeight: FontWeight.w500,
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

  Widget? _buildSuffixIcon() {
    final themeProvider = context.read<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    List<Widget> suffixWidgets = [];

    // Add clear button with modern styling
    if (widget.showClearButton &&
        _hasText &&
        !widget.readOnly &&
        widget.enabled) {
      suffixWidgets.add(
        GestureDetector(
          onTap: _clearText,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.textTertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: colorScheme.textSecondary,
            ),
          ),
        ),
      );
    }

    // Add password toggle with modern styling
    if (widget.obscureText) {
      suffixWidgets.add(
        GestureDetector(
          onTap: _togglePasswordVisibility,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _hasFocus
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.textTertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color:
                  _hasFocus ? colorScheme.primary : colorScheme.textSecondary,
            ),
          ),
        ),
      );
    }

    // Add custom suffix icon
    if (widget.suffixIcon != null) {
      suffixWidgets.add(
        IconTheme(
          data: IconThemeData(
            color: _hasFocus ? colorScheme.primary : colorScheme.textTertiary,
            size: 20,
          ),
          child: widget.suffixIcon!,
        ),
      );
    }

    if (suffixWidgets.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(right: 14),
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
class Example1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      title: 'Land Mark & Area Name',
      hintText: 'Madhapur Police station',
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a landmark';
        }
        return null;
      },
    );
  }
}

// Example 2: Email field with prefix icon
class Example2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      title: 'Email Address',
      hintText: 'Enter your email',
      keyboardType: TextInputType.emailAddress,
      prefixIcon:
          Icon(Icons.email_outlined, size: 20, color: Color(0xFF9E9E9E)),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }
}

// Example 3: Password field
class Example3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      title: 'Password',
      hintText: 'Enter your password',
      obscureText: true,
      prefixIcon: Icon(Icons.lock_outline, size: 20, color: Color(0xFF9E9E9E)),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}

// Example 4: Multi-line text area
class Example4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      title: 'Address',
      hintText: 'Enter your full address',
      maxLines: 4,
      showClearButton: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your address';
        }
        return null;
      },
    );
  }
}

// Example 5: Phone number with custom suffix
class Example5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      title: 'Phone Number',
      hintText: 'Enter phone number',
      keyboardType: TextInputType.phone,
      prefixIcon:
          Icon(Icons.phone_outlined, size: 20, color: Color(0xFF9E9E9E)),
      suffixIcon:
          Icon(Icons.verified_outlined, size: 20, color: Color(0xFF4CAF50)),
      maxLength: 10,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your phone number';
        }
        if (value.length != 10) {
          return 'Phone number must be 10 digits';
        }
        return null;
      },
    );
  }
}
