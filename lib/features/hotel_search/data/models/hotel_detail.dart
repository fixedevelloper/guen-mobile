/// Reflète com.guentours.provider.HotelDetail — champs GET /api/search/hotels/details.
/// Chaque champ est potentiellement absent/null selon le fournisseur amont
/// (`@JsonIgnoreProperties(ignoreUnknown = true)` côté backend).
class HotelDetail {
  final String? hotelId;
  final String? name;
  final String? address;
  final String? city;
  final String? country;
  final String? email;
  final String? phone;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final double? hotelRating;
  final String? description;
  final List<String> facilities;
  final List<HotelImage> hotelImages;
  final HotelReviewSummary? hotelReview;

  const HotelDetail({
    this.hotelId,
    this.name,
    this.address,
    this.city,
    this.country,
    this.email,
    this.phone,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.hotelRating,
    this.description,
    this.facilities = const [],
    this.hotelImages = const [],
    this.hotelReview,
  });

  factory HotelDetail.fromJson(Map<String, dynamic> json) {
    return HotelDetail(
      hotelId: json['hotelId'] as String?,
      name: json['name'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      postalCode: json['postalCode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hotelRating: (json['hotelRating'] as num?)?.toDouble(),
      description: (json['description'] as Map<String, dynamic>?)?['content'] as String?,
      facilities: (json['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      hotelImages: (json['hotelImages'] as List<dynamic>?)
          ?.map((e) => HotelImage.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      hotelReview: json['hotel_review'] != null
          ? HotelReviewSummary.fromJson(json['hotel_review'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HotelImage {
  final String? caption;
  final String? url;

  const HotelImage({this.caption, this.url});

  factory HotelImage.fromJson(Map<String, dynamic> json) {
    return HotelImage(caption: json['caption'] as String?, url: json['url'] as String?);
  }
}

class HotelReviewSummary {
  final double? rating;
  final int? numReviews;
  final String? ranking;
  final String? rankingString;
  final double? rateLocation;
  final double? rateSleep;
  final double? rateRoom;
  final double? rateService;
  final double? rateValue;
  final double? rateCleanliness;
  final List<HotelReview> reviews;

  const HotelReviewSummary({
    this.rating,
    this.numReviews,
    this.ranking,
    this.rankingString,
    this.rateLocation,
    this.rateSleep,
    this.rateRoom,
    this.rateService,
    this.rateValue,
    this.rateCleanliness,
    this.reviews = const [],
  });

  factory HotelReviewSummary.fromJson(Map<String, dynamic> json) {
    return HotelReviewSummary(
      rating: (json['rating'] as num?)?.toDouble(),
      numReviews: json['num_reviews'] as int?,
      ranking: json['ranking'] as String?,
      rankingString: json['ranking_string'] as String?,
      rateLocation: (json['rate_location'] as num?)?.toDouble(),
      rateSleep: (json['rate_sleep'] as num?)?.toDouble(),
      rateRoom: (json['rate_room'] as num?)?.toDouble(),
      rateService: (json['rate_service'] as num?)?.toDouble(),
      rateValue: (json['rate_value'] as num?)?.toDouble(),
      rateCleanliness: (json['rate_cleanliness'] as num?)?.toDouble(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => HotelReview.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
    );
  }

  /// Étiquette qualitative — mêmes seuils que la page détail hôtel du frontend Next.js.
  String get label {
    final r = rating;
    if (r == null) return '';
    if (r >= 8.5) return 'Excellent';
    if (r >= 7.5) return 'Très bien';
    return 'Bien';
  }

  /// Les 6 sous-notes nommées (sur 10), dans un ordre d'affichage stable —
  /// seules celles réellement renvoyées par le fournisseur sont incluses.
  List<(String label, double value)> get namedSubRatings => [
        if (rateLocation != null) ('Emplacement', rateLocation!),
        if (rateCleanliness != null) ('Propreté', rateCleanliness!),
        if (rateService != null) ('Service', rateService!),
        if (rateRoom != null) ('Chambre', rateRoom!),
        if (rateSleep != null) ('Sommeil', rateSleep!),
        if (rateValue != null) ('Rapport qualité-prix', rateValue!),
      ];
}

/// Reflète com.guentours.provider.HotelDetail.Review — un avis individuel.
class HotelReview {
  final String? publishedDate;
  final int? rating; // sur 5, distinct de la note globale (sur 10)
  final String? travelDate;
  final String? title;
  final String? text;
  final String? tripType;
  final String? username;
  final String? userLocationName;

  const HotelReview({
    this.publishedDate,
    this.rating,
    this.travelDate,
    this.title,
    this.text,
    this.tripType,
    this.username,
    this.userLocationName,
  });

  factory HotelReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final userLocation = user?['user_location'] as Map<String, dynamic>?;
    return HotelReview(
      publishedDate: json['published_date'] as String?,
      rating: json['rating'] as int?,
      travelDate: json['travel_date'] as String?,
      title: json['title'] as String?,
      text: json['text'] as String?,
      tripType: json['trip_type'] as String?,
      username: user?['username'] as String?,
      userLocationName: userLocation?['name'] as String?,
    );
  }
}
