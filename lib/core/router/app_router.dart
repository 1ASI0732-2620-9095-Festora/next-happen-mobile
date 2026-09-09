import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendee/presentation/screens/attendee_home_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/organizer/presentation/screens/organizer_dashboard_screen.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final onAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const AttendeeHomeScreen()),
      GoRoute(
        path: '/organizer',
        builder: (context, state) => const OrganizerDashboardScreen(),
      ),
      GoRoute(
        path: '/organizer/create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
    ],
  );
});


class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
