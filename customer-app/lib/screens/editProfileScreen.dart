import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/screens/profileMobileOtpVerificationScreen.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String selectedImagePath = "";
  String? _uploadedImageUrl;
  bool _isSubmitting = false;
  String _originalMobileNumber = "";
  bool _isMobileChanged = false;

  @override
  void initState() {
    super.initState();
    // Prefill from session
    nameController.text =
        Constant.session.getData(SessionManager.keyUserName) ?? "";
    _originalMobileNumber =
        Constant.session.getData(SessionManager.keyPhone) ?? "";
    mobileController.text = _originalMobileNumber;
    emailController.text =
        Constant.session.getData(SessionManager.keyEmail) ?? "";
    _uploadedImageUrl =
        Constant.session.getData(SessionManager.keyUserImage);

    // Listen to mobile number changes
    mobileController.addListener(_checkMobileNumberChange);
  }

  void _checkMobileNumberChange() {
    setState(() {
      _isMobileChanged = mobileController.text.trim() != _originalMobileNumber;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getTranslatedValue(context, 'select_image_source'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: getTranslatedValue(context, 'gallery'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: getTranslatedValue(context, 'camera'),
                    colorScheme: colorScheme,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required AppColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GradientBorderCard(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        borderRadius: 18,
        gradient: colorScheme.cardGradient,
        borderGradient: colorScheme.borderGradient,
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.textPrimary,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // image_picker's gallery source uses the system photo picker, which needs
      // no runtime storage/photos permission (Android Photo Picker / iOS handles
      // its own prompt). Gating it behind Permission.photos silently failed on
      // Android 13+, so we call the picker directly like the rest of the app.
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          selectedImagePath = image.path;
        });
      }
    } catch (e) {
      showMessage(context, e.toString(), MessageType.error);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      await hasCameraPermissionGiven(context).then((status) async {
        if (status.isGranted) {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.front,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 80,
          );

          if (image != null) {
            setState(() {
              selectedImagePath = image.path;
            });
          }
        } else if (status.isDenied) {
          await Permission.camera.request();
        } else if (status.isPermanentlyDenied) {
          if (!Constant.session
              .getBoolData(SessionManager.keyPermissionCameraHidePromptPermanently)) {
            _showPermissionDialog(
              title: getTranslatedValue(context, cameraPermissionTitleLabel),
              message: getTranslatedValue(context, cameraPermissionMessageLabel),
              sessionKey: SessionManager.keyPermissionCameraHidePromptPermanently,
            );
          }
        }
      });
    } catch (e) {
      showMessage(context, e.toString(), MessageType.error);
    }
  }

  void _showPermissionDialog({
    required String title,
    required String message,
    required String sessionKey,
  }) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PermissionHandlerBottomSheet(
        titleJsonKey: title,
        messageJsonKey: message,
        sessionKeyForAskNeverShowAgain: sessionKey,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        Map<String, String> params = {
          ApiAndParams.name: nameController.text.trim(),
          ApiAndParams.email: emailController.text.trim(),
          ApiAndParams.mobile: mobileController.text.trim(),
        };

        debugPrint('=== Submit Form Called ===');
        debugPrint('Mobile Changed: $_isMobileChanged');
        debugPrint('Params: $params');

        // If mobile number is changed, trigger OTP verification flow
        if (_isMobileChanged) {
          debugPrint('Mobile number changed, triggering OTP flow');
          await _handleMobileNumberChange(params);
        } else {
          debugPrint('Mobile number not changed, normal update');
          // If mobile number is not changed, just update profile normally
          await context
              .read<UserProfileProvider>()
              .updateUserProfile(
                context: context,
                selectedImagePath: selectedImagePath,
                params: params,
              )
              .then((value) {
            if (value is bool && value) {
              showMessage(
                context,
                getTranslatedValue(context, profileUpdatedSuccessfullyLabel),
                MessageType.success,
              );
              // Return true to indicate profile was updated
              Navigator.pop(context, true);
            } else {
              setState(() {
                _isSubmitting = false;
              });
              showMessage(
                context,
                value.toString(),
                MessageType.error,
              );
            }
          });
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        showMessage(
          context,
          e.toString(),
          MessageType.error,
        );
      }
    }
  }

  Future<void> _handleMobileNumberChange(Map<String, String> params) async {
    try {
      debugPrint('=== Mobile Change Flow Started ===');
      debugPrint('Original Mobile: $_originalMobileNumber');
      debugPrint('New Mobile: ${params[ApiAndParams.mobile]}');

      // Step 1: Send initial request with name, email, mobile (triggers OTP sending)
      Map<String, String> initialParams = {
        ApiAndParams.name: params[ApiAndParams.name] ?? "",
        ApiAndParams.email: params[ApiAndParams.email] ?? "",
        ApiAndParams.mobile: params[ApiAndParams.mobile] ?? "",
      };

      debugPrint('Sending initial request with params: $initialParams');

      // Call API to initiate mobile change (this will send OTP)
      final result = await context
          .read<UserProfileProvider>()
          .updateUserProfile(
            context: context,
            selectedImagePath: "",
            params: initialParams,
          );

      debugPrint('API Response: $result');
      debugPrint('API Response Type: ${result.runtimeType}');

      if (result is bool && result) {
        debugPrint('OTP sent successfully, showing OTP screen');
        // OTP sent successfully, show OTP verification screen
        if (!mounted) return;

        final otp = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileMobileOtpVerificationScreen(
              mobileNumber: params[ApiAndParams.mobile] ?? "",
              profileData: initialParams,
            ),
          ),
        );

        debugPrint('OTP entered: $otp');

        if (otp != null && otp.isNotEmpty) {
          // Step 2: Send final request with OTP
          debugPrint('Submitting profile with OTP');
          await _submitProfileWithOtp(params, otp);
        } else {
          debugPrint('OTP verification cancelled');
          setState(() {
            _isSubmitting = false;
          });
        }
      } else {
        debugPrint('API Response was not successful');
        setState(() {
          _isSubmitting = false;
        });
        showMessage(
          context,
          result.toString(),
          MessageType.error,
        );
      }
    } catch (e) {
      debugPrint('Error in _handleMobileNumberChange: $e');
      setState(() {
        _isSubmitting = false;
      });
      showMessage(
        context,
        e.toString(),
        MessageType.error,
      );
    }
  }

  Future<void> _submitProfileWithOtp(
      Map<String, String> params, String otp) async {
    try {
      // Add OTP to params
      Map<String, String> otpParams = {
        ...params,
        ApiAndParams.otp: otp,
      };

      debugPrint('=== Submit Profile With OTP ===');
      debugPrint('OTP Params: $otpParams');

      // Call API with OTP
      final result = await context
          .read<UserProfileProvider>()
          .updateUserProfile(
            context: context,
            selectedImagePath: selectedImagePath,
            params: otpParams,
          );

      debugPrint('API Response with OTP: $result');
      debugPrint('Response Type: ${result.runtimeType}');

      if (result is bool && result) {
        debugPrint('Profile updated successfully with OTP');
        if (!mounted) return;
        showMessage(
          context,
          getTranslatedValue(context, profileUpdatedSuccessfullyLabel),
          MessageType.success,
        );
        Navigator.pop(context, true);
      } else {
        debugPrint('Profile update failed: $result');
        setState(() {
          _isSubmitting = false;
        });
        showMessage(
          context,
          result.toString(),
          MessageType.error,
        );
      }
    } catch (e) {
      debugPrint('Error in _submitProfileWithOtp: $e');
      setState(() {
        _isSubmitting = false;
      });
      showMessage(
        context,
        e.toString(),
        MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Scaffold(
          backgroundColor: colorScheme.background,
          body: Column(
            children: [
              AppHeader(
                title: getTranslatedValue(context, 'edit_profile'),
                showBackButton: true,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: colorScheme.screenGradient,
                  ),
                  child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildProfileAvatar(colorScheme),
                        const SizedBox(height: 32),
                        _buildFormFields(colorScheme),
                        const SizedBox(height: 32),
                        _buildSubmitButton(colorScheme),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(AppColorScheme colorScheme) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colorScheme.avatarRingGradient,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: selectedImagePath.isNotEmpty
                  ? Image.file(
                      File(selectedImagePath),
                      fit: BoxFit.cover,
                    )
                  : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _uploadedImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: const Color(0xFFE0E0E0),
                            highlightColor: const Color(0xFFF5F5F5),
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => _buildPlaceholder(colorScheme),
                        )
                      : _buildPlaceholder(colorScheme)),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showImageSourceDialog();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: colorScheme.buttonGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                size: 18,
                color: colorScheme.buttonPrimaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(AppColorScheme colorScheme) {
    // Get name from controller or session
    String? name = nameController.text.isNotEmpty
        ? nameController.text
        : Constant.session.getData(SessionManager.keyUserName);

    // Get initial letter
    final initial = _getInitial(name);

    return Container(
      decoration: BoxDecoration(gradient: colorScheme.heroGradient),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.inter(
            color: colorScheme.primaryDark,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
          ),
        ),
      ),
    );
  }

  String _getInitial(String? name) {
    // If name is null or empty, return 'G' for Guest
    if (name == null || name.trim().isEmpty) {
      return 'G';
    }

    // Return first letter of the name, capitalized
    return name.trim()[0].toUpperCase();
  }

  Widget _buildFormFields(AppColorScheme colorScheme) {
    return Column(
      children: [
        CustomTextFormField(
          title: getTranslatedValue(context, 'full_name'),
          hintText: getTranslatedValue(context, 'enter_your_full_name'),
          controller: nameController,
          keyboardType: TextInputType.name,
          prefixIcon: Icon(
            Icons.person_outline,
            size: 20,
            color: colorScheme.iconSecondary,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return getTranslatedValue(context, 'please_enter_your_name');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          title: getTranslatedValue(context, 'mobile_number'),
          hintText: getTranslatedValue(context, 'enter_your_mobile_number'),
          controller: mobileController,
          keyboardType: TextInputType.phone,
          enabled: true,
          prefixIcon: Icon(
            Icons.phone_outlined,
            size: 20,
            color: colorScheme.iconSecondary,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return getTranslatedValue(context, 'please_enter_mobile_number');
            }
            if (value.trim().length < 10) {
              return getTranslatedValue(context, 'please_enter_valid_mobile_number');
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          title: getTranslatedValue(context, 'email_address'),
          hintText: getTranslatedValue(context, 'enter_your_email'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(
            Icons.email_outlined,
            size: 20,
            color: colorScheme.iconSecondary,
          ),
          validator: (value) {
            // Email is required by the backend, so enforce it here too
            // to give an inline error instead of a server-side failure.
            if (value == null || value.trim().isEmpty) {
              return getTranslatedValue(context, 'please_enter_your_email');
            }
            // Basic email validation
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(value.trim())) {
              return getTranslatedValue(context, 'please_enter_valid_email');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 54,
      // Gradient lives on the container; the button itself is transparent so
      // ripple + disabled dimming still come from the Material button.
      decoration: BoxDecoration(
        gradient: colorScheme.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isSubmitting
            ? null
            : [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      foregroundDecoration: _isSubmitting
          ? BoxDecoration(
              color: colorScheme.background.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () {
          HapticFeedback.lightImpact();
          _submitForm();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.buttonPrimaryText,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: colorScheme.buttonPrimaryText.withValues(alpha: 0.8),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: colorScheme.buttonPrimaryText,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                getTranslatedValue(context, 'save_changes'),
                style: GoogleFonts.inter(
                  color: colorScheme.buttonPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.55,
                  height: 1.02,
                ),
              ),
      ),
    );
  }
}
