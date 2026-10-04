class TicketModel {
  final String id;
  final String userId;
  final String eventId;
  final String? eventTitle;
  final String status;
  final double price;
  final DateTime purchaseDate;
  final String qrCode;
  final String? shortCode;

  TicketModel({
    required this.id,
    required this.userId,
    required this.eventId,
    this.eventTitle,
    required this.status,
    required this.price,
    required this.purchaseDate,
    required this.qrCode,
    this.shortCode,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String?,
      status: json['status'] as String,
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      qrCode: (json['qrCode'] as String?) ?? json['id'] as String,
      shortCode: json['shortCode'] as String?,
    );
  }
}
