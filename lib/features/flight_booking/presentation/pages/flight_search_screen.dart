import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guentravel/core/widgets/airport_autocomplete_field.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/geo_api_client.dart';
import '../../../../core/widgets/retry_error_banner.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import 'flight_results_screen.dart';

enum JourneyType { oneWay, roundTrip, multiCity }

class FlightSearchScreen extends StatefulWidget {
  /// Pré-remplit la destination (code aéroport/ville) quand on arrive depuis
  /// une destination populaire de l'accueil (voir DestinationController côté
  /// Spring, dont FeaturedDestinationResponse#destinationCode existe pour ça).
  final String? initialDestinationCode;

  const FlightSearchScreen({super.key, this.initialDestinationCode});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class FlightSegment {
  final TextEditingController originController;
  final TextEditingController destinationController;
  DateTime date;

  FlightSegment({
    required String defaultOrigin,
    required String defaultDestination,
    required this.date,
  })  : originController = TextEditingController(text: defaultOrigin),
        destinationController = TextEditingController(text: defaultDestination);

  void dispose() {
    originController.dispose();
    destinationController.dispose();
  }
}

class _FlightSearchScreenState extends State<FlightSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  JourneyType _selectedJourneyType = JourneyType.oneWay;

  // Contrôleurs existants

  String _airportCode = 'DLA';
  String _airportDesCode = 'CDG';
  DateTime _departureDate = DateTime.now().add(const Duration(days: 1));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 8));
  final List<FlightSegment> _multiCitySegments = [];

  // --- NOUVEAUX PARAMÈTRES GÉRÉS ---
  int _adults = 1;
  int _children = 0;
  int _infants = 0;
  String _selectedCabinClass = 'ECONOMY'; // Valeurs types: ECONOMY, PREMIUM, BUSINESS, FIRST
  String _selectedCurrency = 'XAF';       // Valeur par défaut pour le Cameroun/Afrique Centrale

  final List<String> _currencies = ['XAF', 'EUR', 'USD'];

  Map<String, String> _cabinClasses(AppLocalizations l10n) => {
        'ECONOMY': l10n.flightCabinEconomy,
        'PREMIUM': l10n.flightCabinPremium,
        'BUSINESS': l10n.flightCabinBusiness,
        'FIRST': l10n.flightCabinFirst,
      };

  @override
  void initState() {
    super.initState();
    if (widget.initialDestinationCode != null && widget.initialDestinationCode!.trim().isNotEmpty) {
      _airportDesCode = widget.initialDestinationCode!.trim();
    }
    _multiCitySegments.addAll([
      FlightSegment(defaultOrigin: 'DLA', defaultDestination: 'CDG', date: DateTime.now().add(const Duration(days: 2))),
      FlightSegment(defaultOrigin: 'CDG', defaultDestination: 'JFK', date: DateTime.now().add(const Duration(days: 9))),
    ]);
  }

  @override
  void dispose() {
    for (var segment in _multiCitySegments) {
      segment.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<FlightBookingBloc, FlightBookingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FlightBookingStatus.flightsLoaded) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlightResultsScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildCurvedHeader(l10n, secondaryColor,primaryColor),

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
                          _buildJourneyTypeSelector(l10n, primaryColor),
                          const SizedBox(height: 24),

                          if (_selectedJourneyType != JourneyType.multiCity)
                            _buildStandardForm(l10n, primaryColor)
                          else
                            _buildMultiCityForm(l10n, primaryColor),

                          const SizedBox(height: 16),

                          // Sélecteur combiné Voyageurs + Classe de cabine
                          _buildPassengersAndClassTile(l10n, primaryColor),

                          const SizedBox(height: 24),

                          BlocBuilder<FlightBookingBloc, FlightBookingState>(
                            builder: (context, state) {
                              if (state.status != FlightBookingStatus.failure) return const SizedBox.shrink();
                              return RetryErrorBanner(
                                message: state.errorMessage ?? 'Erreur',
                                onRetry: _submitSearch,
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          // Bouton de Validation
                          BlocBuilder<FlightBookingBloc, FlightBookingState>(
                            builder: (context, state) {
                              final isLoading = state.status == FlightBookingStatus.loading;

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
                                      : Text(
                                    l10n.flightSearchButton,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chaque onglet est enveloppé dans Expanded : 3 ChoiceChip à taille
  // intrinsèque dans un Row(spaceBetween) débordaient dès qu'une traduction
  // (FR ou EN) était un peu plus large que l'espace des 3 côte à côte.
  Widget _buildJourneyTypeSelector(AppLocalizations l10n, Color primaryColor) {
    return Row(
      children: [
        Expanded(child: _journeyTypeTab(JourneyType.oneWay, l10n.flightJourneyOneWay, primaryColor)),
        const SizedBox(width: 8),
        Expanded(child: _journeyTypeTab(JourneyType.roundTrip, l10n.flightJourneyRoundTrip, primaryColor)),
        const SizedBox(width: 8),
        Expanded(child: _journeyTypeTab(JourneyType.multiCity, l10n.flightJourneyMultiCity, primaryColor)),
      ],
    );
  }

  Widget _journeyTypeTab(JourneyType type, String title, Color primaryColor) {
    final isSelected = _selectedJourneyType == type;
    return ChoiceChip(
      label: Text(title, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
      labelPadding: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedJourneyType = type);
        }
      },
      selectedColor: primaryColor.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: isSelected ? primaryColor : Colors.grey.shade200),
      showCheckmark: false,
    );
  }

  Widget _buildStandardForm(AppLocalizations l10n, Color primaryColor) {
    return Column(
      children: [
        IataCodeAutocompleteField(
          geoApiClient: sl<GeoApiClient>(),
          label: l10n.flightOriginLabel,
          icon: Icons.location_city_rounded,
          onCitySelected: (value) => _airportCode = value,
        ),
        const SizedBox(height: 16),
        IataCodeAutocompleteField(
          geoApiClient: sl<GeoApiClient>(),
          label: l10n.flightDestinationLabel,
          icon: Icons.location_city_rounded,
          initialValue: _airportDesCode,
          onCitySelected: (value) => _airportDesCode = value,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDatePickerTile(
                label: l10n.flightDepartDate,
                date: _departureDate,
                primaryColor: primaryColor,
                onDateSelected: (date) => setState(() => _departureDate = date),
              ),
            ),
            if (_selectedJourneyType == JourneyType.roundTrip) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerTile(
                  label: l10n.flightReturnDate,
                  date: _returnDate,
                  primaryColor: primaryColor,
                  firstDate: _departureDate,
                  onDateSelected: (date) => setState(() => _returnDate = date),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMultiCityForm(AppLocalizations l10n, Color primaryColor) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _multiCitySegments.length,
          separatorBuilder: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, thickness: 1),
          ),
          itemBuilder: (context, index) {
            final segment = _multiCitySegments[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.flightSegmentNumber(index + 1),
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                    ),
                    if (_multiCitySegments.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => _multiCitySegments.removeAt(index)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: segment.originController,
                        label: l10n.flightFrom,
                        icon: Icons.flight_takeoff_rounded,
                        primaryColor: primaryColor,
                        invalidMessage: l10n.flightIataInvalid,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        controller: segment.destinationController,
                        label: l10n.flightTo,
                        icon: Icons.flight_land_rounded,
                        primaryColor: primaryColor,
                        invalidMessage: l10n.flightIataInvalid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDatePickerTile(
                  label: l10n.flightSegmentDate,
                  date: segment.date,
                  primaryColor: primaryColor,
                  onDateSelected: (date) => setState(() => segment.date = date),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (_multiCitySegments.length < 4)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                final lastDate = _multiCitySegments.last.date;
                _multiCitySegments.add(FlightSegment(
                  defaultOrigin: _multiCitySegments.last.destinationController.text,
                  defaultDestination: '',
                  date: lastDate.add(const Duration(days: 3)),
                ));
              });
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.flightAddDestination),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  // --- NOUVEAU TILE : SELECTION VOYAGEURS ET CLASSE ---
  Widget _buildPassengersAndClassTile(AppLocalizations l10n, Color primaryColor) {
    final totalPassengers = _adults + _children + _infants;
    final classLabel = _cabinClasses(l10n)[_selectedCabinClass] ?? l10n.flightCabinEconomy;

    return InkWell(
      onTap: () => _showPassengersBottomSheet(l10n, primaryColor),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: Colors.grey.shade400, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.flightTravelersAndClass, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.flightPassengersPlural(totalPassengers)} • $classLabel',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: primaryColor),
          ],
        ),
      ),
    );
  }

  // --- NOUVELLE BOTTOM SHEET POUR CONFIGURER LES VOYAGEURS ---
  void _showPassengersBottomSheet(AppLocalizations l10n, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.flightTravelersTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildCounterRow(l10n.flightAdults, l10n.flightAdultsSubtitle, _adults, (val) {
                    if (val >= 1) setSheetState(() => _adults = val);
                  }),
                  _buildCounterRow(l10n.flightChildren, l10n.flightChildrenSubtitle, _children, (val) {
                    if (val >= 0) setSheetState(() => _children = val);
                  }),
                  _buildCounterRow(l10n.flightInfants, l10n.flightInfantsSubtitle, _infants, (val) {
                    if (val >= 0) setSheetState(() => _infants = val);
                  }),
                  const Divider(height: 32),
                  Text(l10n.flightTravelClass, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cabinClasses(l10n).entries.map((entry) {
                      final isSelected = _selectedCabinClass == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setSheetState(() => _selectedCabinClass = entry.key);
                        },
                        selectedColor: primaryColor.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Synchronise le Widget Principal
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.commonConfirm, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCounterRow(String title, String subtitle, int value, ValueChanged<int> onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                onPressed: () => onChange(value - 1),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 30),
               // textAlign: TextAlign.center,
                child: Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                onPressed: () => onChange(value + 1),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _submitSearch() {
    if (_formKey.currentState!.validate()) {
      final bloc = context.read<FlightBookingBloc>();

      if (_selectedJourneyType == JourneyType.multiCity) {
        // Optionnel : Gérer ici le dispatch multi-city si besoin
      } else {
        bloc.add(
          SearchFlightsRequested(
            departure: _airportCode.trim(),
            destination: _airportDesCode.trim(),
            departureDate: _departureDate,
            journeyType: _selectedJourneyType == JourneyType.roundTrip ? 'ROUND_TRIP' : 'ONE_WAY',
            adults: _adults,
            children: _children,
            infants: _infants,
            cabinClass: _selectedCabinClass,
            currency: _selectedCurrency,
          ),
        );
      }
    }
  }

  // --- EN-TÊTE MODIFIÉ AVEC LE SÉLECTEUR DE DEVISE ---
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
                'Guentravel Flights',
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
                    value: _selectedCurrency,
                    dropdownColor: primaryColor,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedCurrency = newValue);
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
            l10n.flightHeaderSubtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    required String invalidMessage,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      maxLength: 3,
      validator: (value) {
        if (value == null || value.trim().length != 3) {
          return invalidMessage;
        }
        return null;
      },
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime date,
    required Color primaryColor,
    required ValueChanged<DateTime> onDateSelected,
    DateTime? firstDate,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date.isBefore(firstDate ?? DateTime.now()) ? (firstDate ?? DateTime.now()) : date,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: primaryColor),
          ],
        ),
      ),
    );
  }
}