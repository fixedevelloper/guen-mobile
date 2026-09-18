import 'package:flutter/material.dart';
import '../../../../core/models/provider_quote.dart';
import '../../../../core/widgets/quote_price_section.dart';
import '../../../booking/presentation/booking_offer_context.dart';
import '../../../booking/presentation/pages/booking_contact_screen.dart';
import '../../data/models/harmonized_property_offer.dart';

class PropertyResultsScreen extends StatelessWidget {
  final List<HarmonizedPropertyOffer> offers;

  const PropertyResultsScreen({super.key, required this.offers});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${offers.length} logement(s) trouvé(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: offers.isEmpty
          ? const Center(child: Text('Aucun logement disponible pour ces critères.'))
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
                    Expanded(child: Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(offer.propertyType, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('${offer.city}, ${offer.country}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _infoChip(Icons.bed_rounded, '${offer.bedrooms} chambre(s)'),
                    _infoChip(Icons.people_outline_rounded, '${offer.maxGuests} pers. max'),
                    if (offer.entirePlace) _infoChip(Icons.home_rounded, 'Logement entier'),
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

  void _bookOffer(BuildContext context, HarmonizedPropertyOffer offer, ProviderQuote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingContactScreen(
          offer: BookingOfferContext(
            offerId: quote.offerId,
            offerType: 'FURNISHED_RENTAL',
            title: offer.title,
            subtitle: '${offer.city}, ${offer.country}',
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
