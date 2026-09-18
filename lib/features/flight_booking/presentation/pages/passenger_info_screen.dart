import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import 'flight_payment_screen.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

// Modèle local pour gérer les contrôleurs de chaque passager
class PassengerFormState {
  final String type; // 'ADULT', 'CHILD', 'INFANT'
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passportController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  // Nationalité : obligatoire côté backend pour toute réservation de vol
  // (BookingService.validateFlightTravelers rejette la réservation sinon).
  final TextEditingController nationalityController = TextEditingController(text: 'CM');
  final TextEditingController passportIssueCountryController = TextEditingController();
  final TextEditingController passportExpiryController = TextEditingController();
  DateTime? selectedRawDate;
  DateTime? selectedPassportExpiryDate;

  PassengerFormState({required this.type});

  void dispose() {
    nameController.dispose();
    passportController.dispose();
    dobController.dispose();
    nationalityController.dispose();
    passportIssueCountryController.dispose();
    passportExpiryController.dispose();
  }
}

class PassengerInfoScreen extends StatefulWidget {
  const PassengerInfoScreen({super.key});

  @override
  State<PassengerInfoScreen> createState() => _PassengerInfoScreenState();
}

class _PassengerInfoScreenState extends State<PassengerInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs Contacts d'achat (Uniques pour toute la réservation)
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  // Liste pour stocker les formulaires de chaque passager
  final List<PassengerFormState> _passengerForms = [];

  @override
  void initState() {
    super.initState();
    // Récupération des types de passagers depuis l'état du BLoC (Défini lors de la recherche)
    final currentState = context.read<FlightBookingBloc>().state;

    final List<String> passengerTypes = currentState.passengerTypes;

    // Initialiser un formulaire pour chaque passager
    for (var type in passengerTypes) {
      _passengerForms.add(PassengerFormState(type: type));
    }

    // Pré-remplissage depuis le compte connecté (email de contact + nom du
    // premier passager, celui-ci étant conventionnellement le responsable de
    // la réservation) - même logique que le frontend Next.js, qui pré-remplit
    // le formulaire de checkout depuis la session utilisateur. ProfileUser ne
    // porte pas de téléphone (voir AuthResponse côté Java), donc rien à
    // préremplir pour ce champ.
    final authState = sl<AuthCubit>().state;
    if (authState.isAuthenticated && authState.user != null) {
      _contactEmailController.text = authState.user!.email;
      if (_passengerForms.isNotEmpty) {
        _passengerForms.first.nameController.text = authState.user!.fullName;
      }
    }
  }

  @override
  void dispose() {
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    for (var form in _passengerForms) {
      form.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<FlightBookingBloc, FlightBookingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == FlightBookingStatus.paymentReady && state.confirmedBooking != null) {
          final amount = state.confirmedBooking!.amountDue ?? state.confirmedBooking!.price;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlightPaymentScreen(flightPrice: amount?.amount ?? 0),
            ),
          );
        } else if (state.status == FlightBookingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Une erreur est survenue.'), backgroundColor: Colors.red.shade600),
          );
        }
      },
      child: Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Infos Personnelles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<FlightBookingBloc, FlightBookingState>(
        builder: (context, state) {
          final seatCodes = state.selectedSeatCodesByTraveler;
          final seatPicked = seatCodes.isNotEmpty ? seatCodes.join(', ') : 'Aucun';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar central
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: primaryColor.withValues(alpha: 0.1),
                                child: Icon(Icons.person_rounded, size: 45, color: primaryColor),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section 1: Informations de contact d'achat (Unique)
                        _buildSectionHeader('Responsable de la réservation'),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: _contactEmailController,
                          label: 'Email de contact',
                          icon: Icons.email_outlined,
                          primaryColor: primaryColor,
                          validator: (value) => value == null || !value.contains('@') ? 'Veuillez entrer un email valide' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _contactPhoneController,
                          label: 'Téléphone de contact',
                          icon: Icons.phone_android_outlined,
                          primaryColor: primaryColor,
                          validator: (value) => value == null || value.isEmpty ? 'Téléphone requis' : null,
                        ),

                        const SizedBox(height: 28),

                        // Badge récapitulatif des sièges
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flight_class_rounded, size: 16, color: primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                "Sièges sélectionnés : $seatPicked",
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                        // Section 2: Détails dynamiques des passagers
                        ..._passengerForms.asMap().entries.map((entry) {
                          int index = entry.key;
                          PassengerFormState passengerData = entry.value;

                          // Traduction du type pour l'affichage
                          String displayType = passengerData.type == 'CHILD' ? 'Enfant'
                              : passengerData.type == 'INFANT' ? 'Bébé'
                              : 'Adulte';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 28.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Passager ${index + 1} ($displayType)'),
                                const SizedBox(height: 12),
                                _buildInputField(
                                  controller: passengerData.nameController,
                                  label: 'Nom complet (tel que sur le passeport)',
                                  icon: Icons.assignment_ind_outlined,
                                  primaryColor: primaryColor,
                                  validator: (value) => value == null || value.trim().length < 3 ? 'Entrez le nom complet' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: passengerData.passportController,
                                  label: 'Numéro de passeport',
                                  icon: Icons.badge_outlined,
                                  primaryColor: primaryColor,
                                  validator: (value) => value == null || value.isEmpty ? 'Numéro de passeport requis' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: passengerData.dobController,
                                  label: 'Date de naissance',
                                  icon: Icons.cake_outlined,
                                  primaryColor: primaryColor,
                                  readOnly: true,
                                  validator: (value) => value == null || value.isEmpty ? 'Date de naissance requise' : null,
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime(1995),
                                      firstDate: DateTime(1920),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        passengerData.selectedRawDate = pickedDate;
                                        passengerData.dobController.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: passengerData.nationalityController,
                                  label: 'Nationalité (code pays, ex: CM)',
                                  icon: Icons.flag_outlined,
                                  primaryColor: primaryColor,
                                  textCapitalization: TextCapitalization.characters,
                                  maxLength: 2,
                                  validator: (value) => (value == null || !RegExp(r'^[A-Za-z]{2}$').hasMatch(value.trim()))
                                      ? 'Code pays ISO2 requis (ex: CM)'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: passengerData.passportIssueCountryController,
                                  label: 'Pays d\'émission du passeport (optionnel)',
                                  icon: Icons.flag_outlined,
                                  primaryColor: primaryColor,
                                  textCapitalization: TextCapitalization.characters,
                                  maxLength: 2,
                                  validator: (value) => (value != null && value.trim().isNotEmpty && !RegExp(r'^[A-Za-z]{2}$').hasMatch(value.trim()))
                                      ? 'Code pays ISO2 (ex: CM)'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: passengerData.passportExpiryController,
                                  label: 'Expiration du passeport (optionnel)',
                                  icon: Icons.calendar_today_rounded,
                                  primaryColor: primaryColor,
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().add(const Duration(days: 365)),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365 * 15)),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        passengerData.selectedPassportExpiryDate = pickedDate;
                                        passengerData.passportExpiryController.text = "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Zone d'action de sauvegarde
              _buildBottomActionSection(secondaryColor, state.status == FlightBookingStatus.loading),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        counterText: maxLength != null ? '' : null,
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(height: 0.8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildBottomActionSection(Color actionColor, bool isLoading) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : () {
            // Vérifier que le formulaire est valide ET que toutes les dates de naissance sont remplies
            bool allDatesSelected = _passengerForms.every((p) => p.selectedRawDate != null);

            if (_formKey.currentState!.validate() && allDatesSelected) {

              // 1. Construire la liste typée (TravelerInfo)
              List<TravelerInfo> travelersList = _passengerForms.asMap().entries.map((entry) {
                int index = entry.key;
                PassengerFormState p = entry.value;

                // Extras (sièges/bagages/repas/assurance) choisis pour CE passager -
                // répartis par paxRef ("T1".."Tn"), même logique que
                // applySelectedExtras côté Next.js. Remplace l'ancien seatNumber
                // positionnel.
                final state = context.read<FlightBookingBloc>().state;
                final ancillaryIds = state.ancillaryIdsForTraveler(index);

                return TravelerInfo(
                  fullName: p.nameController.text.trim(),
                  dateOfBirth: p.selectedRawDate!, // Passe l'objet DateTime direct
                  passportNumber: p.passportController.text.trim().toUpperCase(),
                  type: p.type, // 'ADULT', etc.
                  // Requis par le backend pour toute réservation de vol
                  // (BookingService.validateFlightTravelers).
                  nationality: p.nationalityController.text.trim().toUpperCase(),
                  passportIssueCountry: p.passportIssueCountryController.text.trim().isEmpty
                      ? null
                      : p.passportIssueCountryController.text.trim().toUpperCase(),
                  passportExpiryDate: p.selectedPassportExpiryDate,
                  selectedAncillaryIds: ancillaryIds.isEmpty ? null : ancillaryIds,
                );
              }).toList();

              // Envoi de l'événement au Bloc ; la navigation vers l'écran de
              // paiement se fait dans le BlocListener une fois le checkout
              // terminé (state.status == paymentReady), pas ici — le checkout
              // est asynchrone et n'a pas encore de bookingId à cet instant.
              context.read<FlightBookingBloc>().add(PassengerInfoSubmitted(
                contactEmail: _contactEmailController.text.trim(),
                contactFullName: _passengerForms.first.nameController.text.trim(),
                contactPhone: _contactPhoneController.text.trim(),
                travelers: travelersList,
              ));
            } else if (!allDatesSelected) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Veuillez sélectionner la date de naissance pour tous les passagers")),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
            'Confirmer et Continuer',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}