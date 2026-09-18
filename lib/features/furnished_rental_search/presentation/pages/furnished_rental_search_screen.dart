import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/geo_api_client.dart';
import '../../../../core/widgets/city_autocomplete_field.dart';
import '../../../../core/widgets/retry_error_banner.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/property_search_request_dto.dart';
import '../cubit/property_search_cubit.dart';
import '../cubit/property_search_state.dart';
import 'property_results_screen.dart';

class FurnishedRentalSearchScreen extends StatelessWidget {
  const FurnishedRentalSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PropertySearchCubit>(),
      child: const _FurnishedRentalSearchView(),
    );
  }
}

class _FurnishedRentalSearchView extends StatefulWidget {
  const _FurnishedRentalSearchView();

  @override
  State<_FurnishedRentalSearchView> createState() => _FurnishedRentalSearchViewState();
}

class _FurnishedRentalSearchViewState extends State<_FurnishedRentalSearchView> {
  String _city = '';
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 5));
  int _guests = 2;
  String _bedrooms = 'any'; // 'any' | '1' | '2' | '3' | '4'
  String _propertyType = 'all'; // 'all' | 'apartment' | 'studio' | 'villa'
  bool _entirePlace = true;

  static const _guestOptions = [1, 2, 3, 4, 5, 6, 7, 8, 10];
  static const _bedroomOptions = ['any', '1', '2', '3', '4'];

  Map<String, String> _propertyTypeOptions(AppLocalizations l10n) => {
        'all': l10n.furnishedTypeAll,
        'apartment': l10n.furnishedTypeApartment,
        'studio': l10n.furnishedTypeStudio,
        'villa': l10n.furnishedTypeVilla,
      };

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<void> _pickDate({required bool isCheckIn}) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final firstDate = isCheckIn ? DateTime.now() : _checkIn.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });
  }

  void _submitSearch() {
    if (_city.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.hotelSelectCityError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    context.read<PropertySearchCubit>().search(PropertySearchRequestDto(
      city: _city.trim(),
      checkIn: _formatDate(_checkIn),
      checkOut: _formatDate(_checkOut),
      guests: _guests,
      bedrooms: _bedrooms == 'any' ? null : int.parse(_bedrooms),
      propertyType: _propertyType == 'all' ? null : _propertyType,
      entirePlace: _entirePlace,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<PropertySearchCubit, PropertySearchState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PropertySearchStatus.loaded) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyResultsScreen(offers: state.offers)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(l10n.furnishedTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                label: l10n.hotelCityLabel,
                icon: Icons.location_city_rounded,
                onCitySelected: (value) => _city = value,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _dateTile(l10n.hotelCheckIn, _checkIn, () => _pickDate(isCheckIn: true), primaryColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _dateTile(l10n.hotelCheckOut, _checkOut, () => _pickDate(isCheckIn: false), primaryColor)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _dropdownTile(l10n.furnishedGuests, _guests, _guestOptions.map((g) => DropdownMenuItem(value: g, child: Text('$g'))).toList(), (v) => setState(() => _guests = v!))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdownTile(
                      l10n.furnishedBedrooms,
                      _bedrooms,
                      _bedroomOptions.map((b) => DropdownMenuItem(value: b, child: Text(b == 'any' ? l10n.furnishedAny : '$b+'))).toList(),
                      (v) => setState(() => _bedrooms = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.furnishedPropertyType, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _propertyTypeOptions(l10n).entries.map((entry) {
                  final isSelected = _propertyType == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _propertyType = entry.key),
                    selectedColor: primaryColor.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: isSelected ? primaryColor : Colors.grey.shade600, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade200),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _toggleChip(l10n.furnishedEntirePlace, _entirePlace, (v) => setState(() => _entirePlace = v), primaryColor),
              const SizedBox(height: 24),
              BlocBuilder<PropertySearchCubit, PropertySearchState>(
                builder: (context, state) {
                  if (state.status != PropertySearchStatus.error) return const SizedBox.shrink();
                  return RetryErrorBanner(message: state.errorMessage ?? 'Erreur', onRetry: _submitSearch);
                },
              ),
              const SizedBox(height: 8),
              BlocBuilder<PropertySearchCubit, PropertySearchState>(
                builder: (context, state) {
                  final isLoading = state.status == PropertySearchStatus.loading;
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

  Widget _dropdownTile<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            border: InputBorder.none,
          ),
          items: items,
          onChanged: onChanged,
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
