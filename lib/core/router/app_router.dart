import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendee/presentation/screens/attendee_home_screen.dart';
import '../../features/attendee/presentation/screens/event_detail_view.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/two_factor_verify_screen.dart';
import '../../features/events/data/models/event_model.dart';
import '../../features/events/presentation/providers/events_provider.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/organizer/presentation/screens/manage_events_screen.dart';
import '../../features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import '../../features/organizer/presentation/screens/sales_metrics_screen.dart';
import '../../features/organizer/presentation/screens/stands_management_screen.dart';
import '../../features/organizer/presentation/screens/ticket_validation_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final onAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verify-2fa';

      if (authState.status == AuthStatus.checking) return null;

      final isAuthenticated = authState.status == AuthStatus.authenticated;

      if (!isAuthenticated) {
        return onAuthScreen ? null : '/login';
      }

      if (isAuthenticated && onAuthScreen) {
        return authState.isOrganizer ? '/organizer' : '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-2fa',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return TwoFactorVerifyScreen(email: email);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AttendeeHomeScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Organizer routes
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerDashboardScreen(),
      ),
      GoRoute(
        path: '/organizer/create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/organizer/events',
        builder: (context, state) => const ManageEventsScreen(),
      ),
      GoRoute(
        path: '/organizer/sales',
        builder: (context, state) => const SalesMetricsScreen(),
      ),
      GoRoute(
        path: '/organizer/validate',
        builder: (context, state) => const TicketValidationScreen(),
      ),
      GoRoute(
        path: '/organizer/stands',
        builder: (context, state) => const StandsManagementScreen(),
      ),

      // Event detail routes
      GoRoute(
        path: '/event-detail',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventDetailView(event: event);
        },
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) {
          if (state.extra is EventModel) {
            return EventDetailView(event: state.extra as EventModel);
          }
          final eventId = state.pathParameters['id'] ?? '';
          final events = ref.read(eventsProvider).events;
          final found = events.cast<EventModel?>().firstWhere(
                (e) => e?.id == eventId,
                orElse: () => null,
              );
          if (found != null) {
            return EventDetailView(event: found);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Evento')),
            body: const Center(child: Text('Cargando evento...')),
          );
        },
      ),
    ],
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
