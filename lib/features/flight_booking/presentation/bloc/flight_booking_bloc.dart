import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/payment_result.dart';
import '../../data/datasources/flight_api_client.dart';
import '../../data/models/flight_search_request_dto.dart';
import 'flight_booking_event.dart';
import 'flight_booking_state.dart';

class FlightBookingBloc extends Bloc<FlightBookingEvent, FlightBookingState> {
  final FlightApiClient _apiClient;

  FlightBookingBloc(this._apiClient) : super(const FlightBookingState()) {
    on<SearchFlightsRequested>(_onSearchFlightsRequested);
    on<FlightSelected>(_onFlightSelected);
    on<LoadAncillaryOptions>(_onLoadAncillaryOptions);
    on<AncillaryOptionsConfirmed>(_onAncillaryOptionsConfirmed);
    on<PassengerInfoSubmitted>(_onPassengerInfoSubmitted);
    on<PaymentSubmitted>(_onProcessPayment);
    on<PaymentStatusRefreshRequested>(_onPaymentStatusRefreshRequested);
    on<CardAuthorizationSubmitted>(_onCardAuthorizationSubmitted);
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
    } on ApiException catch (e) {
      emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: "Erreur lors de la recherche des vols."));
    }
  }

  void _onFlightSelected(FlightSelected event, Emitter<FlightBookingState> emit) {
    emit(state.copyWith(
      status: FlightBookingStatus.seatSelection,
      selectedFlight: event.flight,
      selectedAncillaryIds: const [],
    ));
  }

  Future<void> _onLoadAncillaryOptions(LoadAncillaryOptions event, Emitter<FlightBookingState> emit) async {
    emit(state.copyWith(status: FlightBookingStatus.loading));
    try {
      // Voyageurs placeholder pour le pricing (vrais noms pas encore connus à ce
      // stade) - le VRAI détail par type (ADULT/CHILD/INFANT) est déjà connu ici
      // (fixé à la recherche), contrairement au frontend Next.js qui ne l'a pas
      // encore à cette étape et se rabat sur ADULT pour tout le monde : on envoie
      // le vrai détail, pour un tarif plus juste sur les extras (bagages/repas).
      final travelers = state.passengerTypes
          .asMap()
          .entries
          .map((e) => {'fullName': 'Voyageur ${e.key + 1}', 'type': e.value})
          .toList();
      final options = await _apiClient.getAncillaryOptions(event.offerId, event.offerType, travelers);
      emit(state.copyWith(status: FlightBookingStatus.seatSelection, ancillaryOptions: options));
    } on ApiException catch (e) {
      emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: "Options additionnelles indisponibles."));
    }
  }

  void _onAncillaryOptionsConfirmed(AncillaryOptionsConfirmed event, Emitter<FlightBookingState> emit) {
    emit(state.copyWith(status: FlightBookingStatus.infoInput, selectedAncillaryIds: event.selectedIds));
  }

  Future<void> _onPassengerInfoSubmitted(PassengerInfoSubmitted event, Emitter<FlightBookingState> emit) async {
    emit(state.copyWith(status: FlightBookingStatus.loading));

    final travelers = event.travelers.map((t) => t.toJson()).toList();

    try {
      if (state.selectedMultiCityItinerary != null) {
        final itinerary = state.selectedMultiCityItinerary!;
        final payload = {
          'legOfferIds': itinerary.legs.map((leg) => leg.offerId).toList(),
          'contactEmail': event.contactEmail,
          'contactFullName': event.contactFullName,
          'contactPhone': event.contactPhone,
          'travelers': travelers,
        };
        final booking = await _apiClient.submitMultiCityCheckout(payload);
        emit(state.copyWith(status: FlightBookingStatus.paymentReady, confirmedBooking: booking));
        return;
      }

      final offer = state.selectedFlight;
      final offerId = offer?.bestQuote?.offerId ?? offer?.bestOfferId;
      if (offerId == null || offerId.isEmpty) {
        emit(state.copyWith(status: FlightBookingStatus.failure, errorMessage: "Aucun vol sélectionné."));
        return;
      }

      final payload = {
        'offerId': offerId,
        'offerType': 'FLIGHT',
        'contactEmail': event.contactEmail,
        'contactFullName': event.contactFullName,
        'contactPhone': event.contactPhone,
        'travelers': travelers,
      };

      final booking = await _apiClient.submitCheckout(payload);
      emit(state.copyWith(status: FlightBookingStatus.paymentReady, confirmedBooking: booking));
    } catch (e) {
      emit(state.copyWith(
        status: FlightBookingStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onProcessPayment(PaymentSubmitted event, Emitter<FlightBookingState> emit) async {
    emit(state.copyWith(paymentStatus: PaymentStatus.processing, errorMessage: null));
    try {
      final result = await _apiClient.submitPayment(event.request);
      _applyPaymentResult(result, emit);
    } on Exception catch (e) {
      emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Polling déclenché par l'écran d'attente Mobile Money (statut PENDING).
  Future<void> _onPaymentStatusRefreshRequested(
      PaymentStatusRefreshRequested event, Emitter<FlightBookingState> emit) async {
    final paymentId = state.paymentResult?.paymentId;
    final email = state.confirmedBooking?.contactEmail;
    if (paymentId == null || paymentId.isEmpty || email == null || email.isEmpty) return;

    try {
      final result = await _apiClient.getPaymentStatus(paymentId, email);
      _applyPaymentResult(result, emit);
    } on Exception {
      // Échec silencieux : un tick de polling raté n'est pas une erreur à
      // afficher, le prochain tick réessaiera.
    }
  }

  Future<void> _onCardAuthorizationSubmitted(
      CardAuthorizationSubmitted event, Emitter<FlightBookingState> emit) async {
    final paymentId = state.paymentResult?.paymentId;
    if (paymentId == null || paymentId.isEmpty) return;

    emit(state.copyWith(paymentStatus: PaymentStatus.processing, errorMessage: null));
    try {
      final result = await _apiClient.submitCardAuthorization(paymentId, event.code);
      _applyPaymentResult(result, emit);
    } on Exception catch (e) {
      emit(state.copyWith(
        paymentStatus: PaymentStatus.pendingAuthorization,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  /// Traduit un PaymentResult (initial, polling ou après authentification
  /// carte) en transition d'état — même branchement quel que soit l'appel
  /// qui l'a produit.
  void _applyPaymentResult(PaymentResult result, Emitter<FlightBookingState> emit) {
    if (result.isSucceeded) {
      emit(state.copyWith(
        paymentStatus: PaymentStatus.success,
        status: FlightBookingStatus.success,
        paymentResult: result,
      ));
    } else if (result.isPendingAuthorization) {
      emit(state.copyWith(paymentStatus: PaymentStatus.pendingAuthorization, paymentResult: result));
    } else if (result.isPending) {
      emit(state.copyWith(paymentStatus: PaymentStatus.pending, paymentResult: result));
    } else {
      emit(state.copyWith(
        paymentStatus: PaymentStatus.failed,
        paymentResult: result,
        errorMessage: "Paiement refusé : ${result.failureReason ?? 'Solde insuffisant ou carte invalide.'}",
      ));
    }
  }
  void _onResetBookingTunnel(ResetBookingTunnel event, Emitter<FlightBookingState> emit) {
    emit(const FlightBookingState());
  }
}