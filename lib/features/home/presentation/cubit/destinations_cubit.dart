import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/destination_api_client.dart';
import 'destinations_state.dart';

class DestinationsCubit extends Cubit<DestinationsState> {
  final DestinationApiClient _apiClient;

  DestinationsCubit(this._apiClient) : super(const DestinationsState());

  Future<void> load() async {
    emit(state.copyWith(status: DestinationsStatus.loading, errorMessage: null));
    try {
      final destinations = await _apiClient.featured();
      emit(state.copyWith(status: DestinationsStatus.loaded, destinations: destinations));
    } on ApiException catch (e) {
      emit(state.copyWith(status: DestinationsStatus.error, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: DestinationsStatus.error,
        errorMessage: 'Impossible de charger les destinations.',
      ));
    }
  }
}
