import '../../domain/entities/flight.dart';

class FlightModel extends Flight {
  const FlightModel({
    required super.id,
    required super.flightNumber,
    required super.airline,
    required super.departureAirport,
    required super.arrivalAirport,
    required super.departureTime,
    required super.arrivalTime,
    required super.price,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      id: json['id']?.toString() ?? '',
      flightNumber: json['flightNumber'] ?? '',
      airline: json['airline'] ?? '',
      departureAirport: json['departureAirport'] ?? '',
      arrivalAirport: json['arrivalAirport'] ?? '',
      departureTime: DateTime.parse(json['departureTime']),
      arrivalTime: DateTime.parse(json['arrivalTime']),
      price: (json['price'] as num).toDouble(),
    );
  }
}
