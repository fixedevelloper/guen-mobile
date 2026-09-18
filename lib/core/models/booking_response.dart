import 'provider_quote.dart';

/// Reflète com.guentours.booking.web.BookingResponse. Un seul modèle pour
/// toutes les verticales : seuls les champs pertinents à `offerType` sont
/// non-null (ex: `hotelName`/`checkIn`/`checkOut` pour HOTEL,
/// `vehicleBrand`/`pickupCity` pour CAR_RENTAL, `propertyTitle` pour
/// FURNISHED_RENTAL).
class BookingResponse {
  final String id;
  final String status; // BookingStatus
  final String offerType; // OfferType
  final String? providerType;
  final String contactEmail;
  final Money? price;
  final String? paymentPlan;
  final Money? reservationFee;
  final Money? amountDue;
  final DateTime? ticketingDeadline;
  final String? providerConfirmationNumber;
  final String? failureReason;
  final List<BookingTraveler> travelers;

  // Vols
  final String? airline;
  final String? flightNumber;
  final String? origin;
  final String? destination;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? fareClass;
  final List<String> eTicketNumbers;
  final List<BookingFlightLeg> itineraryLegs; // vols MULTI_CITY

  // Hôtels
  final String? hotelName;
  final String? cityCode;
  final DateTime? checkIn;
  final DateTime? checkOut;

  // Véhicules
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleCategory;
  final String? vehicleTransmission;
  final int? vehicleSeats;
  final String? pickupCity;
  final String? dropoffCity;
  final DateTime? rentalStart;
  final String? pickupTime;
  final DateTime? rentalEnd;
  final String? dropoffTime;
  final bool? withDriver;

  // Meublés
  final String? propertyTitle;
  final String? propertyType;
  final String? country;
  final int? bedrooms;
  final int? maxGuests;
  final bool? entirePlace;

  final DateTime? createdAt;

  const BookingResponse({
    required this.id,
    required this.status,
    required this.offerType,
    this.providerType,
    required this.contactEmail,
    this.price,
    this.paymentPlan,
    this.reservationFee,
    this.amountDue,
    this.ticketingDeadline,
    this.providerConfirmationNumber,
    this.failureReason,
    this.travelers = const [],
    this.airline,
    this.flightNumber,
    this.origin,
    this.destination,
    this.departureTime,
    this.arrivalTime,
    this.fareClass,
    this.eTicketNumbers = const [],
    this.itineraryLegs = const [],
    this.hotelName,
    this.cityCode,
    this.checkIn,
    this.checkOut,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleCategory,
    this.vehicleTransmission,
    this.vehicleSeats,
    this.pickupCity,
    this.dropoffCity,
    this.rentalStart,
    this.pickupTime,
    this.rentalEnd,
    this.dropoffTime,
    this.withDriver,
    this.propertyTitle,
    this.propertyType,
    this.country,
    this.bedrooms,
    this.maxGuests,
    this.entirePlace,
    this.createdAt,
  });

  static DateTime? _parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
  static Money? _parseMoney(dynamic v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>);

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING_PAYMENT',
      offerType: json['offerType'] as String? ?? '',
      providerType: json['providerType'] as String?,
      contactEmail: json['contactEmail'] as String? ?? '',
      price: _parseMoney(json['price']),
      paymentPlan: json['paymentPlan'] as String?,
      reservationFee: _parseMoney(json['reservationFee']),
      amountDue: _parseMoney(json['amountDue']),
      ticketingDeadline: _parseDate(json['ticketingDeadline']),
      providerConfirmationNumber: json['providerConfirmationNumber'] as String?,
      failureReason: json['failureReason'] as String?,
      travelers: (json['travelers'] as List<dynamic>?)
          ?.map((e) => BookingTraveler.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      airline: json['airline'] as String?,
      flightNumber: json['flightNumber'] as String?,
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      departureTime: _parseDate(json['departureTime']),
      arrivalTime: _parseDate(json['arrivalTime']),
      fareClass: json['fareClass'] as String?,
      eTicketNumbers: (json['eTicketNumbers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      itineraryLegs: (json['itineraryLegs'] as List<dynamic>?)
          ?.map((e) => BookingFlightLeg.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      hotelName: json['hotelName'] as String?,
      cityCode: json['cityCode'] as String?,
      checkIn: _parseDate(json['checkIn']),
      checkOut: _parseDate(json['checkOut']),
      vehicleBrand: json['vehicleBrand'] as String?,
      vehicleModel: json['vehicleModel'] as String?,
      vehicleCategory: json['vehicleCategory'] as String?,
      vehicleTransmission: json['vehicleTransmission'] as String?,
      vehicleSeats: json['vehicleSeats'] as int?,
      pickupCity: json['pickupCity'] as String?,
      dropoffCity: json['dropoffCity'] as String?,
      rentalStart: _parseDate(json['rentalStart']),
      pickupTime: json['pickupTime'] as String?,
      rentalEnd: _parseDate(json['rentalEnd']),
      dropoffTime: json['dropoffTime'] as String?,
      withDriver: json['withDriver'] as bool?,
      propertyTitle: json['propertyTitle'] as String?,
      propertyType: json['propertyType'] as String?,
      country: json['country'] as String?,
      bedrooms: json['bedrooms'] as int?,
      maxGuests: json['maxGuests'] as int?,
      entirePlace: json['entirePlace'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

/// Reflète com.guentours.booking.web.BookingFlightLegResponse (un segment
/// d'un itinéraire MULTI_CITY).
class BookingFlightLeg {
  final int legIndex;
  final String airline;
  final String flightNumber;
  final String origin;
  final String destination;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  const BookingFlightLeg({
    required this.legIndex,
    required this.airline,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    this.departureTime,
    this.arrivalTime,
  });

  factory BookingFlightLeg.fromJson(Map<String, dynamic> json) {
    return BookingFlightLeg(
      legIndex: json['legIndex'] as int? ?? 0,
      airline: json['airline'] as String? ?? '',
      flightNumber: json['flightNumber'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      departureTime: json['departureTime'] != null ? DateTime.tryParse(json['departureTime'] as String) : null,
      arrivalTime: json['arrivalTime'] != null ? DateTime.tryParse(json['arrivalTime'] as String) : null,
    );
  }
}

/// Reflète com.guentours.booking.BookingTravelerResponse.
class BookingTraveler {
  final String fullName;
  final String type;
  final String? seatNumber;

  const BookingTraveler({required this.fullName, required this.type, this.seatNumber});

  factory BookingTraveler.fromJson(Map<String, dynamic> json) {
    return BookingTraveler(
      fullName: json['fullName'] as String? ?? '',
      type: json['type'] as String? ?? 'ADULT',
      seatNumber: json['seatNumber'] as String?,
    );
  }
}
