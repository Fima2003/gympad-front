import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// Provides a stable, non-PII device identifier for guest mode linkage.
/// Stored locally; regenerated only if preferences are cleared.
class DeviceIdentityService {
  static final DeviceIdentityService _instance =
      DeviceIdentityService._internal();
  factory DeviceIdentityService() => _instance;
  DeviceIdentityService._internal();

  static const _prefsKey = 'device_id';
  final AppLogger _logger = AppLogger();

  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final newId = _generatePseudoUuid();
    await prefs.setString(_prefsKey, newId);
    _logger.info('Generated new device id');
    return newId;
  }

  String _generatePseudoUuid() {
    final rand = Random();
    // Not a RFC4122 UUID, but sufficiently unique for local device identity.
    final millis = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final randPart =
        List<int>.generate(
          4,
          (_) => rand.nextInt(1 << 16),
        ).map((e) => e.toRadixString(16).padLeft(4, '0')).join();
    return '$millis-$randPart';
  }
}
