import '../../../../core/models/booking_response.dart';

enum MyBookingsStatus { initial, loading, loaded, error }

class MyBookingsState {
  final MyBookingsStatus status;
  final List<BookingResponse> bookings;
  final String? errorMessage;

  const MyBookingsState({
    this.status = MyBookingsStatus.initial,
    this.bookings = const [],
    this.errorMessage,
  });

  MyBookingsState copyWith({
    MyBookingsStatus? status,
    List<BookingResponse>? bookings,
    String? errorMessage,
  }) {
    return MyBookingsState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      errorMessage: errorMessage,
    );
  }
}
