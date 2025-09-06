import 'dart:developer';
import 'package:gympad/services/logger_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_initializer.dart';
import 'adapters/hive_user.dart';

class UserAuthLocalStorageService {
  static const String _boxName = 'user_auth_box';
  static const String _key = 'auth';
  final AppLogger _logger = AppLogger();

  Future<Box<HiveUserAuth>> _box() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(_boxName)
        ? Hive.box<HiveUserAuth>(_boxName)
        : Hive.openBox<HiveUserAuth>(_boxName);
  }

  Future<HiveUserAuth?> load() async {
    try {
      final box = await _box();
      return box.get(_key);
    } catch (e, st) {
      log('UserAuthLocalStorageService.load failed', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> save({
    String? userId,
    String? gymId,
    String? authToken,
    bool? isGuest,
  }) async {
    try {
      final box = await _box();
      _logger.info('Loaded box $box');
      final existing = box.get(_key);
      _logger.info('Existing user auth: $existing');
      final updated = (existing ?? HiveUserAuth()).copyWith(
        userId: userId,
        gymId: gymId,
        authToken: authToken,
        isGuest: isGuest,
      );
      _logger.info('Saving updated user auth: $updated');
      await box.put(_key, updated);
    } catch (e, st) {
      log('UserAuthLocalStorageService.save failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> clear() async {
    try {
      final box = await _box();
      await box.delete(_key);
    } catch (e, st) {
      log('UserAuthLocalStorageService.clear failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
