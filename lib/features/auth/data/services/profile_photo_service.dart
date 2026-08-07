import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Photo de profil locale (galerie / caméra).
abstract final class ProfilePhotoService {
  static String _key(String uid) => 'profile_photo_path_$uid';

  static Future<String?> pathFor(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key(uid));
    if (path == null || path.isEmpty) return null;
    if (!File(path).existsSync()) {
      await prefs.remove(_key(uid));
      return null;
    }
    return path;
  }

  static Future<String?> pickAndSave({
    required String uid,
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/avatar_$uid.jpg');
    await File(file.path).copy(dest.path);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(uid), dest.path);
    return dest.path;
  }

  static Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key(uid));
    if (path != null) {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    }
    await prefs.remove(_key(uid));
  }
}
