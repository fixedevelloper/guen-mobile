import 'package:flutter/material.dart';
import '../../../../core/models/booking_response.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingResponse booking;
  // `booking` est capturé juste après le checkout (status PENDING_PAYMENT) ;
  // le paiement fait transitionner le statut côté serveur sans que ce client
  // ne le re-fetch. `paymentConfirmed` permet à l'appelant qui vient de voir
  // le paiement réussir de refléter ça sans dépendre du statut figé.
  final bool paymentConfirmed;

  const BookingConfirmationScreen({super.key, required this.booking, this.paymentConfirmed = false});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isConfirmed = paymentConfirmed ||
        booking.status == 'CONFIRMED' || booking.status == 'PAID' || booking.status == 'CONFIRMING';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: secondaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(
                  isConfirmed ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                  color: secondaryColor,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isConfirmed ? 'Réservation confirmée !' : 'Paiement reçu — confirmation en cours',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitleFor(booking),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _row('Référence', booking.id),
                    if (booking.providerConfirmationNumber != null)
                      _row('N° de confirmation', booking.providerConfirmationNumber!),
                    if (booking.price != null) _row('Montant total', booking.price!.format()),
                    _row('Contact', booking.contactEmail),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Retour à l\'accueil', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleFor(BookingResponse b) {
    switch (b.offerType) {
      case 'HOTEL':
        return b.hotelName ?? 'Votre séjour est enregistré.';
      case 'CAR_RENTAL':
        return [b.vehicleBrand, b.vehicleModel].where((e) => e != null).join(' ').isNotEmpty
            ? '${b.vehicleBrand} ${b.vehicleModel}'
            : 'Votre location est enregistrée.';
      case 'FURNISHED_RENTAL':
        return b.propertyTitle ?? 'Votre logement est enregistré.';
      default:
        return 'Votre réservation est enregistrée.';
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
