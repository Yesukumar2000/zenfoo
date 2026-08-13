import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/provider/noteProductsProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/provider/notesProvider.dart';
import 'package:project/models/userNote.dart';
import 'package:project/screens/notes/noteSearchScreen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({Key? key}) : super(key: key);

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _editNoteController = TextEditingController();
  String? _editingNoteId;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      context.read<NotesProvider>().getAllNotes(context: context);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _editNoteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isNotEmpty) {
      bool success = await context.read<NotesProvider>().addNote(
            context: context,
            noteText: _noteController.text.trim(),
          );

      if (success) {
        _noteController.clear();
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _removeNote(String noteId) async {
    bool success = await context
        .read<NotesProvider>()
        .deleteNote(context: context, noteId: noteId);

    if (success) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _toggleNoteSelection(
      String noteId, bool currentSelection) async {
    bool success = await context.read<NotesProvider>().toggleNoteSelection(
          context: context,
          noteId: noteId,
          isSelected: !currentSelection,
        );

    if (success) {
      HapticFeedback.lightImpact();
    }
  }

  void _startEditing(UserNote note) {
    setState(() {
      _editingNoteId = note.id;
      _editNoteController.text = note.noteText ?? '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingNoteId = null;
      _editNoteController.clear();
    });
  }

  Future<void> _saveNoteEdit(String noteId) async {
    if (_editNoteController.text.trim().isNotEmpty) {
      bool success = await context.read<NotesProvider>().updateNote(
            context: context,
            noteId: noteId,
            noteText: _editNoteController.text.trim(),
          );

      if (success) {
        _cancelEdit();
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // App Header
          AppHeader(
            label: getTranslatedValue(context, 'notes_section_label'),
            title: getTranslatedValue(context, 'list_out_grocery_items_title'),
            showBackButton: true,
          ),

          // Content
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, notesProvider, child) {
                if (notesProvider.notesState == NotesState.loading &&
                    !notesProvider.isDataLoaded) {
                  return _buildLoadingShimmer(colorScheme);
                }

                if (notesProvider.notesState == NotesState.error &&
                    !notesProvider.isDataLoaded) {
                  return _buildErrorState(colorScheme, notesProvider.message);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Input field with example text
                      Text(
                        getTranslatedValue(context, 'example_note_text'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.55,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Custom Text Form Field with loading indicator
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              title: 'Note',
                              hintText: getTranslatedValue(
                                  context, 'note_input_hint'),
                              controller: _noteController,
                              maxLines: 1,
                              showClearButton: true,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: _addNote,
                              enabled: !notesProvider.isAdding,
                            ),
                          ),
                          if (notesProvider.isAdding) ...[
                            const SizedBox(width: 12),
                            Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Added note list header
                      if (notesProvider.notes.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              getTranslatedValue(
                                  context, 'added_note_list_header'),
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.55,
                                height: 1.02,
                              ),
                            ),
                            Text(
                              '${notesProvider.getSelectedCount()} ${getTranslatedValue(context, 'items_add_suffix')}',
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.55,
                                height: 1.02,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Notes list
                      ...notesProvider.notes.map((note) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildNoteCard(note, colorScheme),
                        );
                      }).toList(),

                      // Empty state
                      if (notesProvider.notes.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.note_add_outlined,
                                  size: 64,
                                  color: colorScheme.textSecondary
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  getTranslatedValue(
                                      context, 'no_notes_yet_title'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getTranslatedValue(
                                      context, 'add_first_note_message'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary
                                        .withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom button
          Consumer<NotesProvider>(
            builder: (context, notesProvider, child) {
              // Show Add button when keyboard is visible
              if (_isKeyboardVisible) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.border,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: notesProvider.isAdding ? null : _addNote,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: notesProvider.isAdding
                              ? colorScheme.primary.withValues(alpha: 0.5)
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: notesProvider.isAdding
                            ? Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.buttonPrimaryText,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                getTranslatedValue(context, 'add_note_button'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: colorScheme.buttonPrimaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.55,
                                  height: 1.02,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }

              // Show "Let's Build your cart" button when keyboard is hidden and there are selected notes
              if (notesProvider.notes.isNotEmpty &&
                  notesProvider.getSelectedCount() > 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.border,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(
                                  create: (context) => NoteProductsProvider(),
                                )
                              ],
                              child: NoteSearchScreen(
                                notesList: notesProvider.getSelectedNotesText(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          getTranslatedValue(context, 'build_your_cart_button'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: colorScheme.buttonPrimaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(UserNote note, colorScheme) {
    final notesProvider = context.watch<NotesProvider>();
    final isDeleting = notesProvider.deletingNoteId == note.id;
    final isToggling = notesProvider.togglingNoteId == note.id;
    final isEditing = _editingNoteId == note.id;

    return Opacity(
      opacity: isDeleting ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: note.isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.border,
            width: 1,
          ),
          boxShadow: note.isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Edit Button (Left)
            if (!isEditing)
              GestureDetector(
                onTap: () => _startEditing(note),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: colorScheme.textSecondary,
                    size: 16,
                  ),
                ),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 12),

            // Note text / TextField (Expanded)
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: _editNoteController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.55,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _saveNoteEdit(note.id!),
                    )
                  : Text(
                      note.noteText ?? '',
                      style: GoogleFonts.inter(
                        color: note.isSelected
                            ? colorScheme.textPrimary
                            : colorScheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.55,
                        height: 1.02,
                        decoration: note.isSelected
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Action Buttons Grouped on Right
            if (isEditing) ...[
              // Save Button (Tick)
              GestureDetector(
                onTap: () => _saveNoteEdit(note.id!),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: colorScheme.buttonPrimaryText,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Cancel Button (Close)
              GestureDetector(
                onTap: _cancelEdit,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: colorScheme.error,
                    size: 16,
                  ),
                ),
              ),
            ] else ...[
              // Selection toggle button
              GestureDetector(
                onTap: () => _toggleNoteSelection(note.id!, note.isSelected),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: note.isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: note.isSelected
                          ? colorScheme.primary
                          : colorScheme.border,
                      width: 1.5,
                    ),
                  ),
                  child: note.isSelected
                      ? Icon(
                          Icons.check,
                          color: colorScheme.buttonPrimaryText,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Delete button
              GestureDetector(
                onTap: () => _removeNote(note.id!),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: colorScheme.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(colorScheme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return CustomShimmer(
          height: 50,
          width: double.infinity,
          borderRadius: 12,
        );
      },
    );
  }

  Widget _buildErrorState(colorScheme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              getTranslatedValue(context, 'failed_load_notes_error'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.55,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.55,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<NotesProvider>().getAllNotes(context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.buttonPrimaryText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                getTranslatedValue(context, 'retry_button'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
