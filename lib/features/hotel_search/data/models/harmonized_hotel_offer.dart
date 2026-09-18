import 'package:equatable/equatable.dart';
import '../../../../core/models/provider_quote.dart';

/// Reflète com.guentours.search.domain.HarmonizedHotelOffer.
class HarmonizedHotelOffer extends Equatable {
  final String hotelName;
  final String cityCode;
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final double rating;
  final String? coverImageUrl;
  final String bestOfferId;
  final List<ProviderQuote> quotes;

  const HarmonizedHotelOffer({
    required this.hotelName,
    required this.cityCode,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.rating,
    required this.coverImageUrl,
    required this.bestOfferId,
    required this.quotes,
  });

  factory HarmonizedHotelOffer.fromJson(Map<String, dynamic> json) {
    return HarmonizedHotelOffer(
      hotelName: json['hotelName'] as String? ?? '',
      cityCode: json['cityCode'] as String? ?? '',
      roomType: json['roomType'] as String? ?? '',
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      coverImageUrl: json['coverImageUrl'] as String?,
      bestOfferId: json['bestOfferId'] as String? ?? '',
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => ProviderQuote.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  @override
  List<Object?> get props => [hotelName, cityCode, roomType, checkIn, checkOut, rating, coverImageUrl, bestOfferId, quotes];
}
