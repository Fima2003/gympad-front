/// User partial read response model
class UserPartialResponse {
  final String name;
  final String? gymId;

  UserPartialResponse({
    required this.name,
    this.gymId,
  });

  factory UserPartialResponse.fromJson(Map<String, dynamic> json) {
    return UserPartialResponse(
      name: json['name'] as String,
      gymId: json['gymId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gymId': gymId,
    };
  }
}

/// Workout object model (placeholder - should be defined based on your workout structure)
class WorkoutObject {
  // Add workout properties here based on your workout model
  final String? id;
  final String? name;
  final DateTime? createdAt;

  WorkoutObject({
    this.id,
    this.name,
    this.createdAt,
  });

  factory WorkoutObject.fromJson(Map<String, dynamic> json) {
    return WorkoutObject(
      id: json['id'] as String?,
      name: json['name'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

/// User full read response model
class UserFullResponse {
  final String email;
  final String name;
  final String? gymId;
  final WorkoutObject? workouts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLoggedIn;

  UserFullResponse({
    required this.email,
    required this.name,
    this.gymId,
    this.workouts,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoggedIn,
  });

  factory UserFullResponse.fromJson(Map<String, dynamic> json) {
    return UserFullResponse(
      email: json['email'] as String,
      name: json['name'] as String,
      gymId: json['gymId'] as String?,
      workouts: json['workouts'] != null 
          ? WorkoutObject.fromJson(json['workouts'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastLoggedIn: DateTime.parse(json['lastLoggedIn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'gymId': gymId,
      'workouts': workouts?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoggedIn': lastLoggedIn.toIso8601String(),
    };
  }
}

/// User update request model
class UserUpdateRequest {
  final String? name;
  final String? gymId;

  UserUpdateRequest({
    this.name,
    this.gymId,
  });

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserUpdateRequest(
      name: json['name'] as String?,
      gymId: json['gymId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (gymId != null) data['gymId'] = gymId;
    return data;
  }

  /// Validation to ensure at least one parameter is provided
  bool isValid() {
    return name != null || gymId != null;
  }
}
