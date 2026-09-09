import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/event_repository.dart';
import '../../data/models/event_model.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(apiClientProvider));
});

class EventsState {
  const EventsState({
    this.events = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<EventModel> events;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  EventsState copyWith({
    List<EventModel>? events,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EventsNotifier extends StateNotifier<EventsState> {
  EventsNotifier(this._repository) : super(const EventsState());

  final EventRepository _repository;

  Future<void> fetchPublicEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repository.getPublicEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchOrganizerEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repository.getOrganizerEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createEvent(EventModel event) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final newEvent = await _repository.createEvent(event);
      state = state.copyWith(
        events: [...state.events, newEvent],
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  return EventsNotifier(ref.watch(eventRepositoryProvider));
});
