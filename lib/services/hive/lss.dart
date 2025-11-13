import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import '../logger_service.dart';
import 'hive_initializer.dart';

/// Base class for Hive Local Storage Services providing common CRUD operations.
///
/// Type parameters:
/// - [T]: The domain model type (e.g., Exercise, CustomWorkout)
/// - [H]: The Hive adapter type (e.g., HiveExercise, HiveCustomWorkout)
///
/// Supports optional ETag tracking:
/// - If [withEtag] is true, stores a collection-level ETag at key `_etag`
/// - Useful for collections where you track the whole group version, not individual items
/// - Example: Exercises collection has one ETag for the entire list, not per-exercise
///
/// Subclasses must:
/// 1. Provide [boxName] via constructor
/// 2. Implement [fromDomain] to convert domain model to Hive model
/// 3. Implement [toDomain] to convert Hive model to domain model
/// 4. Implement [getKey] to extract the unique key from domain model
///
/// Example:
/// ```dart
/// class ExerciseLss extends LSS<Exercise, HiveExercise> {
///   ExerciseLss() : super('exercises');
///
///   @override
///   HiveExercise fromDomain(Exercise domain) => HiveExercise.fromDomain(domain);
///
///   @override
///   Exercise toDomain(HiveExercise hive) => hive.toDomain();
///
///   @override
///   String getKey(Exercise domain) => domain.id;
/// }
///
/// class ExerciseLss extends LSS<Exercise, HiveExercise> {
///   ExerciseLss() : super('exercises', withEtag: true);
///
///   @override
///   HiveExercise fromDomain(Exercise domain) => HiveExercise.fromDomain(domain);
///
///   @override
///   Exercise toDomain(HiveExercise hive) => hive.toDomain();
///
///   @override
///   String getKey(Exercise domain) => domain.id;
/// }
/// ```
abstract class LSS<T, H> {
  final String boxName;
  final String? defaultKey;
  late final Logger _logger;
  final bool withEtag;

  static const String _etagKey = '_etag';

  LSS(this.boxName, {this.defaultKey, this.withEtag = false}) {
    _logger = AppLogger().createLogger('LSS<$boxName>');
  }

  /// Opens the Hive box for this service, initializing Hive if needed.
  Future<Box<H>> _box() async {
    await HiveInitializer.init();
    return Hive.isBoxOpen(boxName)
        ? Hive.box<H>(boxName)
        : await Hive.openBox<H>(boxName);
  }

  /// Opens the metadata box for storing collection-level info (ETag, etc).
  /// This is separate from the data box to avoid type conflicts.
  Future<Box<dynamic>> _metadataBox() async {
    await HiveInitializer.init();
    final metadataBoxName = '${boxName}_metadata';
    return Hive.isBoxOpen(metadataBoxName)
        ? Hive.box<dynamic>(metadataBoxName)
        : await Hive.openBox<dynamic>(metadataBoxName);
  }

  /// Convert domain model to Hive model. Must be implemented by subclass.
  H fromDomain(T domain);

  /// Convert Hive model to domain model. Must be implemented by subclass.
  T toDomain(H hive);

  /// Extract the unique key from domain model. Must be implemented by subclass.
  dynamic getKey(T domain);

  /// Save a single item to the box.
  Future<void> save(T item) async {
    try {
      final box = await _box();
      final hiveModel = fromDomain(item);
      final key = getKey(item);
      await box.put(key, hiveModel);
      _logger.fine('Saved item with key: $key');
    } catch (e, st) {
      _logger.severe('save failed', e, st);
      rethrow;
    }
  }

  /// Save multiple items to the box.
  Future<void> saveMany(List<T> items) async {
    try {
      final box = await _box();
      final map = <dynamic, H>{};
      for (final item in items) {
        map[getKey(item)] = fromDomain(item);
      }
      await box.putAll(map);
      _logger.fine('Saved ${items.length} items');
    } catch (e, st) {
      _logger.severe('saveMany failed', e, st);
      rethrow;
    }
  }

