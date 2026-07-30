import '../../../../core/network/dio_client.dart';
import '../models/flight_model.dart';

abstract class FlightRemoteDataSource {
  Future<List<FlightModel>> searchFlights({required String from, required String to, required String date});
}

class FlightRemoteDataSourceImpl implements FlightRemoteDataSource {
  final DioClient dioClient;
  FlightRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<FlightModel>> searchFlights({required String from, required String to, required String date}) async {
    final response = await dioClient.dio.get('/flights/search', queryParameters: {'departure': from, 'arrival': to, 'date': date});
    if (response.statusCode == 200) {
      return (response.data as List).map((json) => FlightModel.fromJson(json)).toList();
    }
    throw Exception('Erreur serveur');
  }
}
