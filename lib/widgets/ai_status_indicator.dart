import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

class AiStatusIndicator extends StatelessWidget {
  final AiBackend backend;
  final bool compact;

  const AiStatusIndicator({
    super.key,
    required this.backend,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label, Color color) = switch (backend) {
      AiBackend.claude => (Icons.cloud_rounded, 'Claude', AppColors.leafGreen),
      AiBackend.none => (Icons.cloud_off_rounded, 'No AI', AppColors.textLight),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 16, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
