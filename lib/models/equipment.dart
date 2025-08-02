class Equipment {
  final String id;
  final String type;
  final dynamic data;

  Equipment({
    required this.id,
    required this.type,
    required this.data,
  });

  factory Equipment.fromJson(String id, Map<String, dynamic> json) {
    return Equipment(
      id: id,
      type: json['type'] ?? '',
      data: json['data'] ?? json['exerciseId'],
    );
  }
}
