import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/ticket_model.dart';
import '../../data/ticket_repository.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(ref.watch(apiClientProvider));
});

class TicketsState {
  const TicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.isCheckoutLoading = false,
    this.errorMessage,
  });

  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isCheckoutLoading;
  final String? errorMessage;

  TicketsState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isCheckoutLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isCheckoutLoading: isCheckoutLoading ?? this.isCheckoutLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TicketsNotifier extends StateNotifier<TicketsState> {
  TicketsNotifier(this._repository, this._ref) : super(const TicketsState());

  final TicketRepository _repository;
  final Ref _ref;

  Future<void> fetchMyTickets() async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await _repository.getUserTickets(user.id);
      state = state.copyWith(tickets: tickets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<CheckoutResult?> checkout(String eventId, int quantity) async {
    state = state.copyWith(isCheckoutLoading: true, clearError: true);
    try {
      final result = await _repository.checkoutEvent(eventId, quantity);
      if (result.checkoutUrl.isNotEmpty) {
        await _repository.launchCheckoutUrl(result.checkoutUrl);
      }
      state = state.copyWith(isCheckoutLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isCheckoutLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> confirmPayment(String sessionId) async {
    return _repository.confirmPayment(sessionId);
  }

  Future<bool> refund(String ticketId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.refundTicket(ticketId);
      await fetchMyTickets();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final ticketsProvider = StateNotifierProvider<TicketsNotifier, TicketsState>((ref) {
  return TicketsNotifier(ref.watch(ticketRepositoryProvider), ref);
});
