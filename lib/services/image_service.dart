import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Get the directory where note images are stored.
  Future<Directory> get imageDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'note_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Validate that an image path is within the app's note_images directory.
  Future<bool> isValidImagePath(String path) async {
    try {
      final dir = await imageDir;
      final cleaned = path.replaceFirst('file://', '');
      if (cleaned.contains('..')) return false;
      final canonical = File(cleaned).absolute.path;
      return canonical.startsWith(dir.path);
    } catch (e) {
      debugPrint('Image path validation failed: $e');
      return false;
    }
  }

  /// Quick synchronous check for obviously unsafe paths (path traversal).
  static bool isSafeLocalPath(String path) {
    final cleaned = path.replaceFirst('file://', '');
    if (cleaned.contains('..')) return false;
    if (!cleaned.startsWith('/')) return false;
    return true;
  }

  /// Pick an image from gallery or camera.
  Future<File?> pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Save an image to the app's local storage and return the saved path.
  Future<String> saveImage(File image) async {
    final dir = await imageDir;
    final ext = p.extension(image.path).isNotEmpty ? p.extension(image.path) : '.jpg';
    final filename = '${_uuid.v4()}$ext';
    final savedFile = await image.copy(p.join(dir.path, filename));
    return savedFile.path;
  }

  /// Pick and save an image in one step. Returns the saved path or null.
  Future<String?> pickAndSaveImage(ImageSource source) async {
    final image = await pickImage(source);
    if (image == null) return null;
    return await saveImage(image);
  }

  /// Delete an image file by path.
  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
