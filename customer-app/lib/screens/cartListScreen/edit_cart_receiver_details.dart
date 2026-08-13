import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class EditPersonalDetailsBottomSheet extends StatefulWidget {
  final String currentName;
  final String currentPhone;

  const EditPersonalDetailsBottomSheet({
    Key? key,
    required this.currentName,
    required this.currentPhone,
  }) : super(key: key);

  @override
  State<EditPersonalDetailsBottomSheet> createState() =>
      _EditPersonalDetailsBottomSheetState();
}

class _EditPersonalDetailsBottomSheetState
    extends State<EditPersonalDetailsBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  bool _isLoadingContacts = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);

    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text != widget.currentName ||
        _phoneController.text != widget.currentPhone;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Request contacts permission
  Future<bool> _requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Pick contact from phone
  Future<void> _pickContact() async {
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      final hasPermission = await _requestContactsPermission();

      if (!hasPermission) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        setState(() {
          _isLoadingContacts = false;
        });
        return;
      }

      // Show contacts picker bottom sheet
      final selectedContact = await _showContactsPickerBottomSheet();

      if (selectedContact != null && mounted) {
        // Update name
        if (selectedContact.displayName.isNotEmpty) {
          _nameController.text = selectedContact.displayName;
        }

        // Update phone
        if (selectedContact.phones.isNotEmpty) {
          String phone = selectedContact.phones.first.number;
          // Clean phone number - remove all non-digit and non-plus characters
          phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
          // Remove any leading zeros
          phone = phone.replaceFirst(RegExp(r'^0+'), '');
          // If it starts with country code (91), ensure it has +
          if (phone.startsWith('91') && phone.length == 12) {
            phone = '+$phone';
          }
          // If it's just a 10-digit number, add +91
          else if (phone.length == 10 && !phone.startsWith('+')) {
            phone = '+91$phone';
          }
          _phoneController.text = phone;
        }
      }
    } catch (e) {
      if (mounted) {
        final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load contacts: ${e.toString()}'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingContacts = false;
      });
    }
  }

  // Show contacts picker bottom sheet
  Future<Contact?> _showContactsPickerBottomSheet() async {
    // IMPORTANT: Fetch contacts with phone numbers included
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    return await showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactsPickerSheet(contacts: contacts),
    );
  }

  void _showPermissionDeniedDialog() {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          getTranslatedValue(context, 'permission_required'),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.textPrimary,
          ),
        ),
        content: Text(
          getTranslatedValue(context, 'contacts_permission_message'),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              getTranslatedValue(context, 'cancel'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              getTranslatedValue(context, 'open_settings'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslatedValue(context, 'edit_personal_details'),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        getTranslatedValue(context, 'update_name_phone'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textSecondary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.iconSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Form
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Import from Contacts Button
                  GestureDetector(
                    onTap: _isLoadingContacts ? null : _pickContact,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoadingContacts)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          else
                            Icon(
                              Icons.contacts_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          SizedBox(width: 10),
                          Text(
                            _isLoadingContacts
                                ? getTranslatedValue(context, 'loading_contacts')
                                : getTranslatedValue(context, 'import_from_contacts'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Name Field
                  CustomTextFormField(
                    title: getTranslatedValue(context, 'full_name'),
                    hintText: getTranslatedValue(context, 'enter_full_name'),
                    controller: _nameController,
                    prefixIcon: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return getTranslatedValue(context, 'please_enter_name');
                      }
                      if (value.trim().length < 2) {
                        return getTranslatedValue(context, 'name_min_chars');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Phone Field
                  CustomTextFormField(
                    title: getTranslatedValue(context, 'phone_number'),
                    hintText: getTranslatedValue(context, 'phone_placeholder'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 13,
                    prefixIcon: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.phone_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    suffixIcon: GestureDetector(
                      onTap: _isLoadingContacts ? null : _pickContact,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.contact_phone_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return getTranslatedValue(context, 'please_enter_phone');
                      }
                      String cleanPhone = value.replaceAll(' ', '');
                      if (!cleanPhone.startsWith('+91')) {
                        return getTranslatedValue(context, 'phone_must_start_91');
                      }
                      if (cleanPhone.length != 13) {
                        return getTranslatedValue(context, 'phone_must_10_digits');
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _saveChanges : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        disabledBackgroundColor: colorScheme.buttonDisabledBackground,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: _hasChanges ? colorScheme.buttonPrimaryText : colorScheme.buttonDisabledText,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            getTranslatedValue(context, 'save_changes'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _hasChanges ? colorScheme.buttonPrimaryText : colorScheme.buttonDisabledText,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Stateful widget for contacts picker with search
class _ContactsPickerSheet extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactsPickerSheet({required this.contacts});

  @override
  State<_ContactsPickerSheet> createState() => _ContactsPickerSheetState();
}

class _ContactsPickerSheetState extends State<_ContactsPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final phone = contact.phones.isNotEmpty
              ? contact.phones.first.number.toLowerCase()
              : '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.contacts_rounded, color: colorScheme.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getTranslatedValue(context, 'select_contact'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.iconSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: getTranslatedValue(context, 'search_contacts'),
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.iconSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                        },
                        child: Icon(
                          Icons.clear_rounded,
                          color: colorScheme.iconSecondary,
                          size: 20,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.border, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textPrimary,
              ),
            ),
          ),
          // Contact count
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_filteredContacts.length} contact${_filteredContacts.length != 1 ? 's' : ''} found',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          // Contacts List
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: colorScheme.iconSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          getTranslatedValue(context, 'no_contacts_found'),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          getTranslatedValue(context, 'try_different_search'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredContacts.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.border,
                    ),
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final hasPhone = contact.phones.isNotEmpty;

                      return ListTile(
                        enabled: hasPhone,
                        onTap: hasPhone ? () => Navigator.pop(context, contact) : null,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              contact.displayName.isNotEmpty
                                  ? contact.displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.buttonPrimaryText,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: hasPhone ? colorScheme.textPrimary : colorScheme.textDisabled,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),
                        subtitle: hasPhone
                            ? Text(
                                contact.phones.first.number,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textSecondary,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              )
                            : Text(
                                getTranslatedValue(context, 'no_phone_number'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textDisabled,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                        trailing: hasPhone
                            ? Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: colorScheme.iconSecondary,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
