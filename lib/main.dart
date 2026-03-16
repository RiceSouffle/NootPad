import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'providers/ai_provider.dart';
import 'providers/notes_provider.dart';
import 'screens/edit_note_screen.dart';
import 'screens/home_screen.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.surfaceWarm,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Initialize home screen widget support
  await WidgetService.initialize();

  runApp(const NootPadApp());
}

class NootPadApp extends StatefulWidget {
  const NootPadApp({super.key});

  @override
  State<NootPadApp> createState() => _NootPadAppState();
}

class _NootPadAppState extends State<NootPadApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final NotesProvider _notesProvider = NotesProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleWidgetLaunch();
    _listenForWidgetClicks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notesProvider.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload notes from DB in case the widget background callback
      // modified data while the app was in the background.
      _notesProvider.loadNotes();
    }
  }

  /// Check if the app was initially launched from a widget tap.
  Future<void> _handleWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      _handleWidgetUri(uri);
    }
  }

  /// Listen for subsequent widget taps while the app is running.
  void _listenForWidgetClicks() {
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });
  }

  /// Route based on the URI from a widget click.
  void _handleWidgetUri(Uri uri) {
    // Wait for navigator to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;

      if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
        final noteId = uri.pathSegments.first;
        navigator.push(
          MaterialPageRoute(
            builder: (context) => EditNoteScreen(noteId: noteId),
          ),
        );
      } else if (uri.host == 'new') {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const EditNoteScreen(),
          ),
        );
      }
      // 'home' just opens the app — no extra navigation needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notesProvider),
        ChangeNotifierProvider(create: (_) => AiProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'NootPad',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        home: const HomeScreen(),
      ),
    );
  }
}
