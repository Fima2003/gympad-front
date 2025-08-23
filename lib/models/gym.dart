class Gym {
  final String id;
  final String name;
  final String image;

  Gym({required this.id, required this.name, required this.image});

  factory Gym.fromJson(String id, Map<String, dynamic> json) {
    return Gym(id: id, name: json['name'] ?? '', image: json['image'] ?? '');
  }
}
