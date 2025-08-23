import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Base class providing convenience helpers for SharedPreferences-backed
/// local storage services. Concrete services should extend this and expose
/// domain specific methods.
abstract class BaseLocalStorageService {
  /// Retrieve a raw string by key. Returns null if missing.
  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Save a raw string value.
  Future<bool> writeString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  /// Remove a key.
  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(key);
  }

  /// Read & decode JSON (object or array). Returns null on error or missing.
  Future<dynamic> readJson(String key) async {
    final raw = await readString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return json.decode(raw);
    } catch (_) {
      // Corrupted json -> remove
      await remove(key);
      return null;
    }
  }

  /// Encode any encodable value to JSON and persist.
  Future<bool> writeJson(String key, Object value) async {
    return writeString(key, json.encode(value));
  }
}
