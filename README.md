# NootPad

A cozy note-taking app for phones built with Flutter, featuring a warm sandy aesthetic with pastel colors and rounded UI elements.

## Features

- Create, edit, and delete notes
- Pin important notes to the top
- Color-code notes with 8 pastel colors (cream, pink, blue, yellow, green, orange, purple, mint)
- Organize with categories (General, Personal, Work, Ideas, Shopping, Recipes, or custom)
- Search across titles and content
- Filter by category
- Masonry grid layout
- Local SQLite persistence

## Tech Stack

- **Flutter** (Dart)
- **Provider** for state management
- **sqflite** for local database
- **Google Fonts** (Quicksand)
- **flutter_staggered_grid_view** for masonry layout

## Getting Started

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
  main.dart
  models/note.dart
  services/database_service.dart
  providers/notes_provider.dart
  theme/app_theme.dart
  screens/
    home_screen.dart
    edit_note_screen.dart
  widgets/
    note_card.dart
    app_search_bar.dart
    color_picker.dart
    category_chip.dart
    leaf_painter.dart
```
