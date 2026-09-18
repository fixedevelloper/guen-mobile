import 'package:equatable/equatable.dart';
import '../../data/models/harmonized_vehicle_offer.dart';

enum VehicleSearchStatus { initial, loading, loaded, error }

class VehicleSearchState extends Equatable {
  final VehicleSearchStatus status;
  final List<HarmonizedVehicleOffer> offers;
  final String? errorMessage;

  const VehicleSearchState({
    this.status = VehicleSearchStatus.initial,
    this.offers = const [],
    this.errorMessage,
  });

  VehicleSearchState copyWith({
    VehicleSearchStatus? status,
    List<HarmonizedVehicleOffer>? offers,
    String? errorMessage,
  }) {
    return VehicleSearchState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, offers, errorMessage];
}
