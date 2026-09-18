import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../booking/data/datasources/booking_api_client.dart';
import 'my_bookings_state.dart';

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final BookingApiClient _apiClient;

  MyBookingsCubit(this._apiClient) : super(const MyBookingsState());

  Future<void> load() async {
    emit(state.copyWith(status: MyBookingsStatus.loading, errorMessage: null));
    try {
      final bookings = await _apiClient.getMyBookings();
      emit(state.copyWith(status: MyBookingsStatus.loaded, bookings: bookings));
    } on ApiException catch (e) {
      emit(state.copyWith(status: MyBookingsStatus.error, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(
        status: MyBookingsStatus.error,
        errorMessage: 'Impossible de charger vos réservations.',
      ));
    }
  }
}
