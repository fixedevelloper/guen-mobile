import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import '../../data/models/harmonized_flight_offer.dart';
import '../../data/models/multi_city_itinerary.dart';
import 'flight_seat_screen.dart';
import 'passenger_info_screen.dart';

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
            return _buildEmptyState(context, primaryColor);
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
                      return _FlightOfferCard(
                        offer: standardOffer,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                      );
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
            color: Colors.black.withValues(alpha: 0.02),
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
                color: bgColor.withValues(alpha: 0.1),
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
                    activeThumbColor: Theme.of(context).colorScheme.primary,
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
      selectedColor: primaryColor.withValues(alpha: 0.15),
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

  // --- LES CARTES MULTI-DESTINATIONS (Inchangées pour garder la compatibilité avec tes Records Java) ---

  Widget _buildMultiCityFlightCard(BuildContext context, MultiCityItinerary itinerary, Color primaryColor, Color secondaryColor) {
    final totalPriceString = "${itinerary.totalPrice.amount} ${itinerary.totalPrice.currency}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("Combiné", style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
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

                  // Pas d'étape "options additionnelles" pour les itinéraires
                  // multi-destinations : chaque segment a son propre offerId, il
                  // n'y a pas d'offre unique à coter via LoadAncillaryOptions
                  // (pensé pour un vol simple).
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PassengerInfoScreen()));
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

  Widget _buildEmptyState(BuildContext context, Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration graphique dynamique
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                Icon(
                  Icons.flight_takeoff_rounded,
                  size: 42,
                  color: primaryColor,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Titre principal
            const Text(
              'Aucun vol trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Description & conseils
            Text(
              'Nous n’avons trouvé aucun itinéraire correspondant à vos critères de recherche. Essayez d’ajuster vos filtres ou vos dates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Actions principales
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedSort = 'Prix croissant';
                        _onlyDirectFlights = false;
                        _maxPrice = 1500000;
                      });
                      // Relancer le filtre côté BLoC si nécessaire
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Modifier',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

Widget _timeColumn(String time, String code, CrossAxisAlignment alignment) {
  return Column(
    crossAxisAlignment: alignment,
    children: [
      Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 4),
      Text(code, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 14)),
    ],
  );
}

/// Carte d'une offre de vol simple, avec panneau "Détails" dépliable - même
/// contenu que AncillaryOptionsStep... non, que FlightOfferCard côté Next.js
/// (frontend/src/components/search/flight-results.tsx) : nom de compagnie,
/// itinéraire segment par segment avec escales, franchise bagages, sièges
/// restants. Le détail (escales/bagages/hold) vient de la quote la moins
/// chère (cheapestQuote.detail) - propre au fournisseur/tarif, pas à l'offre
/// harmonisée partagée ; absent pour les fournisseurs qui ne l'exposent pas
/// (repli sur l'itinéraire simple départ/arrivée de l'offre elle-même).
class _FlightOfferCard extends StatefulWidget {
  final HarmonizedFlightOffer offer;
  final Color primaryColor;
  final Color secondaryColor;

  const _FlightOfferCard({
    required this.offer,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<_FlightOfferCard> createState() => _FlightOfferCardState();
}

class _FlightOfferCardState extends State<_FlightOfferCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final primaryColor = widget.primaryColor;
    final secondaryColor = widget.secondaryColor;

    final durationDifference = offer.arrivalTime.difference(offer.departureTime);
    final durationText = '${durationDifference.inHours}h ${durationDifference.inMinutes.remainder(60)}m';

    final departureTimeString =
        "${offer.departureTime.hour.toString().padLeft(2, '0')}:${offer.departureTime.minute.toString().padLeft(2, '0')}";
    final arrivalTimeString =
        "${offer.arrivalTime.hour.toString().padLeft(2, '0')}:${offer.arrivalTime.minute.toString().padLeft(2, '0')}";

    final bestQuote = offer.bestQuote;
    final bestPrice = bestQuote != null ? bestQuote.price.format() : "N/A";
    final detail = bestQuote?.detail;
    final segments = detail?.segments ?? const <FlightSegmentDetail>[];
    final stopCount = segments.length > 1 ? segments.length - 1 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: primaryColor.withValues(alpha: 0.1),
                            child: Icon(Icons.flight_takeoff_rounded, size: 14, color: primaryColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.displayAirlineName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                ),
                                Text(
                                  '${offer.airline} ${offer.flightNumber}',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    _timeColumn(departureTimeString, offer.origin, CrossAxisAlignment.start),
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
                          Text(
                            stopCount > 0 ? '$stopCount escale(s)' : 'Direct',
                            style: TextStyle(
                              color: stopCount > 0 ? Colors.amber.shade800 : Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _timeColumn(arrivalTimeString, offer.destination, CrossAxisAlignment.end),
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
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _showDetails = !_showDetails),
                          icon: AnimatedRotation(
                            turns: _showDetails ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.expand_more_rounded, size: 18, color: primaryColor),
                          ),
                          label: Text(
                            _showDetails ? 'Masquer' : 'Détails',
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: offer.bestOfferId.isEmpty ? null : () {
                            // 1. On enregistre le vol sélectionné
                            context.read<FlightBookingBloc>().add(FlightSelected(flight: offer));

                            // 2. Charge les extras tarifés (sièges/bagages/repas/assurance) pour
                            // LA MÊME offre que celle utilisée au checkout (résolue depuis le
                            // même offer en cache).
                            context.read<FlightBookingBloc>().add(LoadAncillaryOptions(offer.bestOfferId, 'FLIGHT'));

                            // 3. On navigue
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FlightSeatScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text('Choisir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_showDetails) _buildDetailsPanel(offer, detail, segments, primaryColor),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(
    HarmonizedFlightOffer offer,
    FlightOfferDetail? detail,
    List<FlightSegmentDetail> segments,
    Color primaryColor,
  ) {
    final firstSegmentCabinBaggage = segments.isNotEmpty && segments.first.cabinBaggage.isNotEmpty
        ? segments.first.cabinBaggage.first
        : null;
    final firstSegmentCheckedBaggage = segments.isNotEmpty && segments.first.checkedBaggage.isNotEmpty
        ? segments.first.checkedBaggage.first
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: primaryColor),
              const SizedBox(width: 6),
              const Text(
                "ITINÉRAIRE DÉTAILLÉ",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (segments.isNotEmpty)
            ...segments.asMap().entries.map((entry) {
              final index = entry.key;
              final segment = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _segmentTile(segment, index < segments.length - 1, primaryColor),
              );
            })
          else
            _segmentTile(
              FlightSegmentDetail(
                airlineCode: offer.airline,
                airlineName: offer.airlineName,
                flightNumber: offer.flightNumber,
                departure: AirportInfo(code: offer.origin),
                arrival: AirportInfo(code: offer.destination),
                departureTime: offer.departureTime,
                arrivalTime: offer.arrivalTime,
              ),
              false,
              primaryColor,
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip('Cabine', offer.cabinClass, Icons.event_seat_rounded),
              _infoChip(
                firstSegmentCabinBaggage != null ? 'Bagage cabine' : 'Bagage',
                firstSegmentCabinBaggage?.rule ?? 'Inclus',
                Icons.work_outline_rounded,
              ),
              if (firstSegmentCheckedBaggage != null)
                _infoChip('Bagage soute', firstSegmentCheckedBaggage.rule, Icons.luggage_rounded),
              _infoChip('Places restantes', '${offer.seatsAvailable}', Icons.airline_seat_recline_normal_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmentTile(FlightSegmentDetail segment, bool showLayover, Color primaryColor) {
    final depTime = "${segment.departureTime.hour.toString().padLeft(2, '0')}:${segment.departureTime.minute.toString().padLeft(2, '0')}";
    final arrTime = "${segment.arrivalTime.hour.toString().padLeft(2, '0')}:${segment.arrivalTime.minute.toString().padLeft(2, '0')}";
    final airlineLabel = (segment.airlineName != null && segment.airlineName!.isNotEmpty)
        ? segment.airlineName!
        : segment.airlineCode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(depTime, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(width: 6),
              Text(segment.departure.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Divider(color: Colors.grey.shade300),
                ),
              ),
              Text(arrTime, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(width: 6),
              Text(segment.arrival.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flight_rounded, size: 13, color: primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$airlineLabel • Vol ${segment.flightNumber}${segment.duration != null ? ' • ${segment.duration}' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showLayover && segment.layoverAfter != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: Colors.amber.shade800),
                  const SizedBox(width: 6),
                  Text(
                    'Escale à ${segment.arrival.city ?? segment.arrival.code} • ${segment.layoverAfter}',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.blueGrey.shade700),
              const SizedBox(width: 5),
              Flexible(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}