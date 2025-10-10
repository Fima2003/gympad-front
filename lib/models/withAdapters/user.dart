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
  @HiveField(4)
  final UserLevel? level;

  User({
    this.userId,
    this.gymId,
    this.authToken,
    this.level,
    this.isGuest = false,
  });

  User copyWith({
    String? userId,
    String? gymId,
    String? authToken,
    UserLevel? level,
    bool? isGuest,
  }) => User(
    userId: userId ?? this.userId,
    gymId: gymId ?? this.gymId,
    authToken: authToken ?? this.authToken,
    level: level ?? this.level,
    isGuest: isGuest ?? this.isGuest,
  );

  @override
  String toString() =>
      'User(userId: $userId, gymId: $gymId, level: $level, isGuest: $isGuest)';
}

@HiveType(typeId: 11)
enum UserLevel {
  @HiveField(0)
  beginner,
  @HiveField(1)
  intermediate,
  @HiveField(2)
  advanced,
}
