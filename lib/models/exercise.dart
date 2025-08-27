class Exercise {
  final String id;
  final String name;
  final String description;
  final String image;
  final String muscleGroup;
  final String equipmentId;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.muscleGroup,
    required this.equipmentId,
  });

  factory Exercise.fromJson(String id, Map<String, dynamic> json) {
    return Exercise(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      muscleGroup: json['muscleGroup'] ?? 'general',
      equipmentId: json['equipmentId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'muscleGroup': muscleGroup,
    };
  }
}