  /// Get a single item by key.
  Future<T?> get([dynamic key]) async {
    try {
      if (key == null) {
        if (defaultKey != null) {
          key = defaultKey;
        } else {
          throw ArgumentError('Key cannot be null if no defaultKey is set');
        }
      }
      final box = await _box();
      final hiveModel = box.get(key);
      if (hiveModel == null) {
        _logger.fine('Item not found with key: $key');
        return null;
      }
      return toDomain(hiveModel);
    } catch (e, st) {
      _logger.severe('get failed for key: $key', e, st);
      rethrow;
    }
  }

  /// Get all items from the box.
  Future<List<T>> getAll() async {
    try {
      final box = await _box();
      final items = box.values.map((h) => toDomain(h)).toList();
      _logger.fine('Retrieved ${items.length} items');
      return items;
    } catch (e, st) {
      _logger.severe('getAll failed', e, st);
      return []; // Return empty list on error for non-fatal handling
    }
  }

  /// Delete a single item by key.
  Future<void> delete([dynamic key]) async {
    try {
      if (key == null) {
        if (defaultKey != null) {
          key = defaultKey;
        } else {
          throw ArgumentError('Key cannot be null if no defaultKey is set');
        }
      }
      final box = await _box();
      await box.delete(key);
      _logger.fine('Deleted item with key: $key');
    } catch (e, st) {
      _logger.severe('delete failed for key: $key', e, st);
      rethrow;
    }
  }

  /// Delete multiple items by keys.
  Future<void> deleteMany(List<dynamic> keys) async {
    try {
      final box = await _box();
      await box.deleteAll(keys);
      _logger.fine('Deleted ${keys.length} items');
    } catch (e, st) {
      _logger.severe('deleteMany failed', e, st);
      rethrow;
    }
  }

  /// Clear all items from the box.
  Future<void> clear() async {
    try {
      final box = await _box();
      await box.clear();

      // Also clear metadata if ETag tracking is enabled
      if (withEtag) {
        final metadataBox = await _metadataBox();
        await metadataBox.clear();
      }

      _logger.fine('Cleared all items from box');
    } catch (e, st) {
      _logger.severe('clear failed', e, st);
      rethrow;
    }
  }

  /// Check if box contains a key.
  Future<bool> contains(dynamic key) async {
    try {
      final box = await _box();
      return box.containsKey(key);
    } catch (e, st) {
      _logger.severe('contains failed for key: $key', e, st);
      return false;
    }
  }

  /// Update an existing item. Throws if item does not exist.
  Future<void> update({
    dynamic key,
    required T Function(T current) copyWithFn,
  }) async {
    try {
      key ??=
          defaultKey ??
          (throw ArgumentError('Key cannot be null if no defaultKey is set'));

      final box = await _box();
      if (!box.containsKey(key)) {
        throw ArgumentError('Item with key $key does not exist for update');
      }

      final existingHive = box.get(key);
      if (existingHive == null) {
        throw StateError('Existing item for key $key is null');
      }

      final current = toDomain(existingHive as H);
      final updated = copyWithFn(current);
      final hiveModel = fromDomain(updated);

      await box.put(key, hiveModel);
      _logger.fine('Updated item with key: $key');
    } catch (e, st) {
      _logger.severe('update failed', e, st);
      rethrow;
    }
  }

  /// Get the count of items in the box.
  Future<int> count() async {
    try {
      final box = await _box();
      return box.length;
    } catch (e, st) {
      _logger.severe('count failed', e, st);
      return 0;
    }
  }

  /// Get the collection-level ETag (only if [withEtag] is true).
  /// Returns null if ETag is not tracked or has not been set.
  Future<String?> getEtag() async {
    if (!withEtag) return null;
    try {
      final metadataBox = await _metadataBox();
      final etag = metadataBox.get(_etagKey) as String?;
      _logger.fine('Retrieved ETag: $etag');
      return etag;
    } catch (e, st) {
      _logger.severe('getEtag failed', e, st);
      return null;
    }
  }

  /// Set the collection-level ETag (only if [withEtag] is true).
  Future<void> setEtag(String? etag) async {
    if (!withEtag) return;
    try {
      final metadataBox = await _metadataBox();
      if (etag != null) {
        await metadataBox.put(_etagKey, etag);
        _logger.fine('Stored ETag: $etag');
      } else {
        await metadataBox.delete(_etagKey);
        _logger.fine('Cleared ETag');
      }
    } catch (e, st) {
      _logger.severe('setEtag failed', e, st);
      rethrow;
    }
  }
}
