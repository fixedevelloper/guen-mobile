import 'package:equatable/equatable.dart';
import '../../data/models/ancillary_option.dart';
import '../../data/models/harmonized_flight_offer.dart';
import '../../data/models/multi_city_itinerary.dart';
import '../../../../core/models/booking_response.dart';
import '../../../../core/models/payment_result.dart';

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
  failed,
  /// Mobile Money : en attente de confirmation USSD côté client (webhook
  /// gateway asynchrone). L'écran doit poller PaymentStatusRefreshRequested.
  pending,
  /// Carte : la gateway exige une étape synchrone (PIN/AVS/OTP/redirection)
  /// avant de pouvoir finaliser. Voir paymentResult.authorizationType.
  pendingAuthorization,
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

  // Options additionnelles (sièges tarifés/bagages/repas/assurance)
  final List<AncillaryOption>? ancillaryOptions;
  final List<String> selectedAncillaryIds;

  // Données du tunnel d'achat et API
  final BookingResponse? confirmedBooking; // réponse du checkout (POST /bookings/checkout[/multi-city])
  final PaymentResult? paymentResult; // réponse du paiement (POST /payments)
  final String? errorMessage;

  String? get bookingId => confirmedBooking?.id;

  // Getter pratique pour l'UI (utilisé dans le bouton de paiement)
  bool get isSubmitting => paymentStatus == PaymentStatus.processing;

  /// Ids AncillaryOption sélectionnés qui reviennent au voyageur `index` (base 0) :
  /// ceux dont le paxRef vaut "T${index+1}", plus - pour le voyageur 0
  /// uniquement - ceux sans paxRef (extras au niveau réservation, ex:
  /// assurance). Même répartition que applySelectedExtras côté Next.js
  /// (checkout/page.tsx).
  List<String> ancillaryIdsForTraveler(int index) {
    final options = ancillaryOptions;
    if (options == null || selectedAncillaryIds.isEmpty) return const [];
    final byId = {for (final o in options) o.id: o};
    final expectedPaxRef = 'T${index + 1}';
    return selectedAncillaryIds.where((id) {
      final option = byId[id];
      if (option == null) return false;
      return option.paxRef == expectedPaxRef || (option.paxRef == null && index == 0);
    }).toList();
  }

  /// Code de siège ("1A") choisi par chaque voyageur, dans l'ordre de
  /// `passengerTypes` - pour l'affichage uniquement, dérivé de l'extra SEAT
  /// sélectionné avec le paxRef correspondant.
  List<String> get selectedSeatCodesByTraveler {
    final options = ancillaryOptions;
    if (options == null || selectedAncillaryIds.isEmpty) return const [];
    final byId = {for (final o in options) o.id: o};
    final codes = <String>[];
    for (var i = 0; i < passengerTypes.length; i++) {
      final expectedPaxRef = 'T${i + 1}';
      for (final id in selectedAncillaryIds) {
        final option = byId[id];
        if (option != null && option.type == AncillaryType.SEAT && option.paxRef == expectedPaxRef) {
          codes.add(option.code ?? option.label);
          break;
        }
      }
    }
    return codes;
  }

  const FlightBookingState({
    this.status = FlightBookingStatus.initial,
    this.paymentStatus = PaymentStatus.initial,
    this.availableFlights = const [],
    this.selectedFlight,
    this.multiCityFlights = const [],
    this.selectedMultiCityItinerary,
    this.ancillaryOptions,
    this.selectedAncillaryIds = const [],
    this.confirmedBooking,
    this.paymentResult,
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
    List<AncillaryOption>? ancillaryOptions,
    List<String>? selectedAncillaryIds,
    BookingResponse? confirmedBooking,
    PaymentResult? paymentResult,
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
      ancillaryOptions: ancillaryOptions ?? this.ancillaryOptions,
      selectedAncillaryIds: selectedAncillaryIds ?? this.selectedAncillaryIds,
      confirmedBooking: confirmedBooking ?? this.confirmedBooking,
      paymentResult: paymentResult ?? this.paymentResult,
      errorMessage: errorMessage,
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
    ancillaryOptions,
    selectedAncillaryIds,
    confirmedBooking,
    paymentResult,
    errorMessage,
    departure,
    destination,
    departureDate,
    passengerTypes,
  ];
}
