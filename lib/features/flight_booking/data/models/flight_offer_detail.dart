import 'package:equatable/equatable.dart';
import '../../../../core/models/provider_quote.dart';

/// Reflète com.guentours.provider.AirportInfo — un point (départ ou arrivée)
/// d'un FlightSegmentDetail.
class AirportInfo extends Equatable {
  final String code;
  final String? name;
  final String? city;
  final String? terminal;

  const AirportInfo({required this.code, this.name, this.city, this.terminal});

  factory AirportInfo.fromJson(Map<String, dynamic> json) {
    return AirportInfo(
      code: json['code'] as String? ?? '',
      name: json['name'] as String?,
      city: json['city'] as String?,
      terminal: json['terminal'] as String?,
    );
  }

  @override
  List<Object?> get props => [code, name, city, terminal];
}

/// Reflète com.guentours.provider.BaggageRule — franchise bagage d'un type de
/// passager sur un segment. `rule` est du texte libre fournisseur (ex: "23 Kgs",
/// "1 piece") - gardé tel quel plutôt que parsé, le format n'est pas garanti
/// homogène d'un fournisseur/route/tarif à l'autre.
class BaggageRule extends Equatable {
  final String paxType;
  final String rule;
  final int? quantity;
  final String? size;

  const BaggageRule({required this.paxType, required this.rule, this.quantity, this.size});

  factory BaggageRule.fromJson(Map<String, dynamic> json) {
    return BaggageRule(
      paxType: json['paxType'] as String? ?? '',
      rule: json['rule'] as String? ?? '',
      quantity: json['quantity'] as int?,
      size: json['size'] as String?,
    );
  }

  @override
  List<Object?> get props => [paxType, rule, quantity, size];
}

/// Reflète com.guentours.provider.FlightSegmentDetail — un segment physique de
/// vol. Deux segments ou plus pour un même trajet signifient une escale entre
/// `departure` et l'`arrival` du segment précédent (`layoverAfter` est la
/// durée de cette escale, déjà formatée par le fournisseur, ex: "2h 45m").
class FlightSegmentDetail extends Equatable {
  final String airlineCode;
  final String? airlineName;
  final String flightNumber;
  final String? cabinClass;
  final AirportInfo departure;
  final AirportInfo arrival;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String? duration;
  final String? layoverAfter;
  final List<BaggageRule> cabinBaggage;
  final List<BaggageRule> checkedBaggage;

  const FlightSegmentDetail({
    required this.airlineCode,
    this.airlineName,
    required this.flightNumber,
    this.cabinClass,
    required this.departure,
    required this.arrival,
    required this.departureTime,
    required this.arrivalTime,
    this.duration,
    this.layoverAfter,
    this.cabinBaggage = const [],
    this.checkedBaggage = const [],
  });

  factory FlightSegmentDetail.fromJson(Map<String, dynamic> json) {
    return FlightSegmentDetail(
      airlineCode: json['airlineCode'] as String? ?? '',
      airlineName: json['airlineName'] as String?,
      flightNumber: json['flightNumber'] as String? ?? '',
      cabinClass: json['cabinClass'] as String?,
      departure: AirportInfo.fromJson(json['departure'] as Map<String, dynamic>? ?? const {}),
      arrival: AirportInfo.fromJson(json['arrival'] as Map<String, dynamic>? ?? const {}),
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      duration: json['duration'] as String?,
      layoverAfter: json['layoverAfter'] as String?,
      cabinBaggage: (json['cabinBaggage'] as List<dynamic>?)
              ?.map((e) => BaggageRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checkedBaggage: (json['checkedBaggage'] as List<dynamic>?)
              ?.map((e) => BaggageRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
        airlineCode,
        airlineName,
        flightNumber,
        cabinClass,
        departure,
        arrival,
        departureTime,
        arrivalTime,
        duration,
        layoverAfter,
        cabinBaggage,
        checkedBaggage,
      ];
}

/// Reflète com.guentours.provider.FlightOfferDetail — détail propre à un
/// fournisseur/tarif (escales, bagages, disponibilité du hold). Null pour un
/// fournisseur qui ne l'expose pas (seul TravelTerminus le fait aujourd'hui).
class FlightOfferDetail extends Equatable {
  final bool? holdAvailable;
  final String? totalDuration;
  final String? totalLayoverDuration;
  final List<FlightSegmentDetail> segments;

  const FlightOfferDetail({
    this.holdAvailable,
    this.totalDuration,
    this.totalLayoverDuration,
    this.segments = const [],
  });

  factory FlightOfferDetail.fromJson(Map<String, dynamic> json) {
    return FlightOfferDetail(
      holdAvailable: json['holdAvailable'] as bool?,
      totalDuration: json['totalDuration'] as String?,
      totalLayoverDuration: json['totalLayoverDuration'] as String?,
      segments: (json['segments'] as List<dynamic>?)
              ?.map((e) => FlightSegmentDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [holdAvailable, totalDuration, totalLayoverDuration, segments];
}

/// Reflète com.guentours.search.domain.FlightProviderQuote — comme
/// [ProviderQuote], avec en plus `detail` (escales/bagages/hold), null pour un
/// fournisseur qui ne le fournit pas.
class FlightProviderQuote extends ProviderQuote {
  final FlightOfferDetail? detail;

  const FlightProviderQuote({
    required super.offerId,
    required super.providerType,
    required super.price,
    this.detail,
  });

  factory FlightProviderQuote.fromJson(Map<String, dynamic> json) {
    return FlightProviderQuote(
      offerId: json['offerId'] as String? ?? '',
      providerType: ProviderType.fromString(json['providerType'] as String? ?? ''),
      price: Money.fromJson(json['price'] as Map<String, dynamic>? ?? const {}),
      detail: json['detail'] != null
          ? FlightOfferDetail.fromJson(json['detail'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [...super.props, detail];
}
