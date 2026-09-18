import 'package:equatable/equatable.dart';
import '../../data/models/harmonized_flight_offer.dart';
import '../../data/models/multi_city_itinerary.dart';
import '../../../../core/models/payment_request.dart';

abstract class FlightBookingEvent extends Equatable {
  const FlightBookingEvent();

  @override
  List<Object?> get props => [];
}

/// DÉCLENCHÉ lors de la recherche initiale
class SearchFlightsRequested extends FlightBookingEvent {
  final String journeyType;
  final String? departure;
  final String? destination;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final List<FlightSearchSegment>? segments;
  final int adults;
  final int children;
  final int infants;
  final String cabinClass;
  final String currency;

  const SearchFlightsRequested({
    required this.journeyType,
    this.departure,
    this.destination,
    this.departureDate,
    this.returnDate,
    this.segments,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = 'ECONOMY',
    this.currency = 'XAF',
  });

  @override
  List<Object?> get props => [
    journeyType,
    departure,
    destination,
    departureDate,
    returnDate,
    segments,
    adults,
    children,
    infants,
    cabinClass,
    currency
  ];
}

/// DÉCLENCHÉ pour valider les extras choisis (sièges/bagages/repas/assurance) -
/// reçoit les ids AncillaryOption (AncillaryOptionResponse.id côté Java) sélectionnés.
class AncillaryOptionsConfirmed extends FlightBookingEvent {
  final List<String> selectedIds;
  const AncillaryOptionsConfirmed(this.selectedIds);

  @override
  List<Object?> get props => [selectedIds];
}

/// DÉCLENCHÉ pour valider les infos passagers (reçoit une LISTE de voyageurs)
// --- Modèle fortement typé pour correspondre au TravelerRequest Java ---
class TravelerInfo extends Equatable {
  final String fullName;
  final DateTime dateOfBirth; // On utilise DateTime côté Dart
  final String? passportNumber;
  final String type; // Doit correspondre à l'Enum PassengerType (ex: 'ADULT')
  final String? nationality; // ISO 3166-1 alpha-2, requis par certains providers (ex: Travelopro)
  final String? passportIssueCountry; // ISO 3166-1 alpha-2, optionnel
  final DateTime? passportExpiryDate; // optionnel

  /// Ids AncillaryOptionResponse (bagages/repas/siège/assurance) choisis par CE
  /// voyageur à l'étape "options additionnelles" - remplace l'ancien champ
  /// seatNumber positionnel : le prix et, le cas échéant, le jeton fournisseur
  /// sont résolus côté serveur depuis ce même cache d'ids.
  final List<String>? selectedAncillaryIds;

  const TravelerInfo({
    required this.fullName,
    required this.dateOfBirth,
    this.passportNumber,
    required this.type,
    this.nationality,
    this.passportIssueCountry,
    this.passportExpiryDate,
    this.selectedAncillaryIds,
  });

  static String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // Cette méthode simplifie le travail du BLoC et formate la date pour Spring Boot
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      // Formatage strict en YYYY-MM-DD attendu par LocalDate en Java
      'dateOfBirth': _formatDate(dateOfBirth),
      'passportNumber': passportNumber,
      'type': type,
      'nationality': nationality,
      'passportIssueCountry': passportIssueCountry,
      if (passportExpiryDate != null) 'passportExpiryDate': _formatDate(passportExpiryDate!),
      if (selectedAncillaryIds != null && selectedAncillaryIds!.isNotEmpty)
        'selectedAncillaryIds': selectedAncillaryIds,
    };
  }

  @override
  List<Object?> get props => [
    fullName, dateOfBirth, passportNumber, type,
    nationality, passportIssueCountry, passportExpiryDate, selectedAncillaryIds,
  ];
}

// --- L'événement mis à jour ---
class PassengerInfoSubmitted extends FlightBookingEvent {
  final String contactEmail;
  final String contactFullName;
  final String contactPhone;

  // Utilisation de la classe typée au lieu du Map générique
  final List<TravelerInfo> travelers;

  const PassengerInfoSubmitted({
    required this.contactEmail,
    required this.contactFullName,
    required this.contactPhone,
    required this.travelers,
  });

  @override
  List<Object?> get props => [contactEmail, contactFullName, contactPhone, travelers];
}

// --- Événements conservés (inchangés) ---

class FlightSearchSegment extends Equatable {
  final String departure;
  final String destination;
  final DateTime departureDate;

  const FlightSearchSegment({
    required this.departure,
    required this.destination,
    required this.departureDate,
  });

  @override
  List<Object?> get props => [departure, destination, departureDate];
}

class FlightSelected extends FlightBookingEvent {
  final HarmonizedFlightOffer? flight;
  final MultiCityItinerary? multiCityItinerary;

  const FlightSelected({this.flight, this.multiCityItinerary});

  @override
  List<Object?> get props => [flight, multiCityItinerary];
}

/// Charge les extras tarifés (sièges/bagages/repas/assurance) disponibles pour
/// l'offre sélectionnée - remplace l'ancien LoadSeatMap (plan de cabine simulé,
/// non tarifé ; voir POST /api/bookings/ancillary-options côté Java).
class LoadAncillaryOptions extends FlightBookingEvent {
  final String offerId;
  final String offerType;
  const LoadAncillaryOptions(this.offerId, this.offerType);

  @override
  List<Object?> get props => [offerId, offerType];
}

class ResetBookingTunnel extends FlightBookingEvent {}
class PaymentSubmitted extends FlightBookingEvent {
  final PaymentRequest request;
  const PaymentSubmitted(this.request);

  @override
  List<Object?> get props => [request];
}

/// Relit l'état d'un paiement Mobile Money en attente (polling déclenché par
/// l'écran d'attente USSD).
class PaymentStatusRefreshRequested extends FlightBookingEvent {
  const PaymentStatusRefreshRequested();
}

/// Soumet le code (PIN/AVS/OTP) demandé pour débloquer un paiement carte
/// resté en PENDING_AUTHORIZATION.
class CardAuthorizationSubmitted extends FlightBookingEvent {
  final String code;
  const CardAuthorizationSubmitted(this.code);

  @override
  List<Object?> get props => [code];
}