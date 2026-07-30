import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'features/flight_booking/data/datasources/flight_api_client.dart';
import 'features/flight_booking/presentation/bloc/flight_booking_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  //! 1. Features - Flight Booking (BLoCs)
  sl.registerFactory(() => FlightBookingBloc(sl()));

  //! 2. Data Sources / Repositories
  sl.registerLazySingleton(() => FlightApiClient(sl()));

  //! 3. Core / External
  sl.registerLazySingleton(() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10), // Évite les timeouts infinis avec Sabre
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Tu pourras ajouter ici tes intercepteurs plus tard (ex: logs ou jeton OAuth Sabre)
    return dio;
  });
}