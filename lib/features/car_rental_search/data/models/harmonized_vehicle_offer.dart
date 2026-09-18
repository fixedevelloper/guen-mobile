import 'package:equatable/equatable.dart';
import '../../../../core/models/provider_quote.dart';

/// Reflète com.guentours.search.domain.HarmonizedVehicleOffer.
class HarmonizedVehicleOffer extends Equatable {
  final String brand;
  final String model;
  final String category;
  final String transmission;
  final int seats;
  final bool airConditioning;
  final String pickupCity;
  final String dropoffCity;
  final DateTime rentalStart;
  final String? pickupTime;
  final DateTime rentalEnd;
  final String? dropoffTime;
  final bool withDriver;
  final bool driverAge25Plus;
  final String bestOfferId;
  final List<ProviderQuote> quotes;

  const HarmonizedVehicleOffer({
    required this.brand,
    required this.model,
    required this.category,
    required this.transmission,
    required this.seats,
    required this.airConditioning,
    required this.pickupCity,
    required this.dropoffCity,
    required this.rentalStart,
    required this.pickupTime,
    required this.rentalEnd,
    required this.dropoffTime,
    required this.withDriver,
    required this.driverAge25Plus,
    required this.bestOfferId,
    required this.quotes,
  });

  factory HarmonizedVehicleOffer.fromJson(Map<String, dynamic> json) {
    return HarmonizedVehicleOffer(
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      category: json['category'] as String? ?? '',
      transmission: json['transmission'] as String? ?? '',
      seats: json['seats'] as int? ?? 0,
      airConditioning: json['airConditioning'] as bool? ?? false,
      pickupCity: json['pickupCity'] as String? ?? '',
      dropoffCity: json['dropoffCity'] as String? ?? '',
      rentalStart: DateTime.parse(json['rentalStart'] as String),
      pickupTime: json['pickupTime'] as String?,
      rentalEnd: DateTime.parse(json['rentalEnd'] as String),
      dropoffTime: json['dropoffTime'] as String?,
      withDriver: json['withDriver'] as bool? ?? false,
      driverAge25Plus: json['driverAge25Plus'] as bool? ?? true,
      bestOfferId: json['bestOfferId'] as String? ?? '',
      quotes: (json['quotes'] as List<dynamic>?)
          ?.map((e) => ProviderQuote.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
    brand, model, category, transmission, seats, airConditioning,
    pickupCity, dropoffCity, rentalStart, pickupTime, rentalEnd, dropoffTime,
    withDriver, driverAge25Plus, bestOfferId, quotes,
  ];
}
