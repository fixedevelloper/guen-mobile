import 'package:equatable/equatable.dart';
import '../../data/models/harmonized_flight_offer.dart';
import '../../data/models/multi_city_itinerary.dart';
import '../../data/models/payment_request.dart';

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

/// DÉCLENCHÉ pour valider les sièges (reçoit une liste)
class SeatsConfirmed extends FlightBookingEvent {
  final List<String> seats;
  const SeatsConfirmed(this.seats);

  @override
  List<Object?> get props => [seats];
}

/// DÉCLENCHÉ pour valider les infos passagers (reçoit une LISTE de voyageurs)
// --- Modèle fortement typé pour correspondre au TravelerRequest Java ---
class TravelerInfo extends Equatable {
  final String fullName;
  final DateTime dateOfBirth; // On utilise DateTime côté Dart
  final String? passportNumber;
  final String type; // Doit correspondre à l'Enum PassengerType (ex: 'ADULT')
  final String? seatNumber;

  const TravelerInfo({
    required this.fullName,
    required this.dateOfBirth,
    this.passportNumber,
    required this.type,
    this.seatNumber,
  });

  // Cette méthode simplifie le travail du BLoC et formate la date pour Spring Boot
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      // Formatage strict en YYYY-MM-DD attendu par LocalDate en Java
      'dateOfBirth': "${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}",
      'passportNumber': passportNumber,
      'type': type,
      'seatNumber': seatNumber,
    };
  }

  @override
  List<Object?> get props => [fullName, dateOfBirth, passportNumber, type, seatNumber];
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

class LoadSeatMap extends FlightBookingEvent {
  final String offerId;
  const LoadSeatMap(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

// Mise à jour ici : Correspondance avec l'UI et le BLoC
class ProcessPaymentEvent extends FlightBookingEvent {
  final Map<String, dynamic> paymentDetails;

  const ProcessPaymentEvent({required this.paymentDetails});

  @override
  List<Object?> get props => [paymentDetails];
}

class ResetBookingTunnel extends FlightBookingEvent {}
class PaymentSubmitted extends FlightBookingEvent {
  final PaymentRequest request;
  const PaymentSubmitted(this.request);
}