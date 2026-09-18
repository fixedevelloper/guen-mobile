import 'package:cookie_jar/cookie_jar.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:guentravel/features/auth/data/datasources/auth_api_client.dart';
import 'package:guentravel/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:guentravel/features/flight_booking/presentation/bloc/flight_booking_bloc.dart';

import '../locale/locale_cubit.dart';
import '../network/dio_client.dart';
import '../network/geo_api_client.dart';
import '../../features/flight_booking/data/datasources/flight_api_client.dart';
import '../../features/hotel_search/data/datasources/hotel_api_client.dart';
import '../../features/hotel_search/presentation/cubit/hotel_search_cubit.dart';
import '../../features/car_rental_search/data/datasources/vehicle_api_client.dart';
import '../../features/car_rental_search/presentation/cubit/vehicle_search_cubit.dart';
import '../../features/furnished_rental_search/data/datasources/property_api_client.dart';
import '../../features/furnished_rental_search/presentation/cubit/property_search_cubit.dart';
import '../../features/booking/data/datasources/booking_api_client.dart';
import '../../features/booking/presentation/cubit/booking_cubit.dart';
import '../../features/notifications/data/datasources/notification_api_client.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/profil/presentation/cubit/my_bookings_cubit.dart';
import '../../features/home/data/datasources/destination_api_client.dart';
import '../../features/home/presentation/cubit/destinations_cubit.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // 1. Core / Réseau
  // Cookie jar persistant : porte le cookie HttpOnly de session JWT posé par
  // AuthController (com.guentours.security), pour rester connecté entre deux
  // lancements de l'app — même mécanisme que le navigateur pour Next.js.
  final appDocsDir = await getApplicationDocumentsDirectory();
  final cookieJar = PersistCookieJar(
    storage: FileStorage('${appDocsDir.path}/.cookies/'),
    ignoreExpires: false,
  );
  sl.registerLazySingleton<CookieJar>(() => cookieJar);
  sl.registerLazySingleton(() => DioClient(sl<CookieJar>()));
  sl.registerLazySingleton(() => GeoApiClient(sl<DioClient>().dio));

  // 2. Clients API
  sl.registerLazySingleton(() => FlightApiClient(sl<DioClient>().dio));
  sl.registerLazySingleton(() => HotelApiClient(sl<DioClient>().dio));
  sl.registerLazySingleton(() => VehicleApiClient(sl<DioClient>().dio));
  sl.registerLazySingleton(() => PropertyApiClient(sl<DioClient>().dio));
  sl.registerLazySingleton(() => BookingApiClient(sl<DioClient>().dio));
  sl.registerLazySingleton(() => AuthApiClient(sl<DioClient>().dio));
  sl.registerLazySingleton(() => NotificationApiClient(sl<DioClient>().dio));
  sl.registerLazySingleton(() => DestinationApiClient(sl<DioClient>().dio));

  // 3. Blocs / Cubits
  sl.registerFactory<FlightBookingBloc>(
        () => FlightBookingBloc(sl<FlightApiClient>()),
  );
  sl.registerFactory<HotelSearchCubit>(
        () => HotelSearchCubit(sl<HotelApiClient>()),
  );
  sl.registerFactory<VehicleSearchCubit>(
        () => VehicleSearchCubit(sl<VehicleApiClient>()),
  );
  sl.registerFactory<PropertySearchCubit>(
        () => PropertySearchCubit(sl<PropertyApiClient>()),
  );
  sl.registerFactory<BookingCubit>(
        () => BookingCubit(sl<BookingApiClient>()),
  );
  sl.registerFactory<MyBookingsCubit>(
        () => MyBookingsCubit(sl<BookingApiClient>()),
  );
  sl.registerFactory<NotificationsCubit>(
        () => NotificationsCubit(sl<NotificationApiClient>()),
  );
  sl.registerFactory<DestinationsCubit>(
        () => DestinationsCubit(sl<DestinationApiClient>()),
  );
  // Singleton (pas une factory) : une seule session pour toute l'app, voir
  // AuthCubit.
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl<AuthApiClient>()));
  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit());
}
