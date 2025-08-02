class Exercise {
  final String id;
  final String name;
  final String description;
  final String image;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
  });

  factory Exercise.fromJson(String id, Map<String, dynamic> json) {
    return Exercise(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
