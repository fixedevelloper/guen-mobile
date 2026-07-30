import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/payment_request.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import 'boarding_pass_screen.dart';

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
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Calcul dynamique du montant à régler selon le choix
  double get _currentAmountToPay {
    if (_selectedBillingOption == 1) {
      return 5000.0; // Frais d'option / réservation fixe
    }
    return widget.flightPrice; // Montant total du vol reçu
  }

  void _submitPayment() {
    final blocState = context.read<FlightBookingBloc>().state;
    final bookingId = blocState.bookingId ?? "BKG-${DateTime.now().millisecondsSinceEpoch}";

    // Validation du numéro de téléphone si Mobile Money
    if (_selectedPaymentMethod == 1) {
      if (_phoneNumberController.text.trim().isEmpty || _phoneNumberController.text.trim().length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un numéro de téléphone valide'), backgroundColor: Colors.redAccent),
        );
        return;
      }
    } else {
      // Validation du formulaire de carte si Carte bancaire
      if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
        return;
      }
    }

    String planString = _selectedBillingOption == 0 ? 'PAY_NOW' : 'PAY_LATER';
    String methodString;

    if (_selectedPaymentMethod == 0) {
      methodString = 'CARD';
    } else {
      methodString = _selectedMomoOperator == 'ORANGE' ? 'ORANGE_MONEY' : 'MTN_MONEY';
    }

    final request = PaymentRequest(
      bookingId: bookingId,
      paymentPlan: planString,
      paymentMethod: methodString,
      cardNumber: _selectedPaymentMethod == 0 ? _cardNumberController.text.replaceAll(' ', '') : null,
      cardHolderName: _selectedPaymentMethod == 0 ? _cardHolderController.text.trim() : null,
      expiry: _selectedPaymentMethod == 0 ? _expiryController.text.trim() : null,
      cvv: _selectedPaymentMethod == 0 ? _cvvController.text.trim() : null,
      mobileNumber: _selectedPaymentMethod == 1 ? _phoneNumberController.text.trim() : null,
    );

    context.read<FlightBookingBloc>().add(PaymentSubmitted(request));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocConsumer<FlightBookingBloc, FlightBookingState>(
      listener: (context, state) {
        if (state.isSubmitting) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BoardingPassScreen()),
                (route) => route.isFirst,
          );
        } else if (state.errorMessage != null) {
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
                          _buildCreditCardForm(primaryColor),
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
          color: isSelected ? activeColor.withOpacity(0.05) : Colors.white,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
    return Row(
      children: [
        Expanded(
          child: _buildMethodTile(
            index: 0,
            label: 'Carte Crédit',
            icon: Icons.credit_card_rounded,
            activeColor: activeColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMethodTile(
            index: 1,
            label: 'Mobile Money',
            icon: Icons.phone_android_rounded,
            activeColor: activeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile({required int index, required String label, required IconData icon, required Color activeColor}) {
    final isSelected = _selectedPaymentMethod == index;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey.shade400, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardForm(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de la carte',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('Numéro de carte', Icons.payment_rounded, primaryColor),
          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardHolderController,
          keyboardType: TextInputType.name,
          decoration: _buildInputDecoration('Nom du titulaire', Icons.person_outline_rounded, primaryColor),
          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('MM/AA', Icons.calendar_today_rounded, primaryColor),
                validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: _buildInputDecoration('CVV', Icons.lock_outline_rounded, primaryColor),
                validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
              ),
            ),
          ],
        ),
      ],
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
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
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
            isPayLater
                ? 'Régler les frais d\'option (5 000 XAF)'
                : 'Payer ${_currentAmountToPay.toStringAsFixed(0)} XAF',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}