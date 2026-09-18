import 'package:equatable/equatable.dart';
import '../../../../core/models/provider_quote.dart';
import 'flight_offer_detail.dart';

export '../../../../core/models/provider_quote.dart' show ProviderType, Money, ProviderQuote;
export 'flight_offer_detail.dart';

/// Modèle principal HarmonizedFlightOffer
class HarmonizedFlightOffer extends Equatable {
  final String airline;
  final String? airlineName;
  final String flightNumber;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String cabinClass;
  final int seatsAvailable;
  final String bestOfferId;
  final List<FlightProviderQuote> quotes;

  /// Nom d'affichage de la compagnie : `airlineName` si le fournisseur l'a
  /// fourni, sinon le code IATA brut (même repli que `airlineLabel(offer.airline)`
  /// côté Next.js pour un code non résolu).
  String get displayAirlineName => (airlineName != null && airlineName!.isNotEmpty) ? airlineName! : airline;

  /// La quote correspondant à [bestOfferId] (résolu côté serveur) ; retombe
  /// sur la moins chère si elle n'est pas retrouvée parmi [quotes].
  FlightProviderQuote? get bestQuote {
    if (quotes.isEmpty) return null;
    return quotes.firstWhere(
          (q) => q.offerId == bestOfferId,
      orElse: () => sortedByPrice(quotes).first as FlightProviderQuote,
    );
  }

  const HarmonizedFlightOffer({
    required this.airline,
    this.airlineName,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.cabinClass,
    required this.seatsAvailable,
    required this.bestOfferId,
    required this.quotes,
  });

  factory HarmonizedFlightOffer.fromJson(Map<String, dynamic> json) {
    return HarmonizedFlightOffer(
      airline: json['airline'] as String? ?? '',
      airlineName: json['airlineName'] as String?,
      flightNumber: json['flightNumber'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      cabinClass: json['cabinClass'] as String? ?? 'ECONOMY',
      seatsAvailable: json['seatsAvailable'] as int? ?? 0,
      bestOfferId: json['bestOfferId'] as String? ?? '',
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => FlightProviderQuote.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
    airline,
    airlineName,
    flightNumber,
    origin,
    destination,
    departureTime,
    arrivalTime,
    cabinClass,
    seatsAvailable,
    bestOfferId,
    quotes,
  ];
}
