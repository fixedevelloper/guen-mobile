import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_state.dart';
import '../../../../core/models/booking_response.dart';

class BoardingPassScreen extends StatelessWidget {
  const BoardingPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocBuilder<FlightBookingBloc, FlightBookingState>(
      builder: (context, state) {
        final booking = state.confirmedBooking;
        final isMultiCity = booking != null && booking.itineraryLegs.isNotEmpty;

        final origin = isMultiCity ? booking.itineraryLegs.first.origin : (booking?.origin ?? state.departure ?? '—');
        final destination = isMultiCity ? booking.itineraryLegs.last.destination : (booking?.destination ?? state.destination ?? '—');
        final airline = isMultiCity ? booking.itineraryLegs.first.airline : (booking?.airline ?? '—');
        final flightNumber = isMultiCity ? booking.itineraryLegs.first.flightNumber : (booking?.flightNumber ?? '—');
        final departureTime = isMultiCity ? booking.itineraryLegs.first.departureTime : booking?.departureTime;
        final passengerName = booking != null && booking.travelers.isNotEmpty ? booking.travelers.first.fullName : '—';
        final seatCodes = state.selectedSeatCodesByTraveler;
        final seat = booking != null && booking.travelers.isNotEmpty && booking.travelers.first.seatNumber != null
            ? booking.travelers.first.seatNumber!
            : (seatCodes.isNotEmpty ? seatCodes.first : '—');
        final reference = booking?.providerConfirmationNumber ?? booking?.id ?? '—';

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text('Carte d\'embarquement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            centerTitle: true,
            backgroundColor: primaryColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (booking == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Paiement confirmé. Les détails de votre réservation seront disponibles sous peu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildAirportCode(origin, Colors.white, CrossAxisAlignment.start),
                                Icon(Icons.flight_takeoff_rounded, color: secondaryColor, size: 28),
                                _buildAirportCode(destination, Colors.white, CrossAxisAlignment.end),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTicketMeta('COMPAGNIE', flightNumber == '—' ? airline : '$airline ($flightNumber)', Colors.white),
                                _buildTicketMeta('CLASSE', booking?.fareClass ?? '—', Colors.white),
                                _buildTicketMeta('DATE', _formatDate(departureTime), Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: List.generate(20, (index) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Container(height: 1, color: Colors.grey.shade300),
                            ),
                          )),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTicketMeta('PASSAGER', passengerName, Colors.black87),
                                _buildTicketMeta('SIÈGE', seat, Colors.black87),
                                _buildTicketMeta('STATUT', booking?.status ?? '—', Colors.black87),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'RÉF. RÉSERVATION : $reference',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11, letterSpacing: 1.2),
                            ),
                            if (booking != null && booking.eTicketNumbers.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'E-TICKET : ${booking.eTicketNumbers.join(', ')}',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11, letterSpacing: 1.2),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMultiCity) ...[
                  const SizedBox(height: 24),
                  _buildLegsList(booking.itineraryLegs),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                    label: const Text('Retour à l\'accueil', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegsList(List<BookingFlightLeg> legs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Segments de l\'itinéraire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...legs.map((leg) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text('${leg.origin} → ${leg.destination}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Text('${leg.airline} ${leg.flightNumber}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(width: 8),
                Text(_formatDate(leg.departureTime), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildAirportCode(String code, Color textColor, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(code, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: textColor)),
      ],
    );
  }

  Widget _buildTicketMeta(String label, String value, Color baseColor) {
    final isWhite = baseColor == Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isWhite ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: baseColor)),
      ],
    );
  }
}
