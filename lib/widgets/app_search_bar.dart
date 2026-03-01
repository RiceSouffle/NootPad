import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search Noots...',
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.searchBarDecoration,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() => _hasText = value.isNotEmpty);
          widget.onChanged(value);
        },
        style: GoogleFonts.quicksand(
          fontSize: 15,
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.quicksand(
            fontSize: 15,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textLight,
            size: 22,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _hasText = false);
                    widget.onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        ),
      ),
    );
  }
}
