/// Reflète com.guentours.booking.web.TravelerRequest côté backend. Partagé
/// par toutes les verticales : seuls `fullName` et `type` sont obligatoires
/// (`dateOfBirth`/`nationality` ne sont exigés que pour les vols — voir
/// TravelerInfo dans flight_booking, qui a son propre modèle car il gère
/// aussi `seatNumber`).
class CheckoutTravelerDto {
  final String fullName;
  final String type; // PassengerType: 'ADULT' | 'CHILD' | 'INFANT'

  const CheckoutTravelerDto({required this.fullName, this.type = 'ADULT'});

  Map<String, dynamic> toJson() => {'fullName': fullName, 'type': type};
}

/// Reflète com.guentours.booking.web.CheckoutRequest (POST /api/bookings/checkout).
/// `paymentPlan` par défaut à PAY_NOW si omis côté backend ; `quantity` n'est
/// pris en compte que pour `offerType == HOTEL` (nombre de chambres
/// identiques), ignoré sinon.
class CheckoutRequestDto {
  final String offerId;
  final String offerType; // OfferType: 'FLIGHT' | 'HOTEL' | 'CAR_RENTAL' | 'FURNISHED_RENTAL'
  final String contactEmail;
  final String contactFullName;
  final String? contactPhone;
  final List<CheckoutTravelerDto> travelers;
  final String paymentPlan; // PaymentPlan: 'PAY_NOW' | 'PAY_LATER'
  final int? quantity;

  const CheckoutRequestDto({
    required this.offerId,
    required this.offerType,
    required this.contactEmail,
    required this.contactFullName,
    this.contactPhone,
    required this.travelers,
    this.paymentPlan = 'PAY_NOW',
    this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'offerType': offerType,
      'contactEmail': contactEmail,
      'contactFullName': contactFullName,
      if (contactPhone != null && contactPhone!.isNotEmpty) 'contactPhone': contactPhone,
      'travelers': travelers.map((t) => t.toJson()).toList(),
      'paymentPlan': paymentPlan,
      if (quantity != null) 'quantity': quantity,
    };
  }
}
