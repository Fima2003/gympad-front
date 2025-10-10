import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 5)
class User extends HiveObject {
  @HiveField(0)
  final String? userId;
  @HiveField(1)
  final String? gymId;
  @HiveField(2)
  final String? authToken;
  @HiveField(3)
  final bool isGuest;

  User({this.userId, this.gymId, this.authToken, this.isGuest = false});

  User copyWith({
    String? userId,
    String? gymId,
    String? authToken,
    bool? isGuest,
  }) => User(
    userId: userId ?? this.userId,
    gymId: gymId ?? this.gymId,
    authToken: authToken ?? this.authToken,
    isGuest: isGuest ?? this.isGuest,
  );

  @override
  String toString() =>
      'User(userId: $userId, gymId: $gymId, isGuest: $isGuest)';
}
