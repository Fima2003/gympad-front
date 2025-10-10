import '../../models/withAdapters/user.dart';
import 'lss.dart';

class UserAuthLocalStorageService extends LSS<User, User> {
  static const String _boxName = 'user_auth_box';
  static const String _key = 'auth';

  UserAuthLocalStorageService() : super(_boxName, defaultKey: _key);

  @override
  User fromDomain(User domain) => domain;
  @override
  User toDomain(User hive) => hive;

  @override
  String getKey(User domain) => _key;
}
