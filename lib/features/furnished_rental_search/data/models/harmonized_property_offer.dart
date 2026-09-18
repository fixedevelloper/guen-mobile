import 'package:equatable/equatable.dart';
import '../../../../core/models/provider_quote.dart';

/// Reflète com.guentours.search.domain.HarmonizedPropertyOffer.
class HarmonizedPropertyOffer extends Equatable {
  final String title;
  final String propertyType;
  final String city;
  final String country;
  final int bedrooms;
  final int maxGuests;
  final bool entirePlace;
  final DateTime checkIn;
  final DateTime checkOut;
  final String bestOfferId;
  final List<ProviderQuote> quotes;

  const HarmonizedPropertyOffer({
    required this.title,
    required this.propertyType,
    required this.city,
    required this.country,
    required this.bedrooms,
    required this.maxGuests,
    required this.entirePlace,
    required this.checkIn,
    required this.checkOut,
    required this.bestOfferId,
    required this.quotes,
  });

  factory HarmonizedPropertyOffer.fromJson(Map<String, dynamic> json) {
    return HarmonizedPropertyOffer(
      title: json['title'] as String? ?? '',
      propertyType: json['propertyType'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      bedrooms: json['bedrooms'] as int? ?? 0,
      maxGuests: json['maxGuests'] as int? ?? 0,
      entirePlace: json['entirePlace'] as bool? ?? false,
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      bestOfferId: json['bestOfferId'] as String? ?? '',
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => ProviderQuote.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  @override
  List<Object?> get props => [title, propertyType, city, country, bedrooms, maxGuests, entirePlace, checkIn, checkOut, bestOfferId, quotes];
}
