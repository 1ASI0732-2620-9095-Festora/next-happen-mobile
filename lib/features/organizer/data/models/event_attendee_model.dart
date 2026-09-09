class EventAttendeeModel {
  final String id;
  final double price;
  final DateTime purchaseDate;
  final String shortCode;
  final String status;
  final DateTime? validatedAt;

  EventAttendeeModel({
    required this.id,
    required this.price,
    required this.purchaseDate,
    required this.shortCode,
    required this.status,
    this.validatedAt,
  });

  factory EventAttendeeModel.fromJson(Map<String, dynamic> json) {
    return EventAttendeeModel(
      id: json['id'] as String,
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      shortCode: json['shortCode'] as String,
      status: json['status'] as String,
      validatedAt: json['validatedAt'] != null
          ? DateTime.parse(json['validatedAt'] as String)
          : null,
    );
  }
}
