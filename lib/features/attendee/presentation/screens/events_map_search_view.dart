import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../engagement/presentation/providers/engagement_provider.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/providers/events_provider.dart';

class EventsMapSearchView extends ConsumerStatefulWidget {
  const EventsMapSearchView({super.key});

  @override
  ConsumerState<EventsMapSearchView> createState() =>
      _EventsMapSearchViewState();
}

class _EventsMapSearchViewState extends ConsumerState<EventsMapSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedDateFilter = 'all'; // 'all', 'today', 'weekend', 'week'
  String _viewMode = 'map'; // 'map' | 'list'
  EventModel? _selectedEvent;

  static const LatLng _defaultLimaCenter = LatLng(-12.0464, -77.0428);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(eventsProvider.notifier).fetchPublicEvents();
      ref.read(engagementProvider.notifier).fetchSavedEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventModel> _getFilteredEvents(List<EventModel> allEvents) {
    return allEvents.where((e) {
      // 1. Text search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.address.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q);
        if (!match) return false;
      }

      // 2. Category filter
      if (_selectedCategory != 'all') {
        if (e.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // 3. Date filter
      if (!_filterByDate(e, _selectedDateFilter)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _filterByDate(EventModel event, String dateFilter) {
    if (dateFilter == 'all') return true;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final currentWeekday = now.weekday; // 1 = Lunes ... 7 = Domingo
    final daysUntilSaturday = currentWeekday == 6
        ? 0
        : currentWeekday == 7
            ? -1
            : 6 - currentWeekday;
    final weekendStart = todayStart.add(Duration(days: daysUntilSaturday));
    final weekendEnd = weekendStart.add(const Duration(days: 2));

    final next7DaysEnd = todayStart.add(const Duration(days: 7));

    final evDate = event.startDate;

    if (dateFilter == 'today') {
      return evDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          evDate.isBefore(todayEnd);
    } else if (dateFilter == 'weekend') {
      return evDate.isAfter(weekendStart.subtract(const Duration(seconds: 1))) &&
          evDate.isBefore(weekendEnd);
    } else if (dateFilter == 'week') {
      return evDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          evDate.isBefore(next7DaysEnd);
    }
    return true;
  }

  LatLng _getCoordinates(EventModel event) {
    final loc = event.location;
    if (loc.contains('|')) {
      final parts = loc.split('|');
      final coords = parts[0].split(',');
      if (coords.length == 2) {
        final lat = double.tryParse(coords[0].trim());
        final lng = double.tryParse(coords[1].trim());
        if (lat != null && lng != null && lat != 0 && lng != 0) {
          return LatLng(lat, lng);
        }
      }
    } else if (loc.contains(',')) {
      final coords = loc.split(',');
      if (coords.length == 2) {
        final lat = double.tryParse(coords[0].trim());
        final lng = double.tryParse(coords[1].trim());
        if (lat != null && lng != null && lat != 0 && lng != 0) {
          return LatLng(lat, lng);
        }
      }
    }

    final text = '${event.location} ${event.address}'.toLowerCase();
    if (text.contains('miraflores')) return const LatLng(-12.1217, -77.0297);
    if (text.contains('barranco')) return const LatLng(-12.1489, -77.0206);
    if (text.contains('san isidro')) return const LatLng(-12.0978, -77.0347);
    if (text.contains('surco')) return const LatLng(-12.1389, -76.9936);
    if (text.contains('san miguel')) return const LatLng(-12.0769, -77.0864);
    if (text.contains('magdalena')) return const LatLng(-12.0911, -77.0700);
    if (text.contains('lince')) return const LatLng(-12.0833, -77.0361);
    if (text.contains('jesus maria') || text.contains('jesús maría')) {
      return const LatLng(-12.0739, -77.0483);
    }
    if (text.contains('centro') || text.contains('lima')) {
      return const LatLng(-12.0464, -77.0428);
    }

    final hash = (event.id ?? event.title).hashCode;
    final latOffset = ((hash % 80) - 40) / 1000.0;
    final lngOffset = (((hash ~/ 100) % 80) - 40) / 1000.0;
    return LatLng(-12.0464 + latOffset, -77.0428 + lngOffset);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'all';
      _selectedDateFilter = 'all';
      _selectedEvent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final allEvents = eventsState.events;
    final filteredEvents = _getFilteredEvents(allEvents);

    final rawCategories = allEvents
        .map((e) => e.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    final categories = ['all', ...rawCategories];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Neobrutalist Header & Search Bar
            _buildTopBar(filteredEvents.length),

            // Filter Chips (Date & Category)
            _buildFilterChips(categories),

            // Content: Map or List
            Expanded(
              child: eventsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.black),
                      ),
                    )
                  : _viewMode == 'map'
                      ? _buildMapView(filteredEvents)
                      : _buildListView(filteredEvents),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.black, width: 2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                        _selectedEvent = null;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar ferias, distritos, categorías...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.black,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.black),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedEvent = null;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Mode Switcher: Mapa / Lista
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildSwitchButton(
                      icon: Icons.map,
                      mode: 'map',
                      label: 'Mapa',
                    ),
                    _buildSwitchButton(
                      icon: Icons.list,
                      mode: 'list',
                      label: 'Lista',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchButton({
    required IconData icon,
    required String mode,
    required String label,
  }) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.black,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<String> categories) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Dates Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDateChip('all', 'Todas las fechas'),
                _buildDateChip('today', 'Hoy'),
                _buildDateChip('weekend', 'Fin de semana'),
                _buildDateChip('week', 'Próximos 7 días'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Categories Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final label = cat == 'all' ? 'Todas las categorías' : cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _selectedEvent = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.black
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.black, width: 1.5),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.primaryYellow
                              : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String key, String label) {
    final isSelected = _selectedDateFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDateFilter = key;
            _selectedEvent = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryYellow : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.black, width: 1.5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(List<EventModel> events) {
    final markers = events.map((event) {
      final coords = _getCoordinates(event);
      final isSelected = _selectedEvent?.id == event.id;

      return Marker(
        point: coords,
        width: isSelected ? 48 : 40,
        height: isSelected ? 48 : 40,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedEvent = event;
            });
            _mapController.move(coords, 14.0);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryYellow
                  : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.black,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              size: isSelected ? 28 : 22,
              color: isSelected ? AppColors.black : Colors.redAccent,
            ),
          ),
        ),
      );
    }).toList();

    return Stack(
      children: [
        // FlutterMap with Google Maps Roadmap Tiles
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _defaultLimaCenter,
            initialZoom: 12.0,
            minZoom: 4.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.example.nexthappen',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Map Control Floating Buttons (Top-Right)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapControlBtn(
                icon: Icons.add,
                onTap: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    zoom + 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMapControlBtn(
                icon: Icons.remove,
                onTap: () {
                  final zoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    zoom - 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMapControlBtn(
                icon: Icons.my_location,
                onTap: () {
                  _mapController.move(_defaultLimaCenter, 12.0);
                },
              ),
            ],
          ),
        ),

        // Events count indicator badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.black, width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
              ],
            ),
            child: Text(
              '${events.length} ferias en el mapa',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ),
        ),

        // Selected Event Card Callout at Bottom
        if (_selectedEvent != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildEventMapCallout(_selectedEvent!),
          ),
      ],
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.black),
      ),
    );
  }

  Widget _buildEventMapCallout(EventModel event) {
    final photo = event.photos.isNotEmpty
        ? event.photos.first
        : 'https://placehold.co/400x260?text=NextHappen';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.black, width: 1.5),
              ),
              child: Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.grey,
                  child: const Icon(Icons.event, color: AppColors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: AppColors.black, width: 1),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedEvent = null),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.address.isNotEmpty
                      ? event.address
                      : event.location,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.price > 0
                          ? 'S/. ${event.price.toStringAsFixed(2)}'
                          : 'Gratuito',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/event-detail', extra: event);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: AppColors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                              color: AppColors.black, width: 1.5),
                        ),
                      ),
                      child: const Text(
                        'Ver detalles',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<EventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'No se encontraron ferias con estos filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Prueba cambiando las palabras clave o seleccionando otra fecha.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Limpiar filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.black, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final photo = event.photos.isNotEmpty
            ? event.photos.first
            : 'https://placehold.co/400x260?text=NextHappen';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.black, width: 2),
            boxShadow: const [
              BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
            ],
          ),
          child: InkWell(
            onTap: () => context.push('/event-detail', extra: event),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Header
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.grey,
                        child: const Icon(Icons.event, size: 40),
                      ),
                    ),
                  ),
                ),

                // Card Body
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.black, width: 1.5),
                            ),
                            child: Text(
                              event.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final isSaved = ref
                                  .watch(engagementProvider)
                                  .savedEventIds
                                  .contains(event.id);
                              return IconButton(
                                icon: Icon(
                                  isSaved
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isSaved
                                      ? Colors.red
                                      : AppColors.black,
                                ),
                                onPressed: () {
                                  ref
                                      .read(engagementProvider.notifier)
                                      .toggleSaved(event);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            event.startDate.toString().substring(0, 10),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.address.isNotEmpty
                                  ? event.address
                                  : event.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event.price > 0
                                ? 'S/. ${event.price.toStringAsFixed(2)}'
                                : 'Gratuito',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.push('/event-detail', extra: event);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              foregroundColor: AppColors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                    color: AppColors.black, width: 2),
                              ),
                            ),
                            child: const Text(
                              'Ver más',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
