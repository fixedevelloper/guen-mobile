import '../../data/models/featured_destination.dart';

enum DestinationsStatus { initial, loading, loaded, error }

class DestinationsState {
  final DestinationsStatus status;
  final List<FeaturedDestination> destinations;
  final String? errorMessage;

  const DestinationsState({
    this.status = DestinationsStatus.initial,
    this.destinations = const [],
    this.errorMessage,
  });

  DestinationsState copyWith({
    DestinationsStatus? status,
    List<FeaturedDestination>? destinations,
    String? errorMessage,
  }) {
    return DestinationsState(
      status: status ?? this.status,
      destinations: destinations ?? this.destinations,
      errorMessage: errorMessage,
    );
  }
}
