import '../../domain/entities/flight.dart';
import '../../domain/repositories/flight_repository.dart';
import '../datasources/flight_remote_data_source.dart';
import '../../../../core/errors/failures.dart';

class FlightRepositoryImpl implements FlightRepository {
  final FlightRemoteDataSource remoteDataSource;
  FlightRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Flight>> searchFlights({required String from, required String to, required String date}) async {
    try {
      return await remoteDataSource.searchFlights(from: from, to: to, date: date);
    } catch (e) {
      throw const ServerFailure('Erreur backend');
    }
  }
}
