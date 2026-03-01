import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const AppColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: AppColors.noteColorOptions.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = AppColors.noteColorOptions[index];
          final isSelected = entry.key == selectedColor;
          final darkerBorder = HSLColor.fromColor(entry.value)
              .withLightness(
                  (HSLColor.fromColor(entry.value).lightness - 0.15)
                      .clamp(0.0, 1.0))
              .toColor();

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onColorSelected(entry.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: entry.value,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.leafGreen : darkerBorder,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.leafGreen.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.leafGreen,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
