import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import '../../data/models/harmonized_flight_offer.dart';
import '../../data/models/multi_city_itinerary.dart';
import 'flight_seat_screen.dart';

class FlightResultsScreen extends StatefulWidget {
  const FlightResultsScreen({super.key});

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  // États de filtrage locaux (peuvent être déplacés dans ton BLoC si tu veux persister)
  String _selectedSort = 'Prix croissant';
  bool _onlyDirectFlights = false;
  double _maxPrice = 1500000; // Seuil max par défaut en XAF

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary; // Bleu 15a4e6
    final secondaryColor = Theme.of(context).colorScheme.secondary; // Vert 7bcd4f

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Résultats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<FlightBookingBloc, FlightBookingState>(
        builder: (context, state) {
          if (state.status == FlightBookingStatus.loading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (state.status == FlightBookingStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'Une erreur est survenue lors de la récupération des vols.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          final isMultiCity = state.multiCityFlights.isNotEmpty;
          final hasNoResults = state.availableFlights.isEmpty && state.multiCityFlights.isEmpty;

          if (hasNoResults) {
            return const Center(
              child: Text('Aucun vol disponible pour cette recherche.'),
            );
          }

          return Column(
            children: [
              // Bandeau récapitulatif branché sur notre méthode de filtre
              _buildRouteSummaryHeader(
                context,
                isMultiCity ? "Itinéraire" : (state.departure ?? 'Origine'),
                isMultiCity ? "Multi-destinations" : (state.destination ?? 'Destination'),
                primaryColor,
              ),

              // Liste dynamique
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: isMultiCity ? state.multiCityFlights.length : state.availableFlights.length,
                  itemBuilder: (context, index) {
                    if (isMultiCity) {
                      final multiCityOffer = state.multiCityFlights[index];
                      return _buildMultiCityFlightCard(context, multiCityOffer, primaryColor, secondaryColor);
                    } else {
                      final standardOffer = state.availableFlights[index];
                      return _buildFlightCard(context, standardOffer, primaryColor, secondaryColor);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteSummaryHeader(BuildContext context, String from, String to, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$from vers $to', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Options classées par prix', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
          // Bouton filtres rendu cliquable
          InkWell(
            onTap: () => _showFilterBottomSheet(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: bgColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Filtres',
                    style: TextStyle(color: bgColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le panneau des filtres par le bas
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrer et Trier',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Section : Trier par
                  const Text('Trier par', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildChipSort('Prix croissant', setModalState),
                      const SizedBox(width: 8),
                      _buildChipSort('Plus rapide', setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section : Escales
                  const Text('Escales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SwitchListTile(
                    title: const Text('Vols directs uniquement', style: TextStyle(fontSize: 14)),
                    contentPadding: EdgeInsets.zero,
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: _onlyDirectFlights,
                    onChanged: (value) {
                      setModalState(() => _onlyDirectFlights = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Section : Budget Max
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Budget maximum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${_maxPrice.toInt().toString()} XAF', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _maxPrice,
                    min: 100000,
                    max: 2500000,
                    divisions: 24,
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (value) {
                      setModalState(() => _maxPrice = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bouton de validation
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // On applique les filtres à notre vue principale
                        setState(() {});
                        Navigator.pop(context);

                        // Déclenche l'événement de filtrage vers ton BLoC ici si nécessaire :
                        // context.read<FlightBookingBloc>().add(ApplyFiltersEvent(...));
                      },
                      child: const Text('Appliquer les filtres', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChipSort(String label, StateSetter setModalState) {
    final isSelected = _selectedSort == label;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade300),
      onSelected: (bool selected) {
        if (selected) {
          setModalState(() => _selectedSort = label);
        }
      },
    );
  }

  // --- LES CARTES DE VOLS (Inchangées pour garder la compatibilité avec tes Records Java) ---
  Widget _buildFlightCard(BuildContext context, HarmonizedFlightOffer offer, Color primaryColor, Color secondaryColor) {
    final durationDifference = offer.arrivalTime.difference(offer.departureTime);
    final hours = durationDifference.inHours;
    final minutes = durationDifference.inMinutes.remainder(60);
    final durationText = '${hours}h ${minutes}m';

    final departureTimeString = "${offer.departureTime.hour.toString().padLeft(2, '0')}:${offer.departureTime.minute.toString().padLeft(2, '0')}";
    final arrivalTimeString = "${offer.arrivalTime.hour.toString().padLeft(2, '0')}:${offer.arrivalTime.minute.toString().padLeft(2, '0')}";

    final bestPrice = offer.quotes.isNotEmpty
        ? "${offer.quotes.first.price} ${offer.quotes.first.price.currency ?? 'XAF'}"
        : "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.flight_takeoff_rounded, size: 14, color: Color(0xFF15A4E6)),
                  ),
                  const SizedBox(width: 10),
                  Text(offer.airline, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  const SizedBox(width: 6),
                  Text('(${offer.flightNumber})', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Text(offer.cabinClass, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn(departureTimeString, offer.origin, CrossAxisAlignment.start),
              Expanded(
                child: Column(
                  children: [
                    Text(durationText, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.flight_rounded, color: primaryColor, size: 16),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${offer.seatsAvailable} sièges dispos', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              _buildTimeColumn(arrivalTimeString, offer.destination, CrossAxisAlignment.end),
            ],
          ),
          Divider(height: 32, color: Colors.grey.shade100),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meilleur tarif', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(bestPrice, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: secondaryColor)),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // 1. On enregistre le vol sélectionné
                  context.read<FlightBookingBloc>().add(FlightSelected(flight: offer));

                  // 2. ON DÉCLENCHE LE CHARGEMENT DU PLAN (Ajoute cette ligne)
                  context.read<FlightBookingBloc>().add(LoadSeatMap(offer.quotes.first.offerId));

                  // 3. On navigue
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FlightSeatScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Choisir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiCityFlightCard(BuildContext context, MultiCityItinerary itinerary, Color primaryColor, Color secondaryColor) {
    final totalPriceString = "${itinerary.totalPrice.amount} ${itinerary.totalPrice.currency}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.layers_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text("${itinerary.legs.length} destinations incluses", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("Combiné", style: TextStyle(color: Color(0xFF15A4E6), fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          ...itinerary.legs.map((leg) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
                  const SizedBox(width: 12),
                  Text(leg.origin, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey.shade400),
                  ),
                  Text(leg.destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Text("${leg.airline} (${leg.flightNumber})", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          }),
          Divider(height: 24, color: Colors.grey.shade100),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tarif global combiné', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(totalPriceString, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: secondaryColor)),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<FlightBookingBloc>().add(FlightSelected(multiCityItinerary: itinerary));

                  // Si tu as un offerId global dans ton itinéraire :
                 // context.read<FlightBookingBloc>().add(LoadSeatMap(itinerary.id));

                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FlightSeatScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Choisir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String time, String code, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(code, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}