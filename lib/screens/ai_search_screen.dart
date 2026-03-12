import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_status_indicator.dart';
import '../widgets/leaf_painter.dart';

class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  final TextEditingController _questionController = TextEditingController();
  String? _answer;
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _answer = null;
      _error = null;
    });

    try {
      final aiProvider = context.read<AiProvider>();
      final notesProvider = context.read<NotesProvider>();
      final result = await aiProvider.askQuestion(
        question: question,
        notes: notesProvider.notes,
      );
      if (mounted) {
        setState(() {
          _answer = result;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildQuestionInput(),
                    const SizedBox(height: 20),
                    if (_isLoading) _buildLoadingState(),
                    if (_error != null) _buildErrorState(),
                    if (_answer != null) _buildAnswerCard(),
                    if (!_isLoading && _answer == null && _error == null)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.textDark.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 22, color: AppColors.textDark),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.teal),
              const SizedBox(width: 6),
              Text(
                'Ask Noot AI',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      decoration: AppDecorations.searchBarDecoration,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Ask about your Noots...',
                hintStyle: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: AppColors.textLight.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textLight, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _askQuestion(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _isLoading ? null : _askQuestion,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isLoading ? AppColors.textLight : AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.teal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Noot AI is thinking...',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppColors.textOnSand,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
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
            onTap: _askQuestion,
            child: Text(
              'Try again',
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

  Widget _buildAnswerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.teal),
              const SizedBox(width: 6),
              Text(
                'Answer',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
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
          const SizedBox(height: 12),
          Text(
            _answer!,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          LeafIcon(
            size: 56,
            color: AppColors.textOnSand.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me anything about your Noots!',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnSand.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I\'ll search through all your notes to find the answer',
            style: GoogleFonts.quicksand(
              fontSize: 13,
              color: AppColors.textOnSand.withValues(alpha: 0.35),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
