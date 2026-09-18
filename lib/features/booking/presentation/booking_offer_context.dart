import '../../../core/models/provider_quote.dart';

/// Contexte minimal transmis depuis un écran de résultats (hôtel, véhicule,
/// meublé) vers le tunnel de réservation générique : l'offre choisie
/// (`offerId` d'une [ProviderQuote]), son type backend, et de quoi afficher
/// un récapitulatif sans re-fetcher la recherche.
class BookingOfferContext {
  final String offerId;
  final String offerType; // 'HOTEL' | 'CAR_RENTAL' | 'FURNISHED_RENTAL'
  final String title;
  final String subtitle;
  final Money price;
  final bool isHotel;

  const BookingOfferContext({
    required this.offerId,
    required this.offerType,
    required this.title,
    required this.subtitle,
    required this.price,
    this.isHotel = false,
  });
}
