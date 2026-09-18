/// Reflète com.guentours.search.web.HotelSearchRequest (GET /api/search/hotels).
/// `checkIn`/`checkOut` doivent être au format ISO 'YYYY-MM-DD' (LocalDate Java).
class HotelSearchRequestDto {
  final String cityCode;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int rooms;
  final String currency;

  const HotelSearchRequestDto({
    required this.cityCode,
    required this.checkIn,
    required this.checkOut,
    this.adults = 1,
    this.rooms = 1,
    this.currency = 'XAF',
  });

  Map<String, dynamic> toJson() {
    return {
      'cityCode': cityCode,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'adults': adults,
      'rooms': rooms,
      'currency': currency,
    };
  }
}
