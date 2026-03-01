import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/color_picker.dart';

class EditNoteScreen extends StatefulWidget {
  final String? noteId;

  const EditNoteScreen({super.key, this.noteId});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _categoryController;
  String _selectedColor = 'cream';
  bool _isNewNote = true;
  Note? _existingNote;
  bool _showCategoryField = false;

  final List<String> _defaultCategories = [
    'General',
    'Personal',
    'Work',
    'Ideas',
    'Shopping',
    'Recipes',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _categoryController = TextEditingController(text: 'General');

    if (widget.noteId != null) {
      _isNewNote = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNote();
      });
    }
  }

  void _loadNote() {
    final provider = context.read<NotesProvider>();
    try {
      _existingNote = provider.notes.firstWhere((n) => n.id == widget.noteId);
      setState(() {
        _titleController.text = _existingNote!.title;
        _contentController.text = _existingNote!.content;
        _categoryController.text = _existingNote!.category;
        _selectedColor = _existingNote!.color;
      });
    } catch (_) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final category = _categoryController.text.trim().isEmpty
        ? 'General'
        : _categoryController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final provider = context.read<NotesProvider>();

    if (_isNewNote) {
      await provider.createNote(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        category: category,
        color: _selectedColor,
      );
    } else if (_existingNote != null) {
      final updated = _existingNote!.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        category: category,
        color: _selectedColor,
        updatedAt: DateTime.now(),
      );
      await provider.updateNote(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final noteColor = AppColors.getNoteColor(_selectedColor);
    final darkerBorder = HSLColor.fromColor(noteColor)
        .withLightness(
            (HSLColor.fromColor(noteColor).lightness - 0.08).clamp(0.0, 1.0))
        .toColor();

    return Scaffold(
      backgroundColor: noteColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(darkerBorder),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color picker
                    AppColorPicker(
                      selectedColor: _selectedColor,
                      onColorSelected: (color) {
                        setState(() => _selectedColor = color);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category selector
                    _buildCategorySelector(),
                    const SizedBox(height: 16),

                    // Date display
                    if (!_isNewNote && _existingNote != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Last edited ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(_existingNote!.updatedAt)}',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // Title field
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note title...',
                        hintStyle: GoogleFonts.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                    ),

                    // Divider
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: darkerBorder.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                    // Content field
                    TextField(
                      controller: _contentController,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        color: AppColors.textMedium,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: AppColors.textLight.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      minLines: 10,
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

  Widget _buildTopBar(Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getNoteColor(_selectedColor),
        border: Border(
          bottom: BorderSide(
            color: borderColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          _buildToolButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => _saveNote(),
            tooltip: 'Back & Save',
          ),
          const Spacer(),
          Text(
            _isNewNote ? 'New Note' : 'Edit Note',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          // Save button
          _buildToolButton(
            icon: Icons.check_rounded,
            onTap: _saveNote,
            tooltip: 'Save',
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool highlighted = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.leafGreen.withValues(alpha: 0.15)
                : AppColors.textDark.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlighted
                  ? AppColors.leafGreen.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: highlighted ? AppColors.leafGreen : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showCategoryField = !_showCategoryField),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.textDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textDark.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label_rounded,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 6),
                Text(
                  _categoryController.text.isEmpty
                      ? 'General'
                      : _categoryController.text,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCategoryField
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
        if (_showCategoryField) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _defaultCategories.map((cat) {
              final isSelected = _categoryController.text == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _categoryController.text = cat;
                    _showCategoryField = false;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.leafGreen.withValues(alpha: 0.15)
                        : AppColors.textDark.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.leafGreen.withValues(alpha: 0.4)
                          : AppColors.textDark.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? AppColors.leafGreen : AppColors.textLight,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: TextField(
              controller: _categoryController,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Or type custom category...',
                hintStyle: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: AppColors.textLight.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.textDark.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.textDark.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.leafGreen),
                ),
                fillColor: AppColors.surface,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                isDense: true,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
