/// Reflète les @RequestParam bruts de GET /api/search/vehicles (pas de DTO
/// validé côté backend pour cet endpoint — voir SearchController.searchVehicles).
/// `rentalStart`/`rentalEnd` au format 'YYYY-MM-DD', `pickupTime`/`dropoffTime`
/// au format 'HH:mm'.
class VehicleSearchRequestDto {
  final String pickupCity;
  final String? dropoffCity;
  final String rentalStart;
  final String? pickupTime;
  final String rentalEnd;
  final String? dropoffTime;
  final String? category;
  final bool withDriver;
  final bool driverAge25Plus;
  final String currency;

  const VehicleSearchRequestDto({
    required this.pickupCity,
    this.dropoffCity,
    required this.rentalStart,
    this.pickupTime,
    required this.rentalEnd,
    this.dropoffTime,
    this.category,
    this.withDriver = false,
    this.driverAge25Plus = true,
    this.currency = 'XAF',
  });

  Map<String, dynamic> toJson() {
    return {
      'pickupCity': pickupCity,
      if (dropoffCity != null && dropoffCity!.isNotEmpty) 'dropoffCity': dropoffCity,
      'rentalStart': rentalStart,
      if (pickupTime != null) 'pickupTime': pickupTime,
      'rentalEnd': rentalEnd,
      if (dropoffTime != null) 'dropoffTime': dropoffTime,
      if (category != null && category!.isNotEmpty) 'category': category,
      'withDriver': withDriver,
      'driverAge25Plus': driverAge25Plus,
      'currency': currency,
    };
  }
}
