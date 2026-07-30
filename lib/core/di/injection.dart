import 'package:get_it/get_it.dart';
import 'package:guentravel/features/flight_booking/presentation/bloc/flight_booking_bloc.dart';
import '../network/dio_client.dart';
import '../../features/flight_booking/data/datasources/flight_api_client.dart';
import '../../features/flight_booking/data/datasources/flight_remote_data_source.dart';
import '../../features/flight_booking/data/repositories/flight_repository_impl.dart';
import '../../features/flight_booking/domain/repositories/flight_repository.dart';
import '../../features/flight_booking/domain/usecases/search_flights_usecase.dart';
import '../../features/flight_booking/presentation/bloc/flight_bloc.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // 1. Core / Réseau
  sl.registerLazySingleton(() => DioClient());

  // 2. Clients API & Sources de données
  sl.registerLazySingleton(() => FlightApiClient(
    // Option A : Si DioClient possède une propriété interne 'dio' (ex: dioClient.dio)
    sl<DioClient>().dio,

    // Option B : Si ton DioClient hérite directement de Dio, écris juste :
    // sl<DioClient>(),
  ));

  sl.registerLazySingleton<FlightRemoteDataSource>(
        () => FlightRemoteDataSourceImpl(dioClient: sl()),
  );

  // 3. Repositories
  sl.registerLazySingleton<FlightRepository>(
        () => FlightRepositoryImpl(remoteDataSource: sl()),
  );

  // 4. Use Cases
  sl.registerLazySingleton(() => SearchFlightsUseCase(repository: sl()));

  // 5. Blocs
  sl.registerFactory<FlightBookingBloc>(
        () => FlightBookingBloc(sl<FlightApiClient>()),
  );

  sl.registerFactory<FlightBloc>(
        () => FlightBloc(searchFlightsUseCase: sl()),
  );
}