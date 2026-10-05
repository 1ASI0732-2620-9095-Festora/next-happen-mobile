import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'events_catalog_view.dart';
import 'events_map_search_view.dart';
import 'my_tickets_view.dart';
import 'saved_events_view.dart';

class AttendeeTabs {
  static const int catalog = 0;
  static const int map = 1;
  static const int saved = 2;
  static const int tickets = 3;
  static const int notifications = 4;
  static const int profile = 5;
}

final attendeeTabProvider = StateProvider<int>((ref) => AttendeeTabs.catalog);

class AttendeeHomeScreen extends ConsumerWidget {
  const AttendeeHomeScreen({super.key});

  static const List<Widget> _views = [
    EventsCatalogView(),
    EventsMapSearchView(),
    SavedEventsView(),
    MyTicketsView(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(attendeeTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: currentIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.black, width: 2)),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) => ref.read(attendeeTabProvider.notifier).state = index,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.black,
          unselectedItemColor: Colors.black.withValues(alpha: 0.45),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number),
              label: 'Entradas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alertas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
