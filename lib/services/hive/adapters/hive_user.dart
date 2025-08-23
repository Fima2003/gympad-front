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

  HiveUserAuth({this.userId, this.gymId, this.authToken});

  HiveUserAuth copyWith({String? userId, String? gymId, String? authToken}) =>
      HiveUserAuth(
        userId: userId ?? this.userId,
        gymId: gymId ?? this.gymId,
        authToken: authToken ?? this.authToken,
      );
}