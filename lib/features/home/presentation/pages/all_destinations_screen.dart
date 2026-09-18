import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../flight_booking/presentation/pages/flight_search_screen.dart';
import '../../data/models/featured_destination.dart';
import '../widgets/destination_card.dart';

/// Grille des destinations populaires ("Voir tout" sur l'accueil) - reçoit la
/// liste déjà chargée par `DestinationsCubit` plutôt que de refaire un appel
/// réseau, ces destinations changent rarement (curation admin + refresh
/// quotidien côté backend, voir FeaturedDestinationScheduler).
class AllDestinationsScreen extends StatelessWidget {
  final List<FeaturedDestination> destinations;

  const AllDestinationsScreen({super.key, required this.destinations});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(l10n.homeAllDestinationsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final destination = destinations[index];
          final code = destination.destinationCode;
          return DestinationCard(
            destination: destination,
            onTap: code == null || code.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FlightSearchScreen(initialDestinationCode: code)),
                    ),
          );
        },
      ),
    );
  }
}
