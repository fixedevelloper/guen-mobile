import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guentravel/splash_screen.dart';
import 'core/di/injection.dart' as di;
import 'features/flight_booking/presentation/bloc/flight_booking_bloc.dart';
import 'features/flight_booking/presentation/pages/flight_search_screen.dart';
import 'features/home_screen.dart';
// Importez votre splash screen selon le chemin de votre dossier

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  di.setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<FlightBookingBloc>(),
      child: MaterialApp(
        title: 'Guentravel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF15A4E6),
            primary: const Color(0xFF15A4E6),
            secondary: const Color(0xFF7BCD4F),
          ),
        ),
        home: const SplashScreen(),
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
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onItemTapped),
      const FlightSearchScreen(),
      const Center(child: Text('Recherche d\'Hôtels')),
      const Center(child: Text('Mon Profil & Réservations')),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_rounded),
            label: 'Vols',
          ),
          NavigationDestination(
            icon: Icon(Icons.hotel_rounded),
            label: 'Hôtels',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}