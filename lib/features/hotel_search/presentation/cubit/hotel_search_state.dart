import 'package:equatable/equatable.dart';
import '../../data/models/harmonized_hotel_offer.dart';

enum HotelSearchStatus { initial, loading, loaded, error }

class HotelSearchState extends Equatable {
  final HotelSearchStatus status;
  final List<HarmonizedHotelOffer> offers;
  final String? errorMessage;

  /// Jeton de pagination de la recherche en cours (voir
  /// HotelSearchResult.searchId côté Spring) ; `null` si aucun fournisseur
  /// actif n'en a capturé un pour cette recherche.
  final String? searchId;
  final int pageNumber;
  final bool hasMore;
  final bool isLoadingMore;

  const HotelSearchState({
    this.status = HotelSearchStatus.initial,
    this.offers = const [],
    this.errorMessage,
    this.searchId,
    this.pageNumber = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  HotelSearchState copyWith({
    HotelSearchStatus? status,
    List<HarmonizedHotelOffer>? offers,
    String? errorMessage,
    String? searchId,
    int? pageNumber,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return HotelSearchState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      errorMessage: errorMessage,
      searchId: searchId ?? this.searchId,
      pageNumber: pageNumber ?? this.pageNumber,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props =>
      [status, offers, errorMessage, searchId, pageNumber, hasMore, isLoadingMore];
}
