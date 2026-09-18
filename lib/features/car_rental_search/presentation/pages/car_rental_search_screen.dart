import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/geo_api_client.dart';
import '../../../../core/widgets/city_autocomplete_field.dart';
import '../../../../core/widgets/retry_error_banner.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/vehicle_search_request_dto.dart';
import '../cubit/vehicle_search_cubit.dart';
import '../cubit/vehicle_search_state.dart';
import 'vehicle_results_screen.dart';

class CarRentalSearchScreen extends StatelessWidget {
  const CarRentalSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VehicleSearchCubit>(),
      child: const _CarRentalSearchView(),
    );
  }
}

class _CarRentalSearchView extends StatefulWidget {
  const _CarRentalSearchView();

  @override
  State<_CarRentalSearchView> createState() => _CarRentalSearchViewState();
}

class _CarRentalSearchViewState extends State<_CarRentalSearchView> {
  String _pickupCity = '';
  String _dropoffCity = '';
  bool _differentDropoff = false;
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _dropoffDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _dropoffTime = const TimeOfDay(hour: 10, minute: 0);
  bool _withDriver = false;
  bool _driverAge25Plus = true;

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  String _formatTime(TimeOfDay time) => "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  Future<void> _pickDate({required bool isPickup}) async {
    final initial = isPickup ? _pickupDate : _dropoffDate;
    final firstDate = isPickup ? DateTime.now() : _pickupDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isPickup) {
        _pickupDate = picked;
        if (!_dropoffDate.isAfter(_pickupDate)) {
          _dropoffDate = _pickupDate.add(const Duration(days: 1));
        }
      } else {
        _dropoffDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isPickup}) async {
    final picked = await showTimePicker(context: context, initialTime: isPickup ? _pickupTime : _dropoffTime);
    if (picked == null) return;
    setState(() {
      if (isPickup) {
        _pickupTime = picked;
      } else {
        _dropoffTime = picked;
      }
    });
  }

  void _submitSearch() {
    final l10n = AppLocalizations.of(context)!;
    if (_pickupCity.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.carSelectPickupError), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final pickupDateTime = DateTime(_pickupDate.year, _pickupDate.month, _pickupDate.day, _pickupTime.hour, _pickupTime.minute);
    final dropoffDateTime = DateTime(_dropoffDate.year, _dropoffDate.month, _dropoffDate.day, _dropoffTime.hour, _dropoffTime.minute);
    if (!dropoffDateTime.isAfter(pickupDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.carDropoffAfterPickupError), backgroundColor: Colors.redAccent),
      );
      return;
    }
    context.read<VehicleSearchCubit>().search(VehicleSearchRequestDto(
      pickupCity: _pickupCity.trim(),
      dropoffCity: _differentDropoff && _dropoffCity.trim().isNotEmpty ? _dropoffCity.trim() : null,
      rentalStart: _formatDate(_pickupDate),
      pickupTime: _formatTime(_pickupTime),
      rentalEnd: _formatDate(_dropoffDate),
      dropoffTime: _formatTime(_dropoffTime),
      withDriver: _withDriver,
      driverAge25Plus: _driverAge25Plus,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<VehicleSearchCubit, VehicleSearchState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == VehicleSearchStatus.loaded) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleResultsScreen(offers: state.offers)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(l10n.carRentalTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CityAutocompleteField(
                geoApiClient: sl<GeoApiClient>(),
                label: l10n.carPickupLocation,
                icon: Icons.location_on_outlined,
                onCitySelected: (value) => _pickupCity = value,
              ),
              const SizedBox(height: 12),
              _toggleChip(l10n.carDifferentDropoff, _differentDropoff, (v) => setState(() => _differentDropoff = v), primaryColor),
              if (_differentDropoff) ...[
                const SizedBox(height: 12),
                CityAutocompleteField(
                  geoApiClient: sl<GeoApiClient>(),
                  label: l10n.carDropoffLocation,
                  icon: Icons.flag_outlined,
                  onCitySelected: (value) => _dropoffCity = value,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _dateTile(l10n.carPickup, _pickupDate, () => _pickDate(isPickup: true), primaryColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _timeTile(l10n.carTime, _pickupTime, () => _pickTime(isPickup: true), primaryColor)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dateTile(l10n.carDropoff, _dropoffDate, () => _pickDate(isPickup: false), primaryColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _timeTile(l10n.carTime, _dropoffTime, () => _pickTime(isPickup: false), primaryColor)),
                ],
              ),
              const SizedBox(height: 16),
              _toggleChip(l10n.carWithDriver, _withDriver, (v) => setState(() => _withDriver = v), primaryColor),
              if (!_withDriver) ...[
                const SizedBox(height: 12),
                _toggleChip(l10n.carDriverAge25Plus, _driverAge25Plus, (v) => setState(() => _driverAge25Plus = v), primaryColor),
              ],
              const SizedBox(height: 24),
              BlocBuilder<VehicleSearchCubit, VehicleSearchState>(
                builder: (context, state) {
                  if (state.status != VehicleSearchStatus.error) return const SizedBox.shrink();
                  return RetryErrorBanner(message: state.errorMessage ?? 'Erreur', onRetry: _submitSearch);
                },
              ),
              const SizedBox(height: 8),
              BlocBuilder<VehicleSearchCubit, VehicleSearchState>(
                builder: (context, state) {
                  final isLoading = state.status == VehicleSearchStatus.loading;
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                          : Text(l10n.commonSearch, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap, Color primaryColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(String label, TimeOfDay time, VoidCallback onTap, Color primaryColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatTime(time),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool value, ValueChanged<bool> onChanged, Color primaryColor) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value ? primaryColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? primaryColor : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: value ? primaryColor : Colors.grey.shade700, fontSize: 13)),
            Switch(value: value, onChanged: onChanged, activeThumbColor: primaryColor),
          ],
        ),
      ),
    );
  }
}
