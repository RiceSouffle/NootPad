import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';

class AiCategorySuggestion extends StatefulWidget {
  final Note? note;
  final String currentTitle;
  final String currentContent;
  final ValueChanged<String> onAccept;

  const AiCategorySuggestion({
    super.key,
    this.note,
    required this.currentTitle,
    required this.currentContent,
    required this.onAccept,
  });

  @override
  State<AiCategorySuggestion> createState() => _AiCategorySuggestionState();
}

class _AiCategorySuggestionState extends State<AiCategorySuggestion> {
  bool _isLoading = false;
  String? _suggestion;

  Future<void> _suggest() async {
    final aiProvider = context.read<AiProvider>();
    if (!aiProvider.isAvailable) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _suggestion = null;
    });

    try {
      // Create a temporary note object for the provider
      final tempNote = Note(
        id: '',
        title: widget.currentTitle,
        content: widget.currentContent,
        contentFormat: 'plain',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await aiProvider.suggestCategory(tempNote);
      if (mounted) {
        setState(() {
          _suggestion = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, aiProvider, _) {
        if (!aiProvider.isAvailable) return const SizedBox.shrink();

        if (_suggestion != null) {
          return _buildSuggestionChip();
        }

        return GestureDetector(
          onTap: _isLoading ? null : _suggest,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: AppColors.teal,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(Icons.auto_awesome_rounded,
                      size: 14, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(
                  _isLoading ? 'Thinking...' : 'Suggest',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _suggestion!,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onAccept(_suggestion!);
              setState(() => _suggestion = null);
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.leafGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 14, color: AppColors.leafGreen),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _suggestion = null);
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.textDark.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
}
