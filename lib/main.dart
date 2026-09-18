import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guentravel/core/locale/locale_cubit.dart';
import 'package:guentravel/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:guentravel/features/profil/presentation/pages/profile_screen.dart';
import 'package:guentravel/l10n/generated/app_localizations.dart';
import 'package:guentravel/splash_screen.dart';
import 'core/di/injection.dart' as di;
import 'features/flight_booking/presentation/bloc/flight_booking_bloc.dart';
import 'features/flight_booking/presentation/pages/flight_search_screen.dart';
import 'features/hotel_search/presentation/pages/hotel_search_screen.dart';
import 'features/home_screen.dart';
// Importez votre splash screen selon le chemin de votre dossier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<FlightBookingBloc>()),
        // Singleton GetIt : une seule session pour toute l'app (voir AuthCubit).
        BlocProvider.value(value: di.sl<AuthCubit>()),
        BlocProvider.value(value: di.sl<LocaleCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          return MaterialApp(
            title: "Guen's travel & tours",
            debugShowCheckedModeBanner: false,
            // `locale: null` laisse MaterialApp résoudre la langue du système
            // parmi supportedLocales (comportement par défaut tant que
            // l'utilisateur n'a pas choisi explicitement FR/EN).
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0099FF),
                primary: const Color(0xFF0099FF),
                secondary: const Color(0xFF3ECB5B),
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onItemTapped),
      const FlightSearchScreen(),
      const HotelSearchScreen(),
       ProfileScreen(onNavigate: _onItemTapped),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.flight_takeoff_rounded),
            label: l10n.navFlights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.hotel_rounded),
            label: l10n.navHotels,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
