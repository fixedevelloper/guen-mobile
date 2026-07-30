import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_flights_usecase.dart';
import 'flight_event.dart';
import 'flight_state.dart';

class FlightBloc extends Bloc<FlightEvent, FlightState> {
  final SearchFlightsUseCase searchFlightsUseCase;
  FlightBloc({required this.searchFlightsUseCase}) : super(FlightInitial()) {
    on<SearchFlightsEvent>((event, emit) async {
      emit(FlightLoading());
      try {
        final flights = await searchFlightsUseCase.execute(from: event.from, to: event.to, date: event.date);
        emit(FlightLoaded(flights));
      } catch (e) { emit(FlightError(e.toString())); }
    });
  }
}
