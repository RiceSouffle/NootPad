import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';
import 'ai_status_indicator.dart';

void showAiSummarySheet(BuildContext context, Note note) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _AiSummarySheet(note: note),
  );
}

class _AiSummarySheet extends StatefulWidget {
  final Note note;
  const _AiSummarySheet({required this.note});

  @override
  State<_AiSummarySheet> createState() => _AiSummarySheetState();
}

class _AiSummarySheetState extends State<_AiSummarySheet> {
  String? _summary;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    try {
      final aiProvider = context.read<AiProvider>();
      final result = await aiProvider.summarize(widget.note);
      if (mounted) {
        setState(() {
          _summary = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_summary != null) {
      Clipboard.setData(ClipboardData(text: _summary!));
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Summary copied!',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.leafGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 2),
          left: BorderSide(color: AppColors.divider, width: 2),
          right: BorderSide(color: AppColors.divider, width: 2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title row
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 20, color: AppColors.teal),
                const SizedBox(width: 8),
                Text(
                  'Noot Summary',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Consumer<AiProvider>(
                  builder: (context, ai, _) => AiStatusIndicator(
                    backend: ai.activeBackend,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            if (_isLoading)
              _buildLoadingState()
            else if (_error != null)
              _buildErrorState()
            else
              _buildSuccessState(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.teal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Summarizing your Noot...',
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _generateSummary();
          },
          child: Text(
            'Retry',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _summary!,
          style: GoogleFonts.quicksand(
            fontSize: 15,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _copyToClipboard,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.leafGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded,
                        size: 16, color: AppColors.leafGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Copy',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.leafGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
