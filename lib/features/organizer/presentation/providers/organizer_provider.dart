import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/event_attendee_model.dart';
import '../../data/models/sales_metrics_model.dart';
import '../../data/models/stand_model.dart';
import '../../data/models/validate_response_model.dart';
import '../../data/organizer_repository.dart';

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  return OrganizerRepository(ref.watch(apiClientProvider));
});

// --- Stands State & Notifier ---

class StandsState {
  const StandsState({
    this.stands = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<StandModel> stands;
  final bool isLoading;
  final String? errorMessage;

  StandsState copyWith({
    List<StandModel>? stands,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StandsState(
      stands: stands ?? this.stands,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StandsNotifier extends StateNotifier<StandsState> {
  StandsNotifier(this._repository) : super(const StandsState());

  final OrganizerRepository _repository;

  Future<void> fetchStands(String eventId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getStands(eventId);
      state = state.copyWith(stands: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createStand(String eventId, StandModel stand) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repository.createStand(eventId, stand);
      state = state.copyWith(
        stands: [...state.stands, created],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateStand(String standId, StandModel stand) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateStand(standId, stand);
      state = state.copyWith(
        stands: state.stands.map((s) => s.id == standId ? updated : s).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteStand(String standId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteStand(standId);
      state = state.copyWith(
        stands: state.stands.where((s) => s.id != standId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final standsProvider = StateNotifierProvider<StandsNotifier, StandsState>((ref) {
  return StandsNotifier(ref.watch(organizerRepositoryProvider));
});

// --- Sales Metrics State & Notifier ---

class SalesMetricsState {
  const SalesMetricsState({
    this.metrics,
    this.isLoading = false,
    this.errorMessage,
  });

  final SalesMetricsModel? metrics;
  final bool isLoading;
  final String? errorMessage;

  SalesMetricsState copyWith({
    SalesMetricsModel? metrics,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SalesMetricsState(
      metrics: metrics ?? this.metrics,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SalesMetricsNotifier extends StateNotifier<SalesMetricsState> {
  SalesMetricsNotifier(this._repository) : super(const SalesMetricsState());

  final OrganizerRepository _repository;

  Future<void> fetchMetrics(String eventId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final metrics = await _repository.getEventSales(eventId);
      state = state.copyWith(metrics: metrics, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final salesMetricsProvider =
    StateNotifierProvider<SalesMetricsNotifier, SalesMetricsState>((ref) {
  return SalesMetricsNotifier(ref.watch(organizerRepositoryProvider));
});

// --- Ticket Validation State & Notifier ---

class ValidationState {
  const ValidationState({
    this.attendees = const [],
    this.lastResult,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<EventAttendeeModel> attendees;
  final ValidateResponseModel? lastResult;
  final bool isLoading;
  final String? errorMessage;

  ValidationState copyWith({
    List<EventAttendeeModel>? attendees,
    ValidateResponseModel? lastResult,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ValidationState(
      attendees: attendees ?? this.attendees,
      lastResult: lastResult ?? this.lastResult,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ValidationNotifier extends StateNotifier<ValidationState> {
  ValidationNotifier(this._repository) : super(const ValidationState());

  final OrganizerRepository _repository;

  Future<void> fetchAttendees(String eventId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getEventAttendees(eventId);
      state = state.copyWith(attendees: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<ValidateResponseModel?> validateTicket(String qrCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.validateTicket(qrCode);
      state = state.copyWith(lastResult: result, isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

final validationProvider =
    StateNotifierProvider<ValidationNotifier, ValidationState>((ref) {
  return ValidationNotifier(ref.watch(organizerRepositoryProvider));
});
