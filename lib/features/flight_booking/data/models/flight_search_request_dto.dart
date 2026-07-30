import 'package:equatable/equatable.dart';

class FlightSearchRequestDto {
  final String origin;
  final String destination;
  final String departureDate; // Format 'YYYY-MM-DD'
  final String? returnDate;
  final int adults;
  final int children;
  final int infants;
  final String journeyType; // Ex: 'ONE_WAY', 'ROUND_TRIP'
  final String? cabinClass;
  final String? currency;

  const FlightSearchRequestDto({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    required this.journeyType,
    this.cabinClass,
    this.currency = 'XAF', // Devise locale par défaut
  });

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'departureDate': departureDate,
      if (returnDate != null) 'returnDate': returnDate,
      'adults': adults,
      'children': children,
      'infants': infants,
      'journeyType': journeyType,
      if (cabinClass != null) 'cabinClass': cabinClass,
      if (currency != null) 'currency': currency,
    };
  }
}
/// Représente un segment individuel (FlightLeg en Java)
class FlightLegDto extends Equatable {
  final String origin;
  final String destination;
  final String departureDate; // Déjà formatée en YYYY-MM-DD

  const FlightLegDto({
    required this.origin,
    required this.destination,
    required this.departureDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'departureDate': departureDate,
    };
  }

  @override
  List<Object?> get props => [origin, destination, departureDate];
}

/// Représente la requête globale Multi-City (MultiCityFlightSearchRequest en Java)
class MultiCityFlightSearchRequestDto extends Equatable {
  final List<FlightLegDto> legs;
  final int adults;
  final int children;
  final int infants;
  final String cabinClass;
  final String currency;

  const MultiCityFlightSearchRequestDto({
    required this.legs,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = 'ECONOMY',
    this.currency = 'XAF', // Par défaut pour la zone CEMAC / Cameroun
  });

  Map<String, dynamic> toJson() {
    return {
      'legs': legs.map((leg) => leg.toJson()).toList(),
      'adults': adults,
      'children': children,
      'infants': infants,
      'cabinClass': cabinClass,
      'currency': currency,
    };
  }

  @override
  List<Object?> get props => [legs, adults, children, infants, cabinClass, currency];
}