import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:zenfoo_partner/repository/emergency_contact_repository.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class EmergencyContact {
  final int id;
  final String name;
  final String phoneNumber;
  final String? relationship;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile_number': phoneNumber,
      'relation': relationship,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phoneNumber: json['mobile_number'] ?? '',
      relationship: json['relation'],
    );
  }
}

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = false;
  final EmergencyContactRepository _repository = EmergencyContactRepository();
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _repository.getEmergencyContacts();

      debugPrint('Emergency Contacts Response: ${response.data}');

      if (response.data != null) {
        final data = response.data;

        // API returns status: 1 for success
        if (data['status'] == 1 && data['data'] != null) {
          final List<dynamic> contactsList = data['data'];

          setState(() {
            _emergencyContacts = contactsList
                .map((json) => EmergencyContact.fromJson(json))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
      if (mounted) {
        _showSnackBar('Failed to load emergency contacts', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddContactDialog(
      {String? initialName,
      String? initialPhone,
      String? initialRelationship,
      int? editContactId}) async {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController(text: initialPhone);
    String? selectedRelationship = initialRelationship;
    final isEditMode = editContactId != null;
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setPageState) {
              return CustomScaffold(
                backgroundColor: colorScheme.background,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditMode ? 'Edit contact details' : 'Contact details',
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Icon(
                                Icons.close,
                                color: colorScheme.textPrimary,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Contact name
                        CustomTextFormField(
                          controller: nameController,
                          title: 'Contact name',
                          hintText: 'Enter contact',
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 20),

                        // Contact number
                        CustomTextFormField(
                          controller: phoneController,
                          title: 'Contact number',
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          hintText: 'Enter number',
                        ),
                        const SizedBox(height: 20),

                        // Select relationship
                        _buildRelationshipDropdown(
                          colorScheme,
                          selectedRelationship,
                          (value) {
                            setPageState(() {
                              selectedRelationship = value;
                            });
                          },
                        ),

                        const Spacer(),

                        // Save/Update details button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameController.text.isNotEmpty &&
                                    phoneController.text.isNotEmpty) {
                                  Navigator.pop(ctx, {
                                    'name': nameController.text,
                                    'phone': phoneController.text,
                                    'relationship': selectedRelationship ?? '',
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isEditMode ? 'Update details' : 'Save details',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Delete contact button (edit mode only)
                        if (isEditMode)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showDeleteConfirmation(
                                    EmergencyContact(
                                      id: editContactId,
                                      name: initialName ?? '',
                                      phoneNumber: initialPhone ?? '',
                                      relationship: initialRelationship,
                                    ),
                                  );
                                },
                                child: Text(
                                  'Delete contact',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!isEditMode)
                          const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    if (result != null) {
      if (isEditMode) {
        _updateEmergencyContact(
          editContactId,
          result['name']!,
          result['phone']!,
          result['relationship']!.isNotEmpty ? result['relationship'] : null,
        );
      } else {
        _addEmergencyContact(
          result['name']!,
          result['phone']!,
          result['relationship']!.isNotEmpty ? result['relationship'] : null,
        );
      }
    }
  }

  Future<void> _importFromContacts() async {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    try {
      // Request permission
      if (await FlutterContacts.requestPermission()) {
        // Fetch all contacts
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        // Filter contacts with phone numbers
        final contactsWithPhones =
            contacts.where((contact) => contact.phones.isNotEmpty).toList();

        if (!mounted) return;

        if (contactsWithPhones.isEmpty) {
          _showSnackBar('No contacts with phone numbers found', isError: true);
          return;
        }

        // Show contact picker bottom sheet
        final selectedContact = await showModalBottomSheet<Contact>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildContactPickerSheet(
            colorScheme,
            contactsWithPhones,
          ),
        );

        if (selectedContact != null && selectedContact.phones.isNotEmpty) {
          // Re-open add contact dialog with pre-filled data
          await _showAddContactDialog(
            initialName: selectedContact.displayName,
            initialPhone: selectedContact.phones.first.number,
          );
        }
      } else {
        if (!mounted) return;
        _showSnackBar('Permission denied to access contacts', isError: true);
      }
    } catch (e) {
      debugPrint('Error importing contact: $e');
      if (!mounted) return;
      _showSnackBar('Failed to import contact', isError: true);
    }
  }

  Widget _buildContactPickerSheet(
    AppColorScheme colorScheme,
    List<Contact> contacts,
  ) {
    final searchController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setSheetState) {
        final query = searchController.text.toLowerCase();
        final filteredContacts = query.isEmpty
            ? contacts
            : contacts.where((contact) {
                final name = contact.displayName.toLowerCase();
                final phone = contact.phones.isNotEmpty
                    ? contact.phones.first.number.toLowerCase()
                    : '';
                return name.contains(query) || phone.contains(query);
              }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Contact',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.inputBorder,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setSheetState(() {}),
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: context.read<LanguageProvider>().getTranslatedText('search_contacts'),
                      hintStyle: GoogleFonts.inter(
                        color: colorScheme.inputPlaceholder,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          color: colorScheme.iconSecondary,
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 40, minHeight: 24),
                      suffixIcon: searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                searchController.clear();
                                setSheetState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.cancel,
                                  size: 18,
                                  color: colorScheme.iconSecondary,
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: colorScheme.border.withValues(alpha: 0.2),
              ),

              // Contact List
              Expanded(
                child: filteredContacts.isEmpty
                    ? Center(
                        child: Text(
                          'No matching contacts',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        itemCount: filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = filteredContacts[index];
                          final hasPhone = contact.phones.isNotEmpty;
                          final phoneNumber =
                              hasPhone ? contact.phones.first.number : '';

                          return GestureDetector(
                            onTap: () => Navigator.pop(context, contact),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      colorScheme.border.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        contact.displayName.isNotEmpty
                                            ? contact.displayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: GoogleFonts.inter(
                                          color: colorScheme.primary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Contact Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.displayName,
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        if (hasPhone) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            phoneNumber,
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textSecondary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Arrow Icon
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedArrowRight01,
                                    color: colorScheme.iconSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? colorScheme.error : colorScheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _addEmergencyContact(
      String name, String phone, String? relationship) async {
    if (relationship == null || relationship.isEmpty) {
      _showSnackBar('Please select a relationship', isError: true);
      return;
    }

    try {
      final response = await _repository.addEmergencyContact(
        name: name,
        mobileNumber: phone,
        relation: relationship,
      );

      debugPrint('Add Contact Response: ${response.data}');

      if (response.data != null) {
        final data = response.data;

        // API returns status: 1 for success
        if (data['status'] == 1) {
          await _loadEmergencyContacts();
          _showSnackBar(
              data['message'] ?? 'Emergency contact added successfully');
        } else {
          _showSnackBar(data['message'] ?? 'Failed to add contact',
              isError: true);
        }
      } else {
        _showSnackBar('Failed to add emergency contact', isError: true);
      }
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      _showSnackBar('Failed to add emergency contact', isError: true);
    }
  }

  Future<void> _updateEmergencyContact(
      int id, String name, String phone, String? relationship) async {
    if (relationship == null || relationship.isEmpty) {
      _showSnackBar('Please select a relationship', isError: true);
      return;
    }

    try {
      final response = await _repository.updateEmergencyContact(
        id: id,
        name: name,
        mobileNumber: phone,
        relation: relationship,
      );

      debugPrint('Update Contact Response: ${response.data}');

      if (response.data != null) {
        final data = response.data;

        if (data['status'] == 1) {
          await _loadEmergencyContacts();
          _showSnackBar(
              data['message'] ?? 'Emergency contact updated successfully');
        } else {
          _showSnackBar(data['message'] ?? 'Failed to update contact',
              isError: true);
        }
      } else {
        _showSnackBar('Failed to update emergency contact', isError: true);
      }
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      _showSnackBar('Failed to update emergency contact', isError: true);
    }
  }

  Future<void> _deleteContact(int id) async {
    try {
      final response = await _repository.deleteEmergencyContact(id);

      debugPrint('Delete Contact Response: ${response.data}');

      if (response.data != null) {
        final data = response.data;

        // API returns status: 1 for success
        if (data['status'] == 1) {
          await _loadEmergencyContacts();
          _showSnackBar(data['message'] ?? 'Contact removed successfully');
        } else {
          _showSnackBar(data['message'] ?? 'Failed to delete contact',
              isError: true);
        }
      } else {
        _showSnackBar('Failed to delete emergency contact', isError: true);
      }
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      _showSnackBar('Failed to delete emergency contact', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;

    final languageProvider = context.watch<LanguageProvider>();
    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('safety'),
            title: languageProvider.getTranslatedText('emergency_contacts'),
            showBackButton: true,
          ),
          Expanded(
            child: _buildContent(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppColorScheme colorScheme) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildShimmerContactCard(colorScheme);
        },
      );
    }

    if (_emergencyContacts.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = _emergencyContacts[index];
              return _buildContactCard(colorScheme, contact);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: GestureDetector(
            onTap: _showAddContactDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add contact Details',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedUserAdd02,
              color: colorScheme.textPrimary,
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              'Add Emergency Details',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Emergency contact so we can reach someone\nquickly if you need help during delivery.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _showAddContactDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: colorScheme.textPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add contact Details',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
      AppColorScheme colorScheme, EmergencyContact contact) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAddContactDialog(
        initialName: contact.name,
        initialPhone: contact.phoneNumber,
        initialRelationship: contact.relationship,
        editContactId: contact.id,
      ),
      onLongPress: () => _showDeleteConfirmation(contact),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.border.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Contact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.phoneNumber,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.relationship?.isNotEmpty == true
                        ? contact.relationship!
                        : contact.name,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: colorScheme.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    AppColorScheme colorScheme, {
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        color: colorScheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: colorScheme.inputBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.inputBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.inputFocusBorder,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipDropdown(
    AppColorScheme colorScheme,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    final List<String> relationships = [
      'Mother',
      'Father',
      'Spouse',
      'Sibling',
      'Friend',
      'Colleague',
      'Neighbor',
      'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select relationship',
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.55,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.inputBorder,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Select Relationship',
                  style: GoogleFonts.inter(
                    color: colorScheme.inputPlaceholder,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: colorScheme.iconSecondary,
                  size: 20,
                ),
              ),
              dropdownColor: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              items: relationships.map((String relationship) {
                return DropdownMenuItem<String>(
                  value: relationship,
                  child: Text(
                    relationship,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(EmergencyContact contact) {
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: colorScheme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Delete Contact',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Message
              Text(
                'Are you sure you want to remove ${contact.name} from emergency contacts?',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.border.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteContact(contact.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerContactCard(AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar shimmer
          _buildShimmerBox(56, 56, 28, colorScheme),
          const SizedBox(width: 12),

          // Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(150, 16, 4, colorScheme),
                const SizedBox(height: 8),
                _buildShimmerBox(120, 14, 4, colorScheme),
                const SizedBox(height: 4),
                _buildShimmerBox(80, 12, 4, colorScheme),
              ],
            ),
          ),

          // Delete button shimmer
          _buildShimmerBox(40, 40, 20, colorScheme),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(
      double width, double height, double radius, AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceVariant,
                colorScheme.surface,
                colorScheme.surfaceVariant,
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
