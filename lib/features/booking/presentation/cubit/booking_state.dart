import '../../../../core/models/booking_response.dart';
import '../../../../core/models/payment_result.dart';

enum BookingStatus {
  initial,
  checkingOut,
  awaitingPayment, // checkout terminé, en attente du paiement
  payingNow,
  succeeded,
  failure,
  /// Mobile Money : confirmation USSD asynchrone en attente côté gateway.
  paymentPending,
  /// Carte : la gateway exige une étape synchrone (PIN/AVS/OTP/redirection)
  /// avant de finaliser — voir paymentResult.authorizationType. Pas encore
  /// d'écran dédié pour ce flux (contrairement à flight_booking) : l'appelant
  /// doit au minimum éviter d'afficher ça comme un refus.
  paymentPendingAuthorization,
}

class BookingFlowState {
  final BookingStatus status;
  final BookingResponse? booking;
  final PaymentResult? paymentResult;
  final String? errorMessage;

  const BookingFlowState({
    this.status = BookingStatus.initial,
    this.booking,
    this.paymentResult,
    this.errorMessage,
  });

  BookingFlowState copyWith({
    BookingStatus? status,
    BookingResponse? booking,
    PaymentResult? paymentResult,
    String? errorMessage,
  }) {
    return BookingFlowState(
      status: status ?? this.status,
      booking: booking ?? this.booking,
      paymentResult: paymentResult ?? this.paymentResult,
      errorMessage: errorMessage,
    );
  }
}
