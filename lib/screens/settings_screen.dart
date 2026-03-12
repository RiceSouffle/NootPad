import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_status_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _hasKey = false;
  bool _obscureKey = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _hasKey = await _settings.hasApiKey();
    if (_hasKey) {
      final key = await _settings.getApiKey();
      _apiKeyController.text = key ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    await _settings.setApiKey(key);
    if (!mounted) return;
    await context.read<AiProvider>().onApiKeyChanged();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _hasKey = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'API key saved!',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _deleteApiKey() async {
    await _settings.deleteApiKey();
    _apiKeyController.clear();
    if (!mounted) return;
    await context.read<AiProvider>().onApiKeyChanged();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _hasKey = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'API key removed',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.textLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAiStatusSection(),
                          const SizedBox(height: 24),
                          _buildApiKeySection(),
                          const SizedBox(height: 24),
                          _buildPrivacySection(),
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
          _buildToolButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Noot Settings',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.textDark.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildAiStatusSection() {
    return Consumer<AiProvider>(
      builder: (context, aiProvider, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 22, color: AppColors.teal),
                const SizedBox(width: 8),
                Text(
                  'Noot AI',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                AiStatusIndicator(
                  backend: aiProvider.activeBackend,
                  compact: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              aiProvider.isAvailable
                  ? 'Noot AI is ready! You can summarize notes, get writing help, auto-categorize, and search with AI.'
                  : 'Add your Anthropic API key below to enable AI features like summarization, writing help, and smart search.',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anthropic API Key',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get your key from console.anthropic.com',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'sk-ant-...',
              hintStyle: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppColors.textLight.withValues(alpha: 0.5),
              ),
              prefixIcon:
                  const Icon(Icons.key_rounded, color: AppColors.textLight, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.textLight,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
              fillColor: AppColors.surfaceWarm,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _saveApiKey,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Save Key',
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
              if (_hasKey) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _deleteApiKey,
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 20),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded,
                  size: 20, color: AppColors.leafGreen),
              const SizedBox(width: 8),
              Text(
                'Privacy',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPrivacyItem(
            icon: Icons.lock_rounded,
            text: 'Your API key is stored securely on this device only',
          ),
          const SizedBox(height: 8),
          _buildPrivacyItem(
            icon: Icons.cloud_off_rounded,
            text: 'Notes are only sent to the AI when you tap an AI action',
          ),
          const SizedBox(height: 8),
          _buildPrivacyItem(
            icon: Icons.storage_rounded,
            text: 'All your notes stay on your device — no cloud sync',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
