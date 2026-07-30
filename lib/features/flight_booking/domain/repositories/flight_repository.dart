import '../../domain/entities/flight.dart';

abstract class FlightRepository {
  Future<List<Flight>> searchFlights({required String from, required String to, required String date});
}
