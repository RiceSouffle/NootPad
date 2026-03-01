import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/note_card.dart';
import '../widgets/leaf_painter.dart';
import 'edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _openNote(BuildContext context, {String? noteId}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditNoteScreen(noteId: noteId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showNoteOptions(BuildContext context, String noteId) {
    final provider = context.read<NotesProvider>();
    final note = provider.notes.firstWhere((n) => n.id == noteId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 2),
            left: BorderSide(color: AppColors.divider, width: 2),
            right: BorderSide(color: AppColors.divider, width: 2),
          ),
        ),
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            Text(
              note.title.isEmpty ? 'Untitled Noot' : note.title,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: note.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              label: note.isPinned ? 'Unpin Noot' : 'Pin Noot',
              onTap: () {
                provider.togglePin(noteId);
                Navigator.pop(ctx);
              },
            ),
            _buildOptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Noot',
              onTap: () {
                Navigator.pop(ctx);
                _openNote(context, noteId: noteId);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Noot',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, noteId);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppColors.leafGreen).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.leafGreen, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.quicksand(
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textDark,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _confirmDelete(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWarm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.divider, width: 2),
        ),
        title: Text(
          'Delete Noot?',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'This Noot will be gone forever! Are you sure?',
          style: GoogleFonts.quicksand(color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep it',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700,
                color: AppColors.leafGreen,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().deleteNote(noteId);
              Navigator.pop(ctx);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomPaint(
          painter: LeafDecorationPainter(),
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilter(),
              Expanded(child: _buildNotesList()),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () => _openNote(context),
          elevation: 4,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          const AppLeafLogo(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'NootPad',
              style: GoogleFonts.quicksand(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnSand,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Consumer<NotesProvider>(
            builder: (context, provider, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${provider.totalNotes} Noots',
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          AppSearchBar(
            onChanged: (query) {
              context.read<NotesProvider>().setSearchQuery(query);
            },
          ),
          const SizedBox(height: 10),
          Consumer<NotesProvider>(
            builder: (context, provider, _) {
              final categories = provider.categories;
              if (categories.length <= 1) return const SizedBox.shrink();
              return SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return CategoryChip(
                      label: cat,
                      isSelected: provider.selectedCategory == cat,
                      onTap: () => provider.setCategory(cat),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  'Loading Noots...',
                  style: GoogleFonts.quicksand(
                    color: AppColors.textOnSand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.notes.isEmpty) {
          return _buildEmptyState(provider.searchQuery.isNotEmpty);
        }

        return Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(6),
          thickness: 4,
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 4, bottom: 80),
            itemCount: provider.notes.length,
            itemBuilder: (context, index) {
              final note = provider.notes[index];
              return NoteCard(
                note: note,
                onTap: () => _openNote(context, noteId: note.id),
                onLongPress: () => _showNoteOptions(context, note.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LeafIcon(
              size: 64,
              color: AppColors.textOnSand.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No Noots found!' : 'No Noots yet!',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnSand.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Tap + to write your first Noot',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppColors.textOnSand.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
