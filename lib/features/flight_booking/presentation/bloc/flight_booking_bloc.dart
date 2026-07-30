import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/flight_api_client.dart';
import '../../data/models/flight_search_request_dto.dart';
import '../../data/models/harmonized_flight_offer.dart';
import '../../data/models/multi_city_itinerary.dart';
import 'flight_booking_event.dart';
import 'flight_booking_state.dart';

class FlightBookingBloc extends Bloc<FlightBookingEvent, FlightBookingState> {
  final FlightApiClient _apiClient;

  FlightBookingBloc(this._apiClient) : super(const FlightBookingState()) {
    on<SearchFlightsRequested>(_onSearchFlightsRequested);
    on<FlightSelected>(_onFlightSelected);
    on<LoadSeatMap>(_onLoadSeatMap);
    on<SeatsConfirmed>(_onSeatsConfirmed);
    on<PassengerInfoSubmitted>(_onPassengerInfoSubmitted);
    //on<ProcessPaymentEvent>(_onProcessPayment);
    on<PaymentSubmitted>(_onProcessPayment);
    on<ResetBookingTunnel>(_onResetBookingTunnel);
  }

  // --- Helpers ---
  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // --- Handlers ---

  Future<void> _onSearchFlightsRequested(SearchFlightsRequested event, Emitter<FlightBookingState> emit) async {
    emit(state.copyWith(
      status: FlightBookingStatus.loading,
      departure: event.departure ?? event.segments?.first.departure,
      destination: event.destination ?? event.segments?.last.destination,
      departureDate: event.departureDate ?? event.segments?.first.departureDate,
      passengerTypes: [
        ...List.generate(event.adults, (_) => 'ADULT'),
        ...List.generate(event.children, (_) => 'CHILD'),
        ...List.generate(event.infants, (_) => 'INFANT'),
      ],
    ));

    try {
      if (event.journeyType == 'MULTI_CITY' && event.segments != null) {
        final multiCityResults = await _apiClient.searchMultiCityFlights(
          MultiCityFlightSearchRequestDto(
            legs: event.segments!.map((s) => FlightLegDto(
              origin: s.departure.trim().toUpperCase(),
              destination: s.destination.trim().toUpperCase(),
              departureDate: _formatDate(s.departureDate),
            )).toList(),
            adults: event.adults,
            children: event.children,
            infants: event.infants,
            cabinClass: event.cabinClass,
            currency: event.currency,
          ),
        );
        emit(state.copyWith(status: FlightBookingStatus.flightsLoaded, multiCityFlights: multiCityResults));
      } else {
        final standardResults = await _apiClient.searchFlights(
          FlightSearchRequestDto(
            origin: event.departure!.trim().toUpperCase(),
            destination: event.destination!.trim().toUpperCase(),
            departureDate: _formatDate(event.departureDate!),
            returnDate: event.returnDate != null ? _formatDate(event.returnDate!) : null,
            journeyType: event.journeyType,
            adults: event.adults,
            children: event.children,
            infants: event.infants,
            cabinClass: event.cabinClass,
            currency: event.currency,
          ),
        );
        emit(state.copyWith(status: FlightBookingStatus.flightsLoaded, availableFlights: standardResults));
      }
    } catch (e) {
      emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: "Erreur lors de la recherche des vols."));
    }
  }

  void _onFlightSelected(FlightSelected event, Emitter<FlightBookingState> emit) {
    emit(state.copyWith(
      status: FlightBookingStatus.seatSelection,
      selectedFlight: event.flight,
      selectedSeats: const [],
    ));
  }

  Future<void> _onLoadSeatMap(LoadSeatMap event, Emitter<FlightBookingState> emit) async {
    emit(state.copyWith(status: FlightBookingStatus.loading));
    try {
      final seatMap = await _apiClient.getFlightSeatMap(event.offerId);
      emit(state.copyWith(status: FlightBookingStatus.seatSelection, seatMap: seatMap));
    } catch (e) {
      emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: "Plan de cabine indisponible."));
    }
  }

  void _onSeatsConfirmed(SeatsConfirmed event, Emitter<FlightBookingState> emit) {
    emit(state.copyWith(status: FlightBookingStatus.infoInput, selectedSeats: event.seats));
  }

  Future<void> _onPassengerInfoSubmitted(PassengerInfoSubmitted event, Emitter<FlightBookingState> emit) async {
    emit(state.copyWith(status: FlightBookingStatus.loading));
    try {
      final payload = {
        'offerId': state.selectedFlight?.quotes.first.offerId,
        'offerType': 'FLIGHT', // À ajuster selon votre Enum Java
        'contactEmail': event.contactEmail,
        'contactFullName': event.contactFullName,
        'contactPhone': event.contactPhone,

        // La magie opère ici : on convertit proprement nos objets Dart en JSON
        'travelers': event.travelers.map((t) => t.toJson()).toList(),
      };

      final response = await _apiClient.submitCheckout(payload);

      emit(state.copyWith(
        status: FlightBookingStatus.paymentReady,
        bookingId: response['id'] as String,
        passengerData: payload,
      ));
    } catch (e) {
      emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onProcessPayment(PaymentSubmitted event, Emitter<FlightBookingState> emit) async {
    // 1. Passage en état de traitement (UI affiche le loader)
    emit(state.copyWith(
        paymentStatus: PaymentStatus.processing,
        errorMessage: null
    ));

    try {
      // 2. Appel à l'API via notre client
      // Note : submitPayment retourne les données du PaymentResponse
      final responseData = await _apiClient.submitPayment(event.request);

      // 3. Vérification du succès (basé sur le statut retourné par votre API)
      // Assurez-vous que votre API renvoie un champ 'status' ou similaire
      if (responseData['status'] == 'SUCCEEDED') {
        emit(state.copyWith(
          paymentStatus: PaymentStatus.success,
          status: FlightBookingStatus.success,
          bookingId: responseData['bookingId'], // Optionnel : mise à jour avec l'ID final
        ));
      } else {
        // 4. Cas où le paiement est rejeté par la banque/passerelle
        emit(state.copyWith(
          paymentStatus: PaymentStatus.failed,
          errorMessage: "Paiement refusé : ${responseData['message'] ?? 'Solde insuffisant ou carte invalide.'}",
        ));
      }
    } on Exception catch (e) {
      // 5. Cas d'erreur réseau ou serveur (402, 500, etc.)
      emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
  void _onResetBookingTunnel(ResetBookingTunnel event, Emitter<FlightBookingState> emit) {
    emit(const FlightBookingState());
  }
}