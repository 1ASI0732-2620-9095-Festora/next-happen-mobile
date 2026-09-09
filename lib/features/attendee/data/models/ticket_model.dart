class TicketModel {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final double price;
  final DateTime purchaseDate;
  final String qrCode;

  TicketModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.price,
    required this.purchaseDate,
    required this.qrCode,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      status: json['status'] as String,
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      qrCode: json['qrCode'] as String,
    );
  }
}
