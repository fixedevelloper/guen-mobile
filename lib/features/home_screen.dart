import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../core/widgets/language_picker.dart';
import '../core/widgets/retry_error_banner.dart';
import '../l10n/generated/app_localizations.dart';
import 'auth/presentation/cubit/auth_cubit.dart';
import 'auth/presentation/cubit/auth_state.dart';
import 'car_rental_search/presentation/pages/car_rental_search_screen.dart';
import 'flight_booking/presentation/pages/flight_search_screen.dart';
import 'furnished_rental_search/presentation/pages/furnished_rental_search_screen.dart';
import 'home/presentation/cubit/destinations_cubit.dart';
import 'home/presentation/cubit/destinations_state.dart';
import 'home/presentation/pages/all_destinations_screen.dart';
import 'home/presentation/widgets/destination_card.dart';
import 'notifications/presentation/pages/notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DestinationsCubit>()..load(),
      child: _HomeView(onNavigate: onNavigate),
    );
  }
}

class _HomeView extends StatelessWidget {
  final Function(int) onNavigate;

  const _HomeView({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildHeaderBackground(context, l10n, primaryColor, secondaryColor),
                Positioned(
                  bottom: -24,
                  left: 20,
                  right: 20,
                  child: _buildSearchBar(l10n, secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                l10n.homeWhereToGo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceSelector(context, l10n, primaryColor, secondaryColor),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.homePopularDestinations,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  BlocBuilder<DestinationsCubit, DestinationsState>(
                    builder: (context, state) {
                      final hasDestinations = state.status == DestinationsStatus.loaded && state.destinations.isNotEmpty;
                      return TextButton(
                        onPressed: hasDestinations
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AllDestinationsScreen(destinations: state.destinations)),
                                )
                            : null,
                        child: Text(l10n.homeSeeAll, style: TextStyle(color: primaryColor)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildPopularDestinations(context, l10n),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(
      BuildContext context, AppLocalizations l10n, Color primaryColor, Color secondaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryColor,
            secondaryColor.withValues(alpha: 0.85),
            primaryColor.withValues(alpha: 0.4),
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
              Expanded(
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    final firstName = authState.isAuthenticated
                        ? authState.user!.fullName.trim().split(RegExp(r'\s+')).first
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName != null ? l10n.homeGreeting(firstName) : l10n.homeGreetingGuest,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeSubtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              _headerIconButton(
                icon: Icons.language_rounded,
                onPressed: () => showLanguagePicker(context),
              ),
              const SizedBox(width: 8),
              _headerIconButton(
                icon: Icons.notifications_none_rounded,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _headerIconButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, Color activeColor) {
    return InkWell(
      // La barre ouvre directement la recherche de vols, le point d'entrée
      // principal de l'app - même écran que la carte de service "Vols"
      // (onNavigate(1) bascule l'onglet du bas, sans empiler un second écran).
      onTap: () => onNavigate(1),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: activeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.homeSearchHint,
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

  Widget _buildServiceSelector(
      BuildContext context, AppLocalizations l10n, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            // SUPPRESSION DE CrossAxisAlignment.stretch (cause du crash)
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.flight_takeoff_rounded,
                  label: l10n.homeFlights,
                  subtitle: l10n.homeFlightsSubtitle,
                  color: primaryColor,
                  onTap: () => onNavigate(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.hotel_rounded,
                  label: l10n.homeHotels,
                  subtitle: l10n.homeHotelsSubtitle,
                  color: secondaryColor,
                  onTap: () => onNavigate(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            // SUPPRESSION DE CrossAxisAlignment.stretch (cause du crash)
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.directions_car_filled_rounded,
                  label: l10n.homeVehicles,
                  subtitle: l10n.homeVehiclesSubtitle,
                  color: secondaryColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarRentalSearchScreen())),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.villa_rounded,
                  label: l10n.homeFurnished,
                  subtitle: l10n.homeFurnishedSubtitle,
                  color: primaryColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FurnishedRentalSearchScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: color),
                ),
                Icon(Icons.arrow_outward_rounded, size: 16, color: color.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularDestinations(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<DestinationsCubit, DestinationsState>(
      builder: (context, state) {
        if (state.status == DestinationsStatus.loading || state.status == DestinationsStatus.initial) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == DestinationsStatus.error) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: RetryErrorBanner(
              message: state.errorMessage ?? l10n.homeDestinationsError,
              onRetry: () => context.read<DestinationsCubit>().load(),
            ),
          );
        }

        if (state.destinations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              l10n.homeDestinationsEmpty,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            itemCount: state.destinations.length,
            itemBuilder: (context, index) {
              final destination = state.destinations[index];
              final code = destination.destinationCode;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: DestinationCard(
                  destination: destination,
                  width: 160,
                  onTap: code == null || code.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FlightSearchScreen(initialDestinationCode: code)),
                          ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}