import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guentravel/features/flight_booking/presentation/pages/passenger_info_screen.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import '../../data/models/ancillary_option.dart';
import '../../../../core/models/provider_quote.dart';

/// Étape "options additionnelles" du checkout vol : sièges réels et tarifés
/// (grille par segment, exclusifs par voyageur) + bagages/repas/assurance -
/// alimentée par POST /api/bookings/ancillary-options, comme sur le frontend
/// web (voir AncillaryOptionsStep côté Next.js). Remplace l'ancien plan de
/// cabine simulé/non tarifé.
class FlightSeatScreen extends StatefulWidget {
  const FlightSeatScreen({super.key});

  @override
  State<FlightSeatScreen> createState() => _FlightSeatScreenState();
}

class _FlightSeatScreenState extends State<FlightSeatScreen> {
  final List<String> _selectedIds = [];

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// Les sièges sont exclusifs : choisir un nouveau siège pour un (segment,
  /// voyageur) retire silencieusement celui que ce même voyageur avait déjà
  /// sur ce segment - un voyageur ne peut pas être assis à deux endroits.
  void _toggleSeat(AncillaryOption option, List<AncillaryOption> allOptions) {
    setState(() {
      if (_selectedIds.contains(option.id)) {
        _selectedIds.remove(option.id);
        return;
      }
      final byId = {for (final o in allOptions) o.id: o};
      _selectedIds.removeWhere((id) {
        final o = byId[id];
        return o != null &&
            o.type == AncillaryType.SEAT &&
            o.segmentId == option.segmentId &&
            o.paxRef == option.paxRef;
      });
      _selectedIds.add(option.id);
    });
  }

  void _continue(BuildContext context) {
    context.read<FlightBookingBloc>().add(AncillaryOptionsConfirmed(_selectedIds));
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PassengerInfoScreen()));
  }

  int? _travelerNumber(String? paxRef) {
    if (paxRef == null) return null;
    final digits = paxRef.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Options additionnelles', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<FlightBookingBloc, FlightBookingState>(
        builder: (context, state) {
          final options = state.ancillaryOptions;
          if (options == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final travelerCount = state.passengerTypes.length;
          final seatOptions = options.where((o) => o.type == AncillaryType.SEAT).toList();
          final segmentIds = <String>{for (final o in seatOptions) o.segmentId ?? ''}.toList();
          final baggageOptions = options.where((o) => o.type == AncillaryType.BAGGAGE).toList();
          final mealOptions = options.where((o) => o.type == AncillaryType.MEAL).toList();
          final insuranceOptions = options.where((o) => o.type == AncillaryType.INSURANCE).toList();

          final selectedTotal = options
              .where((o) => _selectedIds.contains(o.id))
              .fold<double>(0, (sum, o) => sum + o.price.amount);
          final currency = options.isNotEmpty ? options.first.price.currency : 'XAF';

          if (options.isEmpty) {
            return Column(
              children: [
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        "Aucune option additionnelle disponible pour ce vol.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                _buildFooter(context, 0, 'XAF'),
              ],
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (segmentIds.isNotEmpty) ...[
                        _sectionHeader(Icons.event_seat_rounded, 'Sièges'),
                        const SizedBox(height: 8),
                        ...segmentIds.map(
                          (segmentId) => _SeatGridSection(
                            seatOptions: seatOptions.where((o) => (o.segmentId ?? '') == segmentId).toList(),
                            travelerCount: travelerCount,
                            selectedIds: _selectedIds,
                            onToggle: (option) => _toggleSeat(option, options),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (baggageOptions.isNotEmpty)
                        _buildToggleSection(Icons.luggage_rounded, 'Bagages', baggageOptions),
                      if (mealOptions.isNotEmpty)
                        _buildToggleSection(Icons.restaurant_rounded, 'Repas', mealOptions),
                      if (insuranceOptions.isNotEmpty)
                        _buildToggleSection(Icons.shield_rounded, 'Assurance', insuranceOptions),
                    ],
                  ),
                ),
              ),
              _buildFooter(context, selectedTotal, currency),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade900),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildToggleSection(IconData icon, String title, List<AncillaryOption> sectionOptions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon, title),
          const SizedBox(height: 10),
          ...sectionOptions.map((option) {
            final selected = _selectedIds.contains(option.id);
            final travelerNumber = _travelerNumber(option.paxRef);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggle(option.id),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? Colors.blue.shade900 : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                    color: selected ? Colors.blue.shade50 : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: selected ? Colors.blue.shade900 : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(option.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              travelerNumber != null ? 'Pour le voyageur $travelerNumber' : 'Pour tous les voyageurs',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Text(option.price.format(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, double total, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total > 0 ? Money(amount: total, currency: currency).format() : '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${_selectedIds.length} option(s) sélectionnée(s)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _continue(context),
            child: const Text('Passer', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _continue(context),
            child: const Text('Continuer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// La grille cabine réelle d'un segment (lignes/colonnes/couloir depuis
/// seatLayout, tarifée par siège). Plus d'un voyageur => onglets pour changer
/// quel voyageur (prix/dispo différents par personne, tarification fournisseur
/// au passager). Composant à état propre (comme SeatGrid côté Next.js).
class _SeatGridSection extends StatefulWidget {
  final List<AncillaryOption> seatOptions;
  final int travelerCount;
  final List<String> selectedIds;
  final void Function(AncillaryOption option) onToggle;

  const _SeatGridSection({
    required this.seatOptions,
    required this.travelerCount,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_SeatGridSection> createState() => _SeatGridSectionState();
}

class _SeatGridSectionState extends State<_SeatGridSection> {
  int _activeTraveler = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.seatOptions.isEmpty) return const SizedBox.shrink();

    SeatLayout? layout;
    for (final o in widget.seatOptions) {
      if (o.seatLayout != null) {
        layout = o.seatLayout;
        break;
      }
    }
    if (layout == null || layout.totalRows <= 0) return const SizedBox.shrink();

    final columns = layout.seatGroups.isNotEmpty ? layout.seatGroups.join('').split('') : <String>[];
    final halfColumns = (columns.length / 2).ceil();
    final activePaxRef = 'T${_activeTraveler + 1}';
    final byCode = <String, AncillaryOption>{
      for (final o in widget.seatOptions.where((o) => o.paxRef == activePaxRef)) (o.code ?? ''): o,
    };

    AncillaryOption? selectedForActive;
    for (final o in widget.seatOptions) {
      if (o.paxRef == activePaxRef && widget.selectedIds.contains(o.id)) {
        selectedForActive = o;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.travelerCount > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.travelerCount, (i) {
                  final isActive = i == _activeTraveler;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Voyageur ${i + 1}'),
                      selected: isActive,
                      onSelected: (_) => setState(() => _activeTraveler = i),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: List.generate(layout.totalRows, (rowIndex) {
                final rowNum = rowIndex + 1;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('$rowNum', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ),
                    ...List.generate(columns.length, (colIdx) {
                      final column = columns[colIdx];
                      final code = '$rowNum$column';
                      final option = byCode[code];
                      final selected = option != null && widget.selectedIds.contains(option.id);
                      final available = option != null;
                      final seatWidget = GestureDetector(
                        onTap: available ? () => widget.onToggle(option) : null,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: !available
                                ? Colors.grey.shade200
                                : (selected ? Colors.blue.shade900 : Colors.blue.shade50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              column,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : (available ? Colors.blue.shade900 : Colors.grey.shade400),
                              ),
                            ),
                          ),
                        ),
                      );
                      if (colIdx == halfColumns) {
                        return Row(children: [const SizedBox(width: 14), seatWidget]);
                      }
                      return seatWidget;
                    }),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedForActive != null
                ? 'Voyageur ${_activeTraveler + 1} — ${selectedForActive.label} — ${selectedForActive.price.format()}'
                : 'Aucun siège choisi pour le voyageur ${_activeTraveler + 1}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
