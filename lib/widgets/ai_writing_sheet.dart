import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../theme/app_theme.dart';
import 'ai_status_indicator.dart';

void showAiWritingSheet(
  BuildContext context, {
  required String selectedText,
  required Function(String replacement) onReplace,
  required Function(String text) onInsertBelow,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _AiWritingSheet(
      selectedText: selectedText,
      onReplace: onReplace,
      onInsertBelow: onInsertBelow,
    ),
  );
}

class _AiWritingSheet extends StatefulWidget {
  final String selectedText;
  final Function(String replacement) onReplace;
  final Function(String text) onInsertBelow;

  const _AiWritingSheet({
    required this.selectedText,
    required this.onReplace,
    required this.onInsertBelow,
  });

  @override
  State<_AiWritingSheet> createState() => _AiWritingSheetState();
}

class _AiWritingSheetState extends State<_AiWritingSheet> {
  String? _result;
  String? _error;
  bool _isLoading = false;
  WritingAction? _selectedAction;

  Future<void> _runAction(WritingAction action) async {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAction = action;
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final aiProvider = context.read<AiProvider>();
      final result = await aiProvider.assistWriting(
        selectedText: widget.selectedText,
        action: action,
      );
      if (mounted) {
        setState(() {
          _result = result;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
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
            // Title
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 20, color: AppColors.teal),
                const SizedBox(width: 8),
                Text(
                  'Noot Writing Assistant',
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
            // Action buttons
            _buildActionGrid(),
            const SizedBox(height: 16),
            // Result area
            if (_isLoading) _buildLoadingState(),
            if (_error != null) _buildErrorState(),
            if (_result != null) _buildResultState(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          icon: Icons.expand_rounded,
          label: 'Expand',
          action: WritingAction.expand,
        ),
        _buildActionButton(
          icon: Icons.auto_fix_high_rounded,
          label: 'Rewrite',
          action: WritingAction.rewrite,
        ),
        _buildActionButton(
          icon: Icons.compress_rounded,
          label: 'Shorten',
          action: WritingAction.shorten,
        ),
        _buildActionButton(
          icon: Icons.arrow_forward_rounded,
          label: 'Continue',
          action: WritingAction.continueWriting,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required WritingAction action,
  }) {
    final isSelected = _selectedAction == action;
    final isDisabled = _isLoading && !isSelected;

    return GestureDetector(
      onTap: isDisabled ? null : () => _runAction(action),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal.withValues(alpha: 0.15)
              : AppColors.textDark.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.teal.withValues(alpha: 0.4)
                : AppColors.textDark.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? AppColors.teal
                    : (isDisabled
                        ? AppColors.textLight.withValues(alpha: 0.4)
                        : AppColors.textLight)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.teal
                    : (isDisabled
                        ? AppColors.textLight.withValues(alpha: 0.4)
                        : AppColors.textMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.teal,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Noot AI is writing...',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            _error!,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (_selectedAction != null) _runAction(_selectedAction!);
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
      ),
    );
  }

  Widget _buildResultState() {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result preview
          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _result!,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onReplace(_result!);
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Replace',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onInsertBelow(_result!);
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.teal,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Insert Below',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.textDark.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
