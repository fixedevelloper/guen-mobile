import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/payment_request.dart';
import '../../../../core/models/payment_result.dart';
import '../../data/datasources/booking_api_client.dart';
import '../../data/models/checkout_request_dto.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingFlowState> {
  final BookingApiClient _apiClient;

  BookingCubit(this._apiClient) : super(const BookingFlowState());

  Future<void> submitCheckout(CheckoutRequestDto request) async {
    emit(state.copyWith(status: BookingStatus.checkingOut));
    try {
      final booking = await _apiClient.checkout(request);
      emit(state.copyWith(status: BookingStatus.awaitingPayment, booking: booking));
    } catch (e) {
      emit(state.copyWith(
        status: BookingStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> submitPayment(PaymentRequest request) async {
    emit(state.copyWith(status: BookingStatus.payingNow, errorMessage: null));
    try {
      final result = await _apiClient.pay(request);
      _applyPaymentResult(result);
    } catch (e) {
      emit(state.copyWith(
        status: BookingStatus.awaitingPayment,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Polling déclenché par l'écran d'attente Mobile Money (statut
  /// paymentPending).
  Future<void> refreshPaymentStatus() async {
    final paymentId = state.paymentResult?.paymentId;
    final email = state.booking?.contactEmail;
    if (paymentId == null || paymentId.isEmpty || email == null || email.isEmpty) return;

    try {
      final result = await _apiClient.getPaymentStatus(paymentId, email);
      _applyPaymentResult(result);
    } catch (_) {
      // Échec silencieux : un tick de polling raté n'est pas une erreur à
      // afficher, le prochain tick réessaiera.
    }
  }

  Future<void> submitCardAuthorization(String code) async {
    final paymentId = state.paymentResult?.paymentId;
    if (paymentId == null || paymentId.isEmpty) return;

    emit(state.copyWith(status: BookingStatus.payingNow, errorMessage: null));
    try {
      final result = await _apiClient.submitCardAuthorization(paymentId, code);
      _applyPaymentResult(result);
    } catch (e) {
      emit(state.copyWith(
        status: BookingStatus.paymentPendingAuthorization,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Traduit un PaymentResult (initial, polling ou après authentification
  /// carte) en transition d'état — même branchement quel que soit l'appel
  /// qui l'a produit.
  void _applyPaymentResult(PaymentResult result) {
    if (result.isSucceeded) {
      emit(state.copyWith(status: BookingStatus.succeeded, paymentResult: result));
    } else if (result.isPendingAuthorization) {
      emit(state.copyWith(status: BookingStatus.paymentPendingAuthorization, paymentResult: result));
    } else if (result.isPending) {
      emit(state.copyWith(status: BookingStatus.paymentPending, paymentResult: result));
    } else {
      emit(state.copyWith(
        status: BookingStatus.awaitingPayment,
        paymentResult: result,
        errorMessage: result.failureReason ?? 'Paiement refusé.',
      ));
    }
  }
}
