import 'package:flutter/material.dart';
import '../../../../core/models/provider_quote.dart';
import '../../../../core/widgets/quote_price_section.dart';
import '../../../booking/presentation/booking_offer_context.dart';
import '../../../booking/presentation/pages/booking_contact_screen.dart';
import '../../data/models/harmonized_vehicle_offer.dart';

class VehicleResultsScreen extends StatelessWidget {
  final List<HarmonizedVehicleOffer> offers;

  const VehicleResultsScreen({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${offers.length} véhicule(s) trouvé(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: offers.isEmpty
          ? const Center(child: Text('Aucun véhicule disponible pour ces critères.'))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${offer.brand} ${offer.model}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(offer.category, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _infoChip(Icons.people_outline_rounded, '${offer.seats} places'),
                    _infoChip(Icons.settings_outlined, offer.transmission),
                    if (offer.airConditioning) _infoChip(Icons.ac_unit_rounded, 'Climatisation'),
                    if (offer.withDriver) _infoChip(Icons.person_pin_circle_outlined, 'Avec chauffeur'),
                  ],
                ),
                const SizedBox(height: 14),
                QuotePriceSection(
                  quotes: offer.quotes,
                  highlightColor: secondaryColor,
                  priceLabel: 'Total séjour',
                  onQuoteSelected: (quote) => _bookOffer(context, offer, quote),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _bookOffer(BuildContext context, HarmonizedVehicleOffer offer, ProviderQuote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingContactScreen(
          offer: BookingOfferContext(
            offerId: quote.offerId,
            offerType: 'CAR_RENTAL',
            title: '${offer.brand} ${offer.model}',
            subtitle: '${offer.pickupCity} → ${offer.dropoffCity}',
            price: quote.price,
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
