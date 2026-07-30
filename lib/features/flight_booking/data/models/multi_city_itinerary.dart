import 'package:equatable/equatable.dart';

enum ProviderType { SABRE, AMADEUS, KIWI, LOCAL_AGENCY } // Aligne les enums avec ton backend Java

class MultiCityItinerary {
  final ProviderType providerType;
  final Money totalPrice;
  final List<MultiCityItineraryLeg> legs;

  MultiCityItinerary({
    required this.providerType,
    required this.totalPrice,
    required this.legs,
  });

  factory MultiCityItinerary.fromJson(Map<String, dynamic> json) {
    return MultiCityItinerary(
      providerType: ProviderType.values.firstWhere(
            (e) => e.name == json['providerType'],
        orElse: () => ProviderType.LOCAL_AGENCY, // Valeur de repli sécurisée
      ),
      totalPrice: Money.fromJson(json['totalPrice']),
      legs: (json['legs'] as List)
          .map((legJson) => MultiCityItineraryLeg.fromJson(legJson))
          .toList(),
    );
  }
}

class Money {
  final double amount;
  final String currency;

  Money({required this.amount, required this.currency});

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'XAF',
    );
  }
}

/// Représente un segment (leg) individuel d'un itinéraire combiné MULTI_CITY,
/// mappé directement sur le Record Java 'MultiCityItineraryLeg'.
class MultiCityItineraryLeg extends Equatable {
  final int legIndex;
  final String airline;
  final String flightNumber;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String cabinClass;

  /// Identifiant unique de l'offre pour ce segment spécifique à renvoyer au
  /// backend lors de la phase de validation ou de booking.
  final String offerId;

  const MultiCityItineraryLeg({
    required this.legIndex,
    required this.airline,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.cabinClass,
    required this.offerId,
  });

  /// Désérialisation basée sur les clés exactes de ton Record Java compilé en JSON
  factory MultiCityItineraryLeg.fromJson(Map<String, dynamic> json) {
    return MultiCityItineraryLeg(
      legIndex: json['legIndex'] as int? ?? 0,
      airline: json['airline'] as String? ?? 'N/A',
      flightNumber: json['flightNumber'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      // Parsing direct des ISO-8601 strings générées par LocalDateTime
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'] as String)
          : DateTime.now(),
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'] as String)
          : DateTime.now(),
      cabinClass: json['cabinClass'] as String? ?? 'ECONOMY',
      offerId: json['offerId'] as String? ?? '',
    );
  }

  /// Utile pour sérialiser à nouveau si tu dois stocker localement
  Map<String, dynamic> toJson() {
    return {
      'legIndex': legIndex,
      'airline': airline,
      'flightNumber': flightNumber,
      'origin': origin,
      'destination': destination,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'cabinClass': cabinClass,
      'offerId': offerId,
    };
  }

  @override
  List<Object?> get props => [
    legIndex,
    airline,
    flightNumber,
    origin,
    destination,
    departureTime,
    arrivalTime,
    cabinClass,
    offerId,
  ];
}