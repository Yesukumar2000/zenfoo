import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/customerSupportScreen/helpChatScreen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _isLoading = true;
  String? _phone;
  String? _email;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSupportContacts();
  }

  Future<void> _loadSupportContacts() async {
    try {
      final raw = await sendApiRequest(
        apiName: '${Constant.hostUrl}api/support-contacts?app=customer',
        isPost: false,
        context: context,
        params: {},
      );

      final res = raw is String ? jsonDecode(raw) : raw;

      if (res != null && res['status'] == 1) {
        final data = res['data'];
        setState(() {
          _phone = data['phone']?.toString();
          _email = data['email']?.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load support contacts';
        });
      }
    } catch (e) {
      debugPrint('Error loading support contacts: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load support contacts';
      });
    }
  }

  Future<void> _launchPhone() async {
    if (_phone == null || _phone!.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: _phone);
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  Future<void> _launchEmail() async {
    if (_email == null || _email!.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: _email);
    try {
      await launchUrl(uri);
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'help_and_support'),
          title: getTranslatedValue(context, 'help_and_support'),
          showBackButton: true,
          onBackPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: colorScheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: colorScheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadSupportContacts();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        getTranslatedValue(context, 'how_can_we_help'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        getTranslatedValue(context, 'choose_support_option'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_phone != null && _phone!.isNotEmpty)
                        _SupportOptionTile(
                          icon: Icons.phone_outlined,
                          title: getTranslatedValue(context, 'call_us'),
                          subtitle: _phone!,
                          colorScheme: colorScheme,
                          onTap: _launchPhone,
                        ),
                      if (_phone != null && _phone!.isNotEmpty)
                        const SizedBox(height: 12),
                      if (_email != null && _email!.isNotEmpty)
                        _SupportOptionTile(
                          icon: Icons.email_outlined,
                          title: getTranslatedValue(context, 'email_us'),
                          subtitle: _email!,
                          colorScheme: colorScheme,
                          onTap: _launchEmail,
                        ),
                      if (_email != null && _email!.isNotEmpty)
                        const SizedBox(height: 12),
                      _SupportOptionTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: getTranslatedValue(context, 'chat_with_us'),
                        subtitle: getTranslatedValue(
                            context, 'chat_with_support_team'),
                        colorScheme: colorScheme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpChatScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SupportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final dynamic colorScheme;

  const _SupportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.border),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: colorScheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
