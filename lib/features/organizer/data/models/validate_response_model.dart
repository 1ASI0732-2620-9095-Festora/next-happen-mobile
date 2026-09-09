class ValidateResponseModel {
  final bool valid;
  final String message;
  final String ticketId;
  final String eventId;
  final String status;

  ValidateResponseModel({
    required this.valid,
    required this.message,
    required this.ticketId,
    required this.eventId,
    required this.status,
  });

  factory ValidateResponseModel.fromJson(Map<String, dynamic> json) {
    return ValidateResponseModel(
      valid: json['valid'] as bool,
      message: json['message'] as String,
      ticketId: json['ticketId'] as String,
      eventId: json['eventId'] as String,
      status: json['status'] as String,
    );
  }
}
