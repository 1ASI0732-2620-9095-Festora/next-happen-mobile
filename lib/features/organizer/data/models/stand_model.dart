class StandModel {
  final String id;
  final String? eventId;
  final String name;
  final String category;

  StandModel({
    required this.id,
    this.eventId,
    required this.name,
    required this.category,
  });

  factory StandModel.fromJson(Map<String, dynamic> json) {
    return StandModel(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
    };
  }
}
