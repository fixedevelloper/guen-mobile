import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fond légèrement grisé pour faire ressortir les cartes blanches
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Utilisation d'un Stack pour gérer le chevauchement
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Le Header en arrière-plan
                _buildHeaderBackground(context, primaryColor, secondaryColor),

                // 2. Le bloc de recherche qui vient "entrer" et chevaucher le header
                Positioned(
                  bottom: -24, // Pousse la barre de recherche à moitié en dehors du header
                  left: 20,
                  right: 20,
                  child: _buildSearchBar(secondaryColor),
                ),
              ],
            ),

            // Espace pour compenser le débordement de la barre de recherche
            const SizedBox(height: 48),

            // 3. Section des Services (Vols & Hôtels)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Où désirez-vous aller ?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceSelector(context, primaryColor, secondaryColor),

            const SizedBox(height: 32),

            // 4. Section Destinations populaires
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Destinations Populaires',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('Voir tout', style: TextStyle(color: primaryColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildPopularDestinations(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Le fond du header avec le dégradé inversé
  Widget _buildHeaderBackground(BuildContext context, Color primaryColor, Color secondaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 60), // Plus d'espace en bas
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryColor,
            secondaryColor.withOpacity(0.85),
            primaryColor.withOpacity(0.4),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, Lorenzo 👋',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prêt pour votre prochain voyage ?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Laisse de la place avant le bloc flottant
        ],
      ),
    );
  }

  // La barre de recherche flottante
  Widget _buildSearchBar(Color activeColor) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8), // Ombre accentuée vers le bas pour l'effet de flottaison
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: activeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rechercher des vols, hôtels...',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.tune_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelector(BuildContext context, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: _buildServiceCard(
              icon: Icons.flight_takeoff_rounded,
              label: 'Vols',
              color: primaryColor.withOpacity(0.12),
              iconColor: primaryColor,
              onTap: () => onNavigate(1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildServiceCard(
              icon: Icons.hotel_rounded,
              label: 'Hôtels',
              color: secondaryColor.withOpacity(0.15),
              iconColor: secondaryColor,
              onTap: () => onNavigate(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularDestinations() {
    final destinations = [
      {'name': 'Paris', 'country': 'France', 'image': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=500'},
      {'name': 'New York', 'country': 'USA', 'image': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=500'},
      {'name': 'Tokyo', 'country': 'Japon', 'image': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=500'},
    ];

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final dest = destinations[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(dest['image']!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(dest['country']!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}