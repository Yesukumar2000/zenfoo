import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:project/helper/styles/typography.dart';
import 'package:project/screens/newHome/dashboard_grid.dart';
import 'package:project/provider/support_contact_provider.dart';

class ShopTypeHomeScreen extends StatefulWidget {
  const ShopTypeHomeScreen({Key? key}) : super(key: key);

  @override
  State<ShopTypeHomeScreen> createState() => _ShopTypeHomeScreenState();
}

class _ShopTypeHomeScreenState extends State<ShopTypeHomeScreen> {
  final _storesGridKey = GlobalKey<StoresGridState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportContactProvider>().fetchSupportContacts();
    });
  }

  void _showSupportDialog() {
    final provider = context.read<SupportContactProvider>();
    final contact = provider.supportContact;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.support_agent_rounded,
                  color: Color(0xFF9AC444), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: provider.state == SupportContactState.loading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF9AC444)),
                ),
              )
            : contact != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Need help? Reach out to our support team through any of the options below.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Phone tile
                      if (contact.phone.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.phone_rounded,
                          label: 'Call Us',
                          value: contact.phone,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('tel:${contact.phone}'));
                          },
                        ),
                      if (contact.phone.isNotEmpty && contact.email.isNotEmpty)
                        SizedBox(height: 12),
                      // Email tile
                      if (contact.email.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.email_rounded,
                          label: 'Email Us',
                          value: contact.email,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('mailto:${contact.email}'));
                          },
                        ),
                    ],
                  )
                : Text(
                    'Unable to load support contacts. Please try again later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9AC444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF9AC444), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  )
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Fixed top section ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9AC444), Colors.white],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: _showSupportDialog,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8FFEB),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Help us',
                                style: AppTypography.bodySmall(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Image.asset(
                    'assets/images/zendo_home.png',
                    width: 120,
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8),
          Text(
            "Choose Your Shop Type",
            textAlign: TextAlign.center,
            style: AppTypography.headingLarge(color: Colors.black),
          ),
          SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "We'll set up the app based on your business — Sweet House or Super Market",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          SizedBox(height: 16),

          // ── Scrollable section with pull-to-refresh ────────────────────
          Expanded(
            child: RefreshIndicator(
              color: Color(0xFF9AC444),
              onRefresh: () async {
                await _storesGridKey.currentState?.refresh();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    StoresGrid(key: _storesGridKey),

                    SizedBox(height: 20),

                    // Franchise row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 204,
                            child: Text(
                              "Want to add your franchise and start selling today?",
                              style: AppTypography.bodyMedium(
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 10),
                              side: BorderSide(color: Color(0xFF9AC444)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add,
                                    size: 16, color: Color(0xFF9AC444)),
                                SizedBox(width: 6),
                                Text(
                                  "Add franchise",
                                  style: AppTypography.bodySmall(
                                    color: Color(0xFF9AC444),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Bottom illustration
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Image.asset(
                          "assets/images/home_bottom.png",
                          width: MediaQuery.of(context).size.width,
                          height: 155,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
