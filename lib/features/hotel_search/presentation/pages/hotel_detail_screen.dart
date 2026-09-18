import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/provider_quote.dart';
import '../../../booking/presentation/booking_offer_context.dart';
import '../../../booking/presentation/pages/booking_contact_screen.dart';
import '../../data/datasources/hotel_api_client.dart';
import '../../data/models/harmonized_hotel_offer.dart';
import '../../data/models/hotel_detail.dart';
import '../../data/models/room_offer.dart';

class HotelDetailScreen extends StatefulWidget {
  final HarmonizedHotelOffer offer;

  const HotelDetailScreen({super.key, required this.offer});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late Future<(HotelDetail, List<RoomOffer>)> _future;
  bool _showAllReviews = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(HotelDetail, List<RoomOffer>)> _load() {
    final apiClient = sl<HotelApiClient>();
    final offerId = widget.offer.bestOfferId;
    return Future.wait([
      apiClient.getHotelDetail(offerId),
      apiClient.getHotelRooms(offerId),
    ]).then((results) => (results[0] as HotelDetail, results[1] as List<RoomOffer>));
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.offer.hotelName, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<(HotelDetail, List<RoomOffer>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    const Text('Cette offre n\'est plus disponible.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _retry, child: const Text('Réessayer')),
                  ],
                ),
              ),
            );
          }
          final (detail, rooms) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (detail.address != null || detail.city != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(child: Text([detail.address, detail.city, detail.country].where((e) => e != null && e.isNotEmpty).join(', '),
                        style: TextStyle(color: Colors.grey.shade600))),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (detail.hotelReview != null && detail.hotelReview!.rating != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Text(detail.hotelReview!.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      const SizedBox(width: 8),
                      Text(detail.hotelReview!.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (detail.hotelReview!.numReviews != null) ...[
                        const SizedBox(width: 8),
                        Text('(${detail.hotelReview!.numReviews} avis)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                if ((detail.hotelReview!.rankingString ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail.hotelReview!.rankingString!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
                if (detail.hotelReview!.namedSubRatings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSubRatings(detail.hotelReview!.namedSubRatings),
                ],
                const SizedBox(height: 16),
              ],
              if (detail.description != null && detail.description!.isNotEmpty) ...[
                Text(detail.description!, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 16),
              ],
              if (detail.facilities.isNotEmpty) ...[
                const Text('Équipements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: detail.facilities.map((f) => Chip(label: Text(f, style: const TextStyle(fontSize: 12)))).toList(),
                ),
                const SizedBox(height: 24),
              ],
              const Text('Chambres disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (rooms.isEmpty) const Text('Aucune chambre disponible pour cette offre.'),
              ...rooms.map((room) => _buildRoomCard(context, room, secondaryColor)),
              if (detail.hotelReview != null && detail.hotelReview!.reviews.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildReviewsSection(detail.hotelReview!.reviews),
              ],
            ],
          );
        },
      ),
    );
  }

  void _bookRoom(BuildContext context, RoomOffer room) {
    // Le checkout se résout côté backend via l'offerId de la recherche
    // d'origine (widget.offer.bestOfferId) — la chambre choisie ne sert
    // qu'à l'affichage du prix ici, comme sur le frontend Next.js.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingContactScreen(
          offer: BookingOfferContext(
            offerId: widget.offer.bestOfferId,
            offerType: 'HOTEL',
            title: widget.offer.hotelName,
            subtitle: room.roomType ?? widget.offer.roomType,
            price: Money(amount: room.netPrice, currency: room.currency),
            isHotel: true,
          ),
        ),
      ),
    );
  }

  Widget _buildSubRatings(List<(String, double)> ratings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ratings.map((entry) {
        final (label, value) = entry;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (value / 10).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewsSection(List<HotelReview> reviews) {
    final visible = _showAllReviews ? reviews : reviews.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avis (${reviews.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...visible.map(_buildReviewCard),
        if (!_showAllReviews && reviews.length > visible.length)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAllReviews = true),
              child: Text('Voir les ${reviews.length - visible.length} autres avis'),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(HotelReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              if (review.rating != null)
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < review.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 15,
                      color: Colors.amber,
                    );
                  }),
                ),
              const SizedBox(width: 8),
              if (review.tripType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(review.tripType!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.title!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
          if (review.text != null && review.text!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.text!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(
            [
              if (review.username != null) review.username,
              if (review.userLocationName != null) review.userLocationName,
              if (review.publishedDate != null) review.publishedDate,
            ].whereType<String>().join(' · '),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomOffer room, Color highlightColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.roomType ?? 'Chambre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (room.boardType != null) ...[
            const SizedBox(height: 4),
            Text(room.boardType!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
          if (room.parsedMaxOccupancy != null) ...[
            const SizedBox(height: 4),
            Text('Jusqu\'à ${room.parsedMaxOccupancy} personne(s)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${room.netPrice.toStringAsFixed(0)} ${room.currency}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: highlightColor)),
              OutlinedButton(
                onPressed: () => _bookRoom(context, room),
                child: const Text('Choisir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
