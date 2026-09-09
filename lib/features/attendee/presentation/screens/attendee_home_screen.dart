import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'events_catalog_view.dart';
import 'my_tickets_view.dart';
import 'saved_events_view.dart';

class AttendeeHomeScreen extends ConsumerStatefulWidget {
  const AttendeeHomeScreen({super.key});

  @override
  ConsumerState<AttendeeHomeScreen> createState() => _AttendeeHomeScreenState();
}

class _AttendeeHomeScreenState extends ConsumerState<AttendeeHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    EventsCatalogView(),
    SavedEventsView(),
    MyTicketsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('NextHappen', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.black),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.black, width: 2)),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.black,
          unselectedItemColor: AppColors.black.withOpacity(0.5),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Eventos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_activity),
              label: 'Mis Entradas',
            ),
          ],
        ),
      ),
    );
  }
}
