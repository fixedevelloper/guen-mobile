/// Reflète com.guentours.search.web.PropertySearchRequest (GET /api/search/properties).
/// `checkIn`/`checkOut` au format ISO 'YYYY-MM-DD'.
class PropertySearchRequestDto {
  final String city;
  final String checkIn;
  final String checkOut;
  final int? guests;
  final int? bedrooms;
  final String? propertyType;
  final bool? entirePlace;
  final String currency;

  const PropertySearchRequestDto({
    required this.city,
    required this.checkIn,
    required this.checkOut,
    this.guests,
    this.bedrooms,
    this.propertyType,
    this.entirePlace,
    this.currency = 'XAF',
  });

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'checkIn': checkIn,
      'checkOut': checkOut,
      if (guests != null) 'guests': guests,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (propertyType != null) 'propertyType': propertyType,
      if (entirePlace != null) 'entirePlace': entirePlace,
      'currency': currency,
    };
  }
}
