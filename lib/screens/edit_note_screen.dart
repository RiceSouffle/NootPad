import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/color_picker.dart';

class EditNoteScreen extends StatefulWidget {
  final String? noteId;

  const EditNoteScreen({super.key, this.noteId});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  static const _maxTitleLength = 500;
  static const _maxCategoryLength = 50;

  late TextEditingController _titleController;
  late QuillController _quillController;
  late TextEditingController _categoryController;
  late ScrollController _editorScrollController;
  late FocusNode _editorFocusNode;
  String _selectedColor = 'cream';
  bool _isNewNote = true;
  Note? _existingNote;
  bool _showCategoryField = false;

  /// Strip dangerous Unicode characters (bidi overrides, zero-width).
  static String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[\u202A-\u202E\u2066-\u2069]'), '')
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .trim();
  }

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
    _quillController = QuillController.basic();
    _categoryController = TextEditingController(text: 'General');
    _editorScrollController = ScrollController();
    _editorFocusNode = FocusNode();

    _attachQuillListener();

    if (widget.noteId != null) {
      _isNewNote = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNote();
      });
    }
  }

  /// Rebuild toolbar when selection/formatting changes.
  void _attachQuillListener() {
    _quillController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _loadNote() {
    final provider = context.read<NotesProvider>();
    try {
      _existingNote = provider.notes.firstWhere((n) => n.id == widget.noteId);
      setState(() {
        _titleController.text = _existingNote!.title;
        _categoryController.text = _existingNote!.category;
        _selectedColor = _existingNote!.color;

        // Load content based on format
        if (_existingNote!.isDelta && _existingNote!.content.isNotEmpty) {
          try {
            final json = jsonDecode(_existingNote!.content) as List;
            final doc = Document.fromJson(json);
            _quillController.dispose();
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
            _attachQuillListener();
          } on FormatException catch (e) {
            debugPrint('Invalid Delta JSON: $e');
            _loadPlainTextContent(_existingNote!.content);
          } catch (e) {
            debugPrint('Error loading Delta content: $e');
            _loadPlainTextContent(_existingNote!.content);
          }
        } else if (_existingNote!.content.isNotEmpty) {
          _loadPlainTextContent(_existingNote!.content);
        }
      });
    } catch (e) {
      debugPrint('Failed to load note: $e');
      Navigator.pop(context);
    }
  }

  void _loadPlainTextContent(String text) {
    final doc = Document()..insert(0, text);
    _quillController.dispose();
    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _attachQuillListener();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _categoryController.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    var title = _sanitize(_titleController.text);
    if (title.length > _maxTitleLength) {
      title = title.substring(0, _maxTitleLength);
    }
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();
    var category = _sanitize(_categoryController.text);
    if (category.isEmpty) category = 'General';
    if (category.length > _maxCategoryLength) {
      category = category.substring(0, _maxCategoryLength);
    }

    if (title.isEmpty && plainText.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final provider = context.read<NotesProvider>();

    if (_isNewNote) {
      await provider.createNote(
        title: title.isEmpty ? 'Untitled' : title,
        content: deltaJson,
        contentFormat: 'delta',
        category: category,
        color: _selectedColor,
      );
    } else if (_existingNote != null) {
      final updated = _existingNote!.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: deltaJson,
        contentFormat: 'delta',
        category: category,
        color: _selectedColor,
        updatedAt: DateTime.now(),
      );
      await provider.updateNote(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _insertImage(ImageSource source) async {
    final imageService = ImageService();
    final savedPath = await imageService.pickAndSaveImage(source);
    if (savedPath != null) {
      final index = _quillController.selection.baseOffset;
      _quillController.document.insert(index, BlockEmbed.image(savedPath));
      _quillController.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Image',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.leafGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.leafGreen),
                ),
                title: Text('Gallery',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                subtitle: Text('Pick from your photos',
                    style: GoogleFonts.quicksand(
                        fontSize: 12, color: AppColors.textLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  _insertImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.teal),
                ),
                title: Text('Camera',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                subtitle: Text('Take a new photo',
                    style: GoogleFonts.quicksand(
                        fontSize: 12, color: AppColors.textLight)),
                onTap: () {
                  Navigator.pop(ctx);
                  _insertImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
              child: Column(
                children: [
                  // Scrollable content area
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
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
                              hintText: 'Noot title...',
                              hintStyle: GoogleFonts.quicksand(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color:
                                    AppColors.textLight.withValues(alpha: 0.5),
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

                          // Quill Editor
                          QuillEditor(
                            controller: _quillController,
                            focusNode: _editorFocusNode,
                            scrollController: _editorScrollController,
                            config: QuillEditorConfig(
                              placeholder: 'Start writing...',
                              padding: EdgeInsets.zero,
                              autoFocus: false,
                              expands: false,
                              customStyles: _buildEditorStyles(),
                              embedBuilders: [
                                _NoteImageEmbedBuilder(),
                              ],
                            ),
                          ),
                          // Extra space at bottom for comfortable editing
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                    ),
                  ),

                  // Formatting toolbar
                  _buildFormattingToolbar(darkerBorder),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DefaultStyles _buildEditorStyles() {
    final baseStyle = GoogleFonts.quicksand(
      fontSize: 16,
      color: AppColors.textMedium,
      height: 1.6,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(4, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        GoogleFonts.quicksand(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(6, 6),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          height: 1.4,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(4, 4),
        const VerticalSpacing(0, 0),
        null,
      ),
      bold: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
      italic: GoogleFonts.quicksand(fontStyle: FontStyle.italic),
      underline: const TextStyle(decoration: TextDecoration.underline),
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      placeHolder: DefaultTextBlockStyle(
        GoogleFonts.quicksand(
          fontSize: 16,
          color: AppColors.textLight.withValues(alpha: 0.5),
          height: 1.6,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      lists: DefaultListBlockStyle(
        baseStyle,
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(4, 4),
        const VerticalSpacing(0, 0),
        null,
        null,
      ),
    );
  }

  Widget _buildFormattingToolbar(Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getNoteColor(_selectedColor),
        border: Border(
          top: BorderSide(
            color: borderColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFormatButton(
            icon: Icons.format_bold_rounded,
            attribute: Attribute.bold,
            tooltip: 'Bold',
          ),
          _buildFormatButton(
            icon: Icons.format_italic_rounded,
            attribute: Attribute.italic,
            tooltip: 'Italic',
          ),
          _buildFormatButton(
            icon: Icons.format_underlined_rounded,
            attribute: Attribute.underline,
            tooltip: 'Underline',
          ),
          _buildFormatButton(
            icon: Icons.format_strikethrough_rounded,
            attribute: Attribute.strikeThrough,
            tooltip: 'Strikethrough',
          ),
          _buildToolbarDivider(),
          _buildFormatButton(
            icon: Icons.title_rounded,
            attribute: Attribute.h1,
            tooltip: 'Heading',
            isBlockLevel: true,
          ),
          _buildFormatButton(
            icon: Icons.format_list_bulleted_rounded,
            attribute: Attribute.ul,
            tooltip: 'Bullets',
            isBlockLevel: true,
          ),
          _buildFormatButton(
            icon: Icons.format_list_numbered_rounded,
            attribute: Attribute.ol,
            tooltip: 'Numbered',
            isBlockLevel: true,
          ),
          _buildFormatButton(
            icon: Icons.checklist_rounded,
            attribute: Attribute.unchecked,
            tooltip: 'Checklist',
            isBlockLevel: true,
          ),
          // Image button (teal circle, visually distinct)
          Tooltip(
            message: 'Add Image',
            child: GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.image_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required Attribute attribute,
    String? tooltip,
    bool isBlockLevel = false,
  }) {
    final style = _quillController.getSelectionStyle();
    final isActive = isBlockLevel
        ? style.containsKey(attribute.key) &&
            style.attributes[attribute.key]?.value == attribute.value
        : style.containsKey(attribute.key);

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: () {
          if (isActive) {
            _quillController.formatSelection(Attribute.clone(attribute, null));
          } else {
            _quillController.formatSelection(attribute);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.leafGreen.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppColors.leafGreen.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.leafGreen : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: AppColors.divider,
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
            _isNewNote ? 'New Noot' : 'Edit Noot',
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

/// Custom embed builder for displaying images in the Quill editor.
class _NoteImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imageUrl = embedContext.node.value.data as String;

    final isLocal =
        imageUrl.startsWith('/') || imageUrl.startsWith('file://');

    // Reject local paths with traversal attempts
    if (isLocal && !ImageService.isSafeLocalPath(imageUrl)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildErrorPlaceholder(),
      );
    }

    final imageWidget = isLocal
        ? Image.file(
            File(imageUrl.replaceFirst('file://', '')),
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stack) => _buildErrorPlaceholder(),
          )
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stack) => _buildErrorPlaceholder(),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      ),
    );
  }

  Widget _buildErrorPlaceholder() => Container(
        height: 100,
        color: AppColors.divider.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(Icons.broken_image_rounded,
              color: AppColors.textLight, size: 32),
        ),
      );
}
