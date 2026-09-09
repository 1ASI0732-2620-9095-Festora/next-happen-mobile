class SalesMetricsModel {
  final String eventId;
  final int ticketsSold;
  final int ticketsValidated;
  final int ticketsRefunded;
  final double grossRevenue;
  final double refundedAmount;
  final double netRevenue;
  final List<SalesByDayModel> byDay;

  SalesMetricsModel({
    required this.eventId,
    required this.ticketsSold,
    required this.ticketsValidated,
    required this.ticketsRefunded,
    required this.grossRevenue,
    required this.refundedAmount,
    required this.netRevenue,
    required this.byDay,
  });

  factory SalesMetricsModel.fromJson(Map<String, dynamic> json) {
    return SalesMetricsModel(
      eventId: json['eventId'] as String,
      ticketsSold: json['ticketsSold'] as int,
      ticketsValidated: json['ticketsValidated'] as int,
      ticketsRefunded: json['ticketsRefunded'] as int,
      grossRevenue: (json['grossRevenue'] as num).toDouble(),
      refundedAmount: (json['refundedAmount'] as num).toDouble(),
      netRevenue: (json['netRevenue'] as num).toDouble(),
      byDay: (json['byDay'] as List<dynamic>?)
              ?.map((e) => SalesByDayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SalesByDayModel {
  final String date;
  final int tickets;
  final double revenue;

  SalesByDayModel({
    required this.date,
    required this.tickets,
    required this.revenue,
  });

  factory SalesByDayModel.fromJson(Map<String, dynamic> json) {
    return SalesByDayModel(
      date: json['date'] as String,
      tickets: json['tickets'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}
