import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/payment_request.dart';
import '../../../payment/presentation/pages/external_payment_screen.dart';
import '../../data/datasources/flight_api_client.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import 'boarding_pass_screen.dart';
import 'payment_pending_screen.dart';

class FlightPaymentScreen extends StatefulWidget {
  final double flightPrice; // Montant reçu depuis l'écran précédent

  const FlightPaymentScreen({
    super.key,
    required this.flightPrice,
  });

  @override
  State<FlightPaymentScreen> createState() => _FlightPaymentScreenState();
}

class _FlightPaymentScreenState extends State<FlightPaymentScreen> {
  int _selectedBillingOption = 0; // 0: Payer maintenant, 1: Réserver pour plus tard
  int _selectedPaymentMethod = 0; // 0: Carte Bancaire, 1: Mobile Money
  String _selectedMomoOperator = 'ORANGE'; // 'ORANGE' ou 'MTN'

  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Calcul dynamique du montant à régler selon le choix.
  // Le montant de l'acompte "Réserver (Plus tard)" est calculé côté serveur
  // (BookingResponse.reservationFee) : il dépend de l'offre, pas d'une constante.
  double get _currentAmountToPay {
    if (_selectedBillingOption == 1) {
      final reservationFee =
          context.read<FlightBookingBloc>().state.confirmedBooking?.reservationFee;
      return reservationFee?.amount ?? widget.flightPrice;
    }
    return widget.flightPrice; // Montant total du vol reçu
  }

  void _submitPayment() {
    final blocState = context.read<FlightBookingBloc>().state;
    final bookingId = blocState.bookingId;
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation introuvable, veuillez réessayer.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Carte / Google Pay / Apple Pay / PayPal : le backend route ces méthodes
    // vers une Checkout Session Stripe (voir StripePaymentGateway côté Java) -
    // aucune donnée de carte ne transite par ce formulaire ni par ce backend.
    // On renvoie simplement le payeur vers la page de paiement Next.js, qui
    // sait déjà monter l'Embedded Checkout Stripe correctement.
    if (_selectedPaymentMethod == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExternalPaymentScreen(
            bookingId: bookingId,
            fetchBooking: (id) => sl<FlightApiClient>().getBooking(id, email: blocState.confirmedBooking?.contactEmail),
            onConfirmed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const BoardingPassScreen()),
                (route) => route.isFirst,
              );
            },
          ),
        ),
      );
      return;
    }

    // Validation du numéro de téléphone Mobile Money — le backend exige
    // exactement /^\+?\d{8,15}$/ une fois le préfixe pays ajouté (PaymentService).
    final digitsOnly = _phoneNumberController.text.trim();
    if (!RegExp(r'^\d{8,9}$').hasMatch(digitsOnly)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro de téléphone valide'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final request = PaymentRequest(
      bookingId: bookingId,
      paymentMethod: 'MOBILE_MONEY',
      countryCode: 'CM',
      countryCurrency: 'XAF',
      mobileNumber: '+237${_phoneNumberController.text.trim()}',
    );

    context.read<FlightBookingBloc>().add(PaymentSubmitted(request));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocConsumer<FlightBookingBloc, FlightBookingState>(
      listenWhen: (previous, current) =>
          previous.paymentStatus != current.paymentStatus || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.paymentStatus == PaymentStatus.success) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BoardingPassScreen()),
                (route) => route.isFirst,
          );
        } else if (state.paymentStatus == PaymentStatus.pending ||
            state.paymentStatus == PaymentStatus.pendingAuthorization) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentPendingScreen()));
        } else if (state.paymentStatus == PaymentStatus.failed && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red.shade600),
          );
        }
      },
      builder: (context, state) {
        final bool isPayLater = _selectedBillingOption == 1;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('Paiement & Réservation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
              onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
            ),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBillingOptionSelector(primaryColor),
                        const SizedBox(height: 20),
                        _buildPriceSummaryCard(secondaryColor),
                        const SizedBox(height: 32),
                        Text(
                          'Mode de règlement',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentMethodSelector(primaryColor),
                        const SizedBox(height: 28),
                        if (_selectedPaymentMethod == 0) ...[
                          _buildStripeHandoffNotice(primaryColor),
                        ] else ...[
                          _buildMobileMoneyForm(primaryColor),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildBottomActionSection(primaryColor, secondaryColor, isPayLater, state.isSubmitting),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillingOptionSelector(Color activeColor) {
    return Row(
      children: [
        Expanded(
          child: _buildChoiceChip(
            index: 0,
            title: 'Payer maintenant',
            subtitle: 'Règlement total',
            icon: Icons.bolt_rounded,
            activeColor: activeColor,
            isSelected: _selectedBillingOption == 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildChoiceChip(
            index: 1,
            title: 'Réserver (Plus tard)',
            subtitle: 'Frais : 5 000 XAF',
            icon: Icons.calendar_today_rounded,
            activeColor: activeColor,
            isSelected: _selectedBillingOption == 1,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedBillingOption = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard(Color highlightColor) {
    final bool isReservation = _selectedBillingOption == 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isReservation ? 'Frais de Réservation' : 'Montant Total',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                isReservation ? 'Bloque le tarif du billet' : 'Vol sélectionné inclus',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
          Text(
            '${_currentAmountToPay.toStringAsFixed(0)} XAF',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: highlightColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(Color activeColor) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('Carte / Wallet'),
          icon: Icon(Icons.credit_card_rounded),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Mobile Money'),
          icon: Icon(Icons.phone_android_rounded),
        ),
      ],
      selected: {_selectedPaymentMethod},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => setState(() => _selectedPaymentMethod = selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: activeColor.withValues(alpha: 0.1),
        selectedForegroundColor: activeColor,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade200),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  /// Carte/Google Pay/Apple Pay/PayPal ne collectent rien ici : ces méthodes
  /// sont routées vers Stripe côté backend, qui affiche son propre formulaire
  /// (voir ExternalPaymentScreen). Même message de confiance que côté Next.js
  /// (PaymentForm) - "tu saisiras tes informations de paiement à l'étape
  /// suivante, directement chez notre partenaire Stripe".
  Widget _buildStripeHandoffNotice(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15), style: BorderStyle.solid),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Tu saisiras tes informations de paiement à l'étape suivante, directement et en "
              "toute sécurité chez notre partenaire de paiement Stripe.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMoneyForm(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez votre opérateur',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOperatorTile(
                id: 'ORANGE',
                name: 'Orange Money',
                color: Colors.orange.shade700,
                logoAssetOrIcon: Icons.money_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOperatorTile(
                id: 'MTN',
                name: 'MTN MoMo',
                color: const Color(0xFFFFCC00),
                textColor: Colors.black87,
                logoAssetOrIcon: Icons.phonelink_ring_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Numéro de téléphone',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration: _buildInputDecoration('Ex: 6xxxxxxxxx', Icons.phone, primaryColor).copyWith(
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text(
                '+237 ',
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Une demande de confirmation USSD / PIN sera envoyée sur votre mobile.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperatorTile({
    required String id,
    required String name,
    required Color color,
    Color textColor = Colors.white,
    required IconData logoAssetOrIcon,
  }) {
    final isSelected = _selectedMomoOperator == id;
    return InkWell(
      onTap: () => setState(() => _selectedMomoOperator = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(logoAssetOrIcon, color: isSelected ? textColor : Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? textColor : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Widget _buildBottomActionSection(Color primaryColor, Color secondaryColor, bool isPayLater, bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 36, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submitPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPayLater ? const Color(0xFF10B981) : primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: isSubmitting
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
            _selectedPaymentMethod == 0
                ? 'Continuer vers le paiement sécurisé'
                : isPayLater
                    ? 'Régler les frais d\'option (5 000 XAF)'
                    : 'Payer ${_currentAmountToPay.toStringAsFixed(0)} XAF',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}