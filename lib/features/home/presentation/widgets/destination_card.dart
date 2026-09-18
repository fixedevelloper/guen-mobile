import 'package:flutter/material.dart';

import '../../data/models/featured_destination.dart';

/// Carte destination réutilisée par le carrousel de l'accueil et par l'écran
/// "Voir tout" (`AllDestinationsScreen`) - gère l'absence d'image (aucune
/// photo n'est garantie tant qu'un admin ne l'a pas ajoutée, voir
/// FeaturedDestinationService côté Spring) avec un repli neutre.
class DestinationCard extends StatelessWidget {
  final FeaturedDestination destination;
  final VoidCallback? onTap;
  final double? width;

  const DestinationCard({super.key, required this.destination, this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    final hasImage = destination.imageUrl != null && destination.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade300,
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(destination.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, _) {},
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasImage) const Icon(Icons.image_not_supported_rounded, color: Colors.white70, size: 20),
              if (!hasImage) const SizedBox(height: 8),
              Text(destination.cityName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(destination.countryName, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
