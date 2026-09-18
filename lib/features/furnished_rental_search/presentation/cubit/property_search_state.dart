import 'package:equatable/equatable.dart';
import '../../data/models/harmonized_property_offer.dart';

enum PropertySearchStatus { initial, loading, loaded, error }

class PropertySearchState extends Equatable {
  final PropertySearchStatus status;
  final List<HarmonizedPropertyOffer> offers;
  final String? errorMessage;

  const PropertySearchState({
    this.status = PropertySearchStatus.initial,
    this.offers = const [],
    this.errorMessage,
  });

  PropertySearchState copyWith({
    PropertySearchStatus? status,
    List<HarmonizedPropertyOffer>? offers,
    String? errorMessage,
  }) {
    return PropertySearchState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, offers, errorMessage];
}
