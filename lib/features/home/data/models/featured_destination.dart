/// Reflète com.guentours.destination.FeaturedDestinationResponse.
class FeaturedDestination {
  final String cityName;
  final String countryName;
  final String? destinationCode;
  final String? imageUrl;

  const FeaturedDestination({
    required this.cityName,
    required this.countryName,
    this.destinationCode,
    this.imageUrl,
  });

  factory FeaturedDestination.fromJson(Map<String, dynamic> json) {
    return FeaturedDestination(
      cityName: json['cityName'] as String? ?? '',
      countryName: json['countryName'] as String? ?? '',
      destinationCode: json['destinationCode'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
