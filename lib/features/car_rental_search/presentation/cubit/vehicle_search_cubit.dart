import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/vehicle_api_client.dart';
import '../../data/models/vehicle_search_request_dto.dart';
import 'vehicle_search_state.dart';

class VehicleSearchCubit extends Cubit<VehicleSearchState> {
  final VehicleApiClient _apiClient;

  VehicleSearchCubit(this._apiClient) : super(const VehicleSearchState());

  Future<void> search(VehicleSearchRequestDto request) async {
    emit(state.copyWith(status: VehicleSearchStatus.loading));
    try {
      final offers = await _apiClient.searchVehicles(request);
      emit(state.copyWith(status: VehicleSearchStatus.loaded, offers: offers));
    } on ApiException catch (e) {
      emit(state.copyWith(status: VehicleSearchStatus.error, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(status: VehicleSearchStatus.error, errorMessage: 'Recherche de véhicules indisponible.'));
    }
  }
}
