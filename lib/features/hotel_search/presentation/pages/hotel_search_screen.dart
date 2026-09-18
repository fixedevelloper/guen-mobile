import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/geo_api_client.dart';
import '../../../../core/widgets/city_autocomplete_field.dart';
import '../../../../core/widgets/retry_error_banner.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/hotel_search_request_dto.dart';
import '../cubit/hotel_search_cubit.dart';
import '../cubit/hotel_search_state.dart';
import 'hotel_results_screen.dart';

class HotelSearchScreen extends StatelessWidget {
  const HotelSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HotelSearchCubit>(),
      child: const _HotelSearchView(),
    );
  }
}

class _HotelSearchView extends StatefulWidget {
  const _HotelSearchView();

  @override
  State<_HotelSearchView> createState() => _HotelSearchViewState();
}

class _HotelSearchViewState extends State<_HotelSearchView> {
  final _formKey = GlobalKey<FormState>();
  String _cityCode = '';
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  int _adults = 1;
  int _rooms = 1;
  String _currency = 'XAF';

  final List<String> _currencies = ['XAF', 'EUR', 'USD'];
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

  String _formatDate(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  void _submitSearch() {
    if (!_formKey.currentState!.validate() || _cityCode.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.hotelSelectCityError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    context.read<HotelSearchCubit>().search(HotelSearchRequestDto(
      cityCode: _cityCode.trim(),
      checkIn: _formatDate(_checkIn),
      checkOut: _formatDate(_checkOut),
      adults: _adults,
      rooms: _rooms,
      currency: _currency,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<HotelSearchCubit, HotelSearchState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == HotelSearchStatus.loaded) {
          // HotelSearchCubit est fourni localement à cette route : il faut le
          // repropager explicitement pour que l'écran de résultats puisse
          // déclencher loadMore() sur la même instance/recherche.
          final cubit = context.read<HotelSearchCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(value: cubit, child: const HotelResultsScreen()),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildCurvedHeader(l10n, primaryColor,secondaryColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CityAutocompleteField(
                        geoApiClient: sl<GeoApiClient>(),
                        label: l10n.hotelCityLabel,
                        icon: Icons.location_city_rounded,
                        onCitySelected: (value) => _cityCode = value,
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
                          Expanded(child: _counterTile(l10n.hotelAdults, _adults, (v) => setState(() => _adults = v), min: 1, max: 9)),
                          const SizedBox(width: 12),
                          Expanded(child: _counterTile(l10n.hotelRooms, _rooms, (v) => setState(() => _rooms = v), min: 1, max: 5)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _currencySelector(primaryColor),
                      const SizedBox(height: 24),
                      BlocBuilder<HotelSearchCubit, HotelSearchState>(
                        builder: (context, state) {
                          if (state.status != HotelSearchStatus.error) return const SizedBox.shrink();
                          return RetryErrorBanner(
                            message: state.errorMessage ?? 'Erreur',
                            onRetry: _submitSearch,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      BlocBuilder<HotelSearchCubit, HotelSearchState>(
                        builder: (context, state) {
                          final isLoading = state.status == HotelSearchStatus.loading;
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
                ))))
            ],
          )
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
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

  // Libellé au-dessus des contrôles (plutôt que sur la même ligne, comme
  // _dateTile) : sur une tuile à moitié d'écran, un Row unique n'a pas assez
  // de place pour le libellé + 2 IconButton + la valeur sans les faire
  // s'écraser mutuellement.
  Widget _counterTile(String label, int value, ValueChanged<int> onChanged, {required int min, required int max}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildCurvedHeader(AppLocalizations l10n, Color primaryColor, Color secondaryColor) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Guentravel Hotels',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              // Petit sélecteur épuré de devise
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currency,
                    dropdownColor: primaryColor,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _currency = newValue);
                      }
                    },
                    items: _currencies.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.hotelHeaderSubtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
  Widget _currencySelector(Color primaryColor) {
    return Row(
      children: _currencies.map((c) {
        final isSelected = _currency == c;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(c),
            selected: isSelected,
            onSelected: (_) => setState(() => _currency = c),
            selectedColor: primaryColor.withValues(alpha: 0.12),
            labelStyle: TextStyle(color: isSelected ? primaryColor : Colors.grey.shade600, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade200),
            showCheckmark: false,
          ),
        );
      }).toList(),
    );
  }
}
