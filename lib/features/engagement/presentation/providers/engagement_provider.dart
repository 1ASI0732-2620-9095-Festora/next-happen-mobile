import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../data/engagement_repository.dart';
import '../../data/models/review_model.dart';

final engagementRepositoryProvider = Provider<EngagementRepository>((ref) {
  return EngagementRepository(ref.watch(apiClientProvider));
});

class EngagementState {
  const EngagementState({
    this.savedEvents = const [],
    this.savedEventIds = const {},
    this.reviewsByEvent = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<EventModel> savedEvents;
  final Set<String> savedEventIds;
  final Map<String, List<ReviewModel>> reviewsByEvent;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  bool isEventSaved(String? eventId) {
    if (eventId == null) return false;
    return savedEventIds.contains(eventId);
  }

  EngagementState copyWith({
    List<EventModel>? savedEvents,
    Set<String>? savedEventIds,
    Map<String, List<ReviewModel>>? reviewsByEvent,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EngagementState(
      savedEvents: savedEvents ?? this.savedEvents,
      savedEventIds: savedEventIds ?? this.savedEventIds,
      reviewsByEvent: reviewsByEvent ?? this.reviewsByEvent,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EngagementNotifier extends StateNotifier<EngagementState> {
  EngagementNotifier(this._repository, this._ref) : super(const EngagementState());

  final EngagementRepository _repository;
  final Ref _ref;

  Future<void> fetchSavedEvents() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final events = await _repository.getSavedEvents(user.id);
      final eventIds = events.where((e) => e.id != null).map((e) => e.id!).toSet();
      state = state.copyWith(
        savedEvents: events,
        savedEventIds: eventIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleSaved(EventModel event) async {
    final user = _ref.read(authProvider).user;
    if (user == null || event.id == null) return;

    final eventId = event.id!;
    final isCurrentlySaved = state.savedEventIds.contains(eventId);
    
    // Optimistic update
    final newIds = Set<String>.from(state.savedEventIds);
    final newEvents = List<EventModel>.from(state.savedEvents);

    if (isCurrentlySaved) {
      newIds.remove(eventId);
      newEvents.removeWhere((e) => e.id == eventId);
    } else {
      newIds.add(eventId);
      newEvents.add(event);
    }
    
    state = state.copyWith(savedEventIds: newIds, savedEvents: newEvents);

    try {
      if (isCurrentlySaved) {
        await _repository.removeSavedEvent(user.id, eventId);
      } else {
        await _repository.saveEvent(user.id, eventId);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
      fetchSavedEvents();
    }
  }

  Future<void> toggleSaveEvent(String? eventId) async {
    if (eventId == null) return;
    final allEvents = _ref.read(eventsProvider).events;
    final event = allEvents.cast<EventModel?>().firstWhere(
          (e) => e?.id == eventId,
          orElse: () => null,
        );
    if (event != null) {
      await toggleSaved(event);
    }
  }

  Future<void> fetchReviews(String? eventId) async {
    if (eventId == null || eventId.isEmpty) return;
    try {
      final reviews = await _repository.getEventReviews(eventId);
      final newMap = Map<String, List<ReviewModel>>.from(state.reviewsByEvent);
      newMap[eventId] = reviews;
      state = state.copyWith(reviewsByEvent: newMap);
    } catch (e) {
      // Ignore or log error
    }
  }

  Future<bool> addReview(String? eventId, int rating, String comment) async {
    if (eventId == null || eventId.isEmpty) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final created = await _repository.createReview(eventId, rating, comment);
      final currentList = state.reviewsByEvent[eventId] ?? [];
      final newMap = Map<String, List<ReviewModel>>.from(state.reviewsByEvent);
      newMap[eventId] = [created, ...currentList];
      state = state.copyWith(
        reviewsByEvent: newMap,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> leaveReview(String eventId, int rating, String comment) async {
    return addReview(eventId, rating, comment);
  }
}

final engagementProvider = StateNotifierProvider<EngagementNotifier, EngagementState>((ref) {
  return EngagementNotifier(ref.watch(engagementRepositoryProvider), ref);
});
