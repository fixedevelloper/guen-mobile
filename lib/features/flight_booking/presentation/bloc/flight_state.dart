import '../../domain/entities/flight.dart';
abstract class FlightState { const FlightState(); }
class FlightInitial extends FlightState {}
class FlightLoading extends FlightState {}
class FlightLoaded extends FlightState { final List<Flight> flights; const FlightLoaded(this.flights); }
class FlightError extends FlightState { final String message; const FlightError(this.message); }
