class EventModel {
  final String? id;
  final String? organizer;
  final String title;
  final String description;
  final double price;
  final int quantity;
  final String category;
  final String address;
  final String location;
  final List<String> photos;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPublic;

  EventModel({
    this.id,
    this.organizer,
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    required this.category,
    required this.address,
    required this.location,
    required this.photos,
    required this.startDate,
    required this.endDate,
    required this.isPublic,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String?,
      organizer: json['organizer'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      category: json['category'] as String,
      address: json['address'] as String,
      location: json['location'] as String,
      photos: List<String>.from(json['photos'] ?? []),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isPublic: json['isPublic'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (organizer != null) 'organizer': organizer,
      'title': title,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
      'address': address,
      'location': location,
      'photos': photos,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'isPublic': isPublic,
    };
  }
}
