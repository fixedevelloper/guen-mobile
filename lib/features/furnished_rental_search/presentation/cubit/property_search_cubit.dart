import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/property_api_client.dart';
import '../../data/models/property_search_request_dto.dart';
import 'property_search_state.dart';

class PropertySearchCubit extends Cubit<PropertySearchState> {
  final PropertyApiClient _apiClient;

  PropertySearchCubit(this._apiClient) : super(const PropertySearchState());

  Future<void> search(PropertySearchRequestDto request) async {
    emit(state.copyWith(status: PropertySearchStatus.loading));
    try {
      final offers = await _apiClient.searchProperties(request);
      emit(state.copyWith(status: PropertySearchStatus.loaded, offers: offers));
    } on ApiException catch (e) {
      emit(state.copyWith(status: PropertySearchStatus.error, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(status: PropertySearchStatus.error, errorMessage: 'Recherche de logements indisponible.'));
    }
  }
}
