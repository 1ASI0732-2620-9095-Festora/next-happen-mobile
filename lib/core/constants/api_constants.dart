import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;


class ApiConstants {
  ApiConstants._();

  static const String _port = '5000';


  static const String _localNetworkIp = '192.168.1.100';


  static const String _productionUrl = '';


  static const bool _isPhysicalDevice = false;

  static String get baseUrl {
    if (_productionUrl.isNotEmpty) return _productionUrl;

    if (kIsWeb) return 'http://localhost:$_port';

    if (Platform.isAndroid) {
      if (_isPhysicalDevice) return 'http://$_localNetworkIp:$_port';
      return 'http://10.0.2.2:$_port';
    }

    if (Platform.isIOS) {
      if (_isPhysicalDevice) return 'http://$_localNetworkIp:$_port';
      return 'http://localhost:$_port';
    }
    
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://localhost:$_port';
    }

    return 'http://$_localNetworkIp:$_port';
  }

  // Auth (IAM)
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // Events
  static const String eventsPublic = '/api/events/public';
  static const String events = '/api/events';

  // Payments
  static const String checkout = '/api/payments/checkout';

  // Tickets
  static String userTickets(String userId) => '/api/users/$userId/tickets';

  // Engagement
  static String savedEvent(String userId, String eventId) => '/api/users/$userId/saved-events/$eventId';
  static String savedEventsList(String userId) => '/api/users/$userId/saved-events';
  static String eventReviews(String eventId) => '/api/events/$eventId/reviews';

  // Organizer
  static String eventDetail(String eventId) => '/api/events/$eventId';
  static String eventTickets(String eventId) => '/api/events/$eventId/tickets';
  static const String validateTicket = '/api/tickets/validate';
  static String eventSales(String eventId) => '/api/events/$eventId/sales';
}
