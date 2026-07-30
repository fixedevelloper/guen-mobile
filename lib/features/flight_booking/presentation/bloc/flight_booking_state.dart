import 'package:equatable/equatable.dart';
import '../../data/models/harmonized_flight_offer.dart';
import '../../data/models/multi_city_itinerary.dart';
import '../../data/models/seat_map_response.dart';

enum FlightBookingStatus {
  initial,
  loading,
  flightsLoaded,
  seatSelection,
  infoInput,
  paymentReady,
  success,
  failure
}

// Nouvel enum pour gérer spécifiquement l'état du paiement
enum PaymentStatus {
  initial,
  processing,
  success,
  failed
}

class FlightBookingState extends Equatable {
  final FlightBookingStatus status;
  final PaymentStatus paymentStatus;

  // Flux de recherche et résultats
  final List<HarmonizedFlightOffer> availableFlights;
  final HarmonizedFlightOffer? selectedFlight;
  final List<MultiCityItinerary> multiCityFlights;
  final MultiCityItinerary? selectedMultiCityItinerary;

  // Données de recherche initiales
  final String? departure;
  final String? destination;
  final DateTime? departureDate;
  final List<String> passengerTypes; // ex: ['ADULT', 'CHILD']

  // Gestion des sièges
  final SeatMapResponse? seatMap;
  final List<String> selectedSeats;

  // Données du tunnel d'achat et API
  final Map<String, dynamic>? passengerData;
  final String? bookingId;
  final String? errorMessage;

  // Getter pratique pour l'UI (utilisé dans le bouton de paiement)
  bool get isSubmitting => paymentStatus == PaymentStatus.processing;

  const FlightBookingState({
    this.status = FlightBookingStatus.initial,
    this.paymentStatus = PaymentStatus.initial,
    this.availableFlights = const [],
    this.selectedFlight,
    this.multiCityFlights = const [],
    this.selectedMultiCityItinerary,
    this.seatMap,
    this.selectedSeats = const [],
    this.passengerData,
    this.bookingId,
    this.errorMessage,
    this.departure,
    this.destination,
    this.departureDate,
    this.passengerTypes = const ['ADULT'],
  });

  FlightBookingState copyWith({
    FlightBookingStatus? status,
    PaymentStatus? paymentStatus,
    List<HarmonizedFlightOffer>? availableFlights,
    HarmonizedFlightOffer? selectedFlight,
    List<MultiCityItinerary>? multiCityFlights,
    MultiCityItinerary? selectedMultiCityItinerary,
    SeatMapResponse? seatMap,
    List<String>? selectedSeats,
    Map<String, dynamic>? passengerData,
    String? bookingId,
    String? errorMessage,
    String? departure,
    String? destination,
    DateTime? departureDate,
    List<String>? passengerTypes,
  }) {
    return FlightBookingState(
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      availableFlights: availableFlights ?? this.availableFlights,
      selectedFlight: selectedFlight ?? this.selectedFlight,
      multiCityFlights: multiCityFlights ?? this.multiCityFlights,
      selectedMultiCityItinerary: selectedMultiCityItinerary ?? this.selectedMultiCityItinerary,
      seatMap: seatMap ?? this.seatMap,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      passengerData: passengerData ?? this.passengerData,
      bookingId: bookingId ?? this.bookingId,
      errorMessage: errorMessage ?? this.errorMessage,
      departure: departure ?? this.departure,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      passengerTypes: passengerTypes ?? this.passengerTypes,
    );
  }

  @override
  List<Object?> get props => [
    status,
    paymentStatus,
    availableFlights,
    selectedFlight,
    multiCityFlights,
    selectedMultiCityItinerary,
    seatMap,
    selectedSeats,
    passengerData,
    bookingId,
    errorMessage,
    departure,
    destination,
    departureDate,
    passengerTypes,
  ];
}