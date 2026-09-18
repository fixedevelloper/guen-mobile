import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/hotel_api_client.dart';
import '../../data/models/hotel_search_request_dto.dart';
import 'hotel_search_state.dart';

class HotelSearchCubit extends Cubit<HotelSearchState> {
  final HotelApiClient _apiClient;

  HotelSearchCubit(this._apiClient) : super(const HotelSearchState());

  Future<void> search(HotelSearchRequestDto request) async {
    developer.log(
      'Hotel search started',
      name: 'HotelSearchCubit',
      error: request.toJson(),
    );

    emit(state.copyWith(status: HotelSearchStatus.loading));

    try {
      final result = await _apiClient.searchHotels(request);

      developer.log(
        'Hotel search succeeded',
        name: 'HotelSearchCubit',
        error: 'Offers count: ${result.offers.length}, searchId: ${result.searchId}',
      );

      // État neuf plutôt que copyWith : une nouvelle recherche doit toujours
      // repartir de zéro (searchId/pageNumber d'une recherche précédente ne
      // doivent jamais survivre — copyWith(searchId: null) serait ignoré par
      // son propre `??`).
      emit(HotelSearchState(
        status: HotelSearchStatus.loaded,
        offers: result.offers,
        searchId: result.searchId,
        pageNumber: 1,
        hasMore: result.searchId != null,
      ));
    } on ApiException catch (e, stackTrace) {
      developer.log('Hotel search failed', name: 'HotelSearchCubit', error: e, stackTrace: stackTrace);
      emit(state.copyWith(status: HotelSearchStatus.error, errorMessage: e.message));
    } catch (e, stackTrace) {
      developer.log(
        'Hotel search failed',
        name: 'HotelSearchCubit',
        error: e,
        stackTrace: stackTrace,
      );

      emit(state.copyWith(
        status: HotelSearchStatus.error,
        errorMessage: 'Recherche d’hôtels indisponible.',
      ));
    }
  }

  /// Charge la page suivante de la recherche en cours (voir
  /// HotelSearchResult.searchId côté Spring) ; no-op si la recherche
  /// n'expose pas de jeton de pagination, si tout a déjà été chargé, ou si un
  /// chargement est déjà en cours.
  Future<void> loadMore() async {
    final searchId = state.searchId;
    if (searchId == null || !state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.pageNumber + 1;

    try {
      final newOffers = await _apiClient.loadMoreHotels(searchId, nextPage);
      if (newOffers.isEmpty) {
        emit(state.copyWith(isLoadingMore: false, hasMore: false));
      } else {
        emit(state.copyWith(
          isLoadingMore: false,
          hasMore: true,
          pageNumber: nextPage,
          offers: [...state.offers, ...newOffers],
        ));
      }
    } catch (e, stackTrace) {
      developer.log('Hotel load-more failed', name: 'HotelSearchCubit', error: e, stackTrace: stackTrace);
      // Un échec de "charger plus" n'invalide pas les résultats déjà
      // affichés : on redevient prêt à réessayer plutôt que de bloquer hasMore.
      emit(state.copyWith(isLoadingMore: false));
    }
  }
}
