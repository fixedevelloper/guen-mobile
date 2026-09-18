import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/provider_quote.dart';
import '../../../../core/widgets/quote_price_section.dart';
import '../../../booking/presentation/booking_offer_context.dart';
import '../../../booking/presentation/pages/booking_contact_screen.dart';
import '../../data/models/harmonized_hotel_offer.dart';
import '../cubit/hotel_search_cubit.dart';
import '../cubit/hotel_search_state.dart';
import 'hotel_detail_screen.dart';

class HotelResultsScreen extends StatelessWidget {
  const HotelResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocBuilder<HotelSearchCubit, HotelSearchState>(
      builder: (context, state) {
        final offers = state.offers;
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text('${offers.length} hôtel(s) trouvé(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: offers.isEmpty
              ? const Center(child: Text('Aucun hôtel disponible pour ces critères.'))
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (state.hasMore &&
                        !state.isLoadingMore &&
                        notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                      context.read<HotelSearchCubit>().loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: offers.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= offers.length) {
                        return _buildLoadMoreFooter(context, state);
                      }
                      final offer = offers[index];
                      final nights = offer.checkOut.difference(offer.checkIn).inDays.clamp(1, 999);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HotelDetailScreen(offer: offer)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCover(offer),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(offer.hotelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                              const SizedBox(width: 2),
                                              Text(offer.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(offer.cityCode, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                        const SizedBox(width: 12),
                                        Text(offer.roomType, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    QuotePriceSection(
                                      quotes: offer.quotes,
                                      highlightColor: secondaryColor,
                                      priceLabel: '$nights nuit(s)',
                                      onQuoteSelected: (quote) => _bookOffer(context, offer, quote),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLoadMoreFooter(BuildContext context, HotelSearchState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton(
          onPressed: () => context.read<HotelSearchCubit>().loadMore(),
          child: const Text('Charger plus d\'hôtels'),
        ),
      ),
    );
  }

  void _bookOffer(BuildContext context, HarmonizedHotelOffer offer, ProviderQuote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingContactScreen(
          offer: BookingOfferContext(
            offerId: quote.offerId,
            offerType: 'HOTEL',
            title: offer.hotelName,
            subtitle: offer.roomType,
            price: quote.price,
            isHotel: true,
          ),
        ),
      ),
    );
  }

  Widget _buildCover(HarmonizedHotelOffer offer) {
    if (offer.coverImageUrl != null && offer.coverImageUrl!.isNotEmpty) {
      return Image.network(offer.coverImageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(offer.hotelName));
    }
    return _placeholder(offer.hotelName);
  }

  Widget _placeholder(String name) {
    final hue = (name.codeUnits.fold<int>(0, (a, b) => a + b) % 360).toDouble();
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(color: HSLColor.fromAHSL(1, hue, 0.45, 0.7).toColor()),
      child: const Center(child: Icon(Icons.business_rounded, color: Colors.white, size: 36)),
    );
  }
}
