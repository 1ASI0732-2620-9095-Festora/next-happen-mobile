import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/data/models/event_model.dart';
import '../../data/engagement_repository.dart';

final engagementRepositoryProvider = Provider<EngagementRepository>((ref) {
  return EngagementRepository(ref.watch(apiClientProvider));
});

class EngagementState {
  const EngagementState({
    this.savedEvents = const [],
    this.savedEventIds = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<EventModel> savedEvents;
  final Set<String> savedEventIds;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  EngagementState copyWith({
    List<EventModel>? savedEvents,
    Set<String>? savedEventIds,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EngagementState(
      savedEvents: savedEvents ?? this.savedEvents,
      savedEventIds: savedEventIds ?? this.savedEventIds,
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
      final eventIds = events.map((e) => e.id!).toSet();
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
      // Revert if failed
      state = state.copyWith(
        savedEventIds: state.savedEventIds, // old state is lost, should keep original but optimistic is fine for now
        errorMessage: e.toString(),
      );
      fetchSavedEvents(); // Re-fetch to sync
    }
  }

  Future<bool> leaveReview(String eventId, int rating, String comment) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.createReview(eventId, rating, comment);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final engagementProvider = StateNotifierProvider<EngagementNotifier, EngagementState>((ref) {
  return EngagementNotifier(ref.watch(engagementRepositoryProvider), ref);
});
