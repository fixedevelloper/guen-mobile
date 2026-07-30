import 'package:equatable/equatable.dart';

/// Reflète l'énumération ProviderType du backend Spring Boot
enum ProviderType {
  SABRE,
  AMADEUS,
  TRAVELPORT,
  LOCAL_CHARTER,
  UNKNOWN;

  static ProviderType fromString(String value) {
    return ProviderType.values.firstWhere(
          (e) => e.name == value.toUpperCase(),
      orElse: () => ProviderType.UNKNOWN,
    );
  }
}

/// Reflète la classe partagée com.guentours.shared.Money
class Money extends Equatable {
  final double amount;
  final String currency;

  const Money({
    required this.amount,
    required this.currency,
  });

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'XAF',
    );
  }

  @override
  String toString() => '${amount.toStringAsFixed(0)} $currency';

  @override
  List<Object?> get props => [amount, currency];
}

/// Reflète le Record com.guentours.search.ProviderQuote
class ProviderQuote extends Equatable {
  final String offerId;
  final ProviderType providerType;
  final Money price;

  const ProviderQuote({
    required this.offerId,
    required this.providerType,
    required this.price,
  });

  factory ProviderQuote.fromJson(Map<String, dynamic> json) {
    return ProviderQuote(
      offerId: json['offerId'] as String? ?? '',
      providerType: ProviderType.fromString(json['providerType'] as String? ?? ''),
      price: Money.fromJson(json['price'] as Map<String, dynamic>? ?? const {}),
    );
  }

  @override
  List<Object?> get props => [offerId, providerType, price];
}

/// Modèle principal HarmonizedFlightOffer
class HarmonizedFlightOffer extends Equatable {
  final String airline;
  final String flightNumber;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String cabinClass;
  final int seatsAvailable;
  final String bestOfferId;
  final List<ProviderQuote> quotes;

  const HarmonizedFlightOffer({
    required this.airline,
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
      flightNumber: json['flightNumber'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      cabinClass: json['cabinClass'] as String? ?? 'ECONOMY',
      seatsAvailable: json['seatsAvailable'] as int? ?? 0,
      bestOfferId: json['bestOfferId'] as String? ?? '',
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => ProviderQuote.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
    airline,
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