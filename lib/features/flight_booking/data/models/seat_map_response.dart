import 'package:equatable/equatable.dart';

class SeatMapResponse extends Equatable {
  final int rows;
  final List<String> columns;
  final List<Seat> seats;

  const SeatMapResponse({
    required this.rows,
    required this.columns,
    required this.seats,
  });

  factory SeatMapResponse.fromJson(Map<String, dynamic> json) {
    return SeatMapResponse(
      rows: json['rows'] as int? ?? 0,
      columns: List<String>.from(json['columns'] ?? []),
      seats: (json['seats'] as List? ?? [])
          .map((s) => Seat.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [rows, columns, seats];
}

class Seat extends Equatable {
  final String seatNumber;
  final bool available;

  const Seat({
    required this.seatNumber,
    required this.available,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      seatNumber: json['seatNumber'] as String? ?? '',
      available: json['available'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [seatNumber, available];
}