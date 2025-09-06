import 'package:hive/hive.dart';

part 'hive_user.g.dart';

@HiveType(typeId: 5)
class HiveUserAuth extends HiveObject {
  @HiveField(0)
  final String? userId;
  @HiveField(1)
  final String? gymId;
  @HiveField(2)
  final String? authToken;
  @HiveField(3)
  final bool isGuest;

  HiveUserAuth({this.userId, this.gymId, this.authToken, this.isGuest = false});

  HiveUserAuth copyWith({
    String? userId,
    String? gymId,
    String? authToken,
    bool? isGuest,
  }) => HiveUserAuth(
    userId: userId ?? this.userId,
    gymId: gymId ?? this.gymId,
    authToken: authToken ?? this.authToken,
    isGuest: isGuest ?? this.isGuest,
  );

  @override
  String toString() =>
      'HiveUserAuth(userId: $userId, gymId: $gymId, isGuest: $isGuest)';
}
