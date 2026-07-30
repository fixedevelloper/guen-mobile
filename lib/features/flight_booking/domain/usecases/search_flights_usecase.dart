import '../entities/flight.dart';
import '../repositories/flight_repository.dart';

class SearchFlightsUseCase {
  final FlightRepository repository;
  SearchFlightsUseCase({required this.repository});

  Future<List<Flight>> execute({required String from, required String to, required String date}) {
    return repository.searchFlights(from: from, to: to, date: date);
  }
}
