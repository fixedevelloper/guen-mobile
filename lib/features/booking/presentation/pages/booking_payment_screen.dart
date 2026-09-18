import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/models/payment_request.dart';
import '../../../../core/models/booking_response.dart';
import '../../../payment/presentation/pages/external_payment_screen.dart';
import '../../data/datasources/booking_api_client.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'booking_confirmation_screen.dart';
import 'booking_payment_pending_screen.dart';

class BookingPaymentScreen extends StatelessWidget {
  final BookingResponse booking;

  const BookingPaymentScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingCubit>(),
      child: _BookingPaymentView(booking: booking),
    );
  }
}

class _BookingPaymentView extends StatefulWidget {
  final BookingResponse booking;

  const _BookingPaymentView({required this.booking});

  @override
  State<_BookingPaymentView> createState() => _BookingPaymentViewState();
}

class _BookingPaymentViewState extends State<_BookingPaymentView> {
  final _formKey = GlobalKey<FormState>();
  int _selectedPaymentMethod = 0; // 0: Carte / Wallet, 1: Mobile Money

  final _phoneNumberController = TextEditingController();

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    // Carte / Google Pay / Apple Pay / PayPal : le backend route ces méthodes
    // vers une Checkout Session Stripe (voir StripePaymentGateway côté Java) -
    // aucune donnée de carte ne transite par ce formulaire ni par ce backend.
    // On renvoie le payeur vers la page de paiement Next.js, qui sait déjà
    // monter l'Embedded Checkout Stripe correctement (voir
    // ExternalPaymentScreen).
    if (_selectedPaymentMethod == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExternalPaymentScreen(
            bookingId: widget.booking.id,
            fetchBooking: (id) => sl<BookingApiClient>().getBooking(id, email: widget.booking.contactEmail),
            onConfirmed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingConfirmationScreen(booking: widget.booking, paymentConfirmed: true),
                ),
                (route) => route.isFirst,
              );
            },
          ),
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{8,9}$').hasMatch(_phoneNumberController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro de téléphone valide'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final amount = widget.booking.amountDue ?? widget.booking.price;

    context.read<BookingCubit>().submitPayment(PaymentRequest(
      bookingId: widget.booking.id,
      paymentMethod: 'MOBILE_MONEY',
      countryCode: 'CM',
      countryCurrency: amount?.currency ?? 'XAF',
      mobileNumber: '+237${_phoneNumberController.text.trim()}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final amount = widget.booking.amountDue ?? widget.booking.price;

    return BlocListener<BookingCubit, BookingFlowState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == BookingStatus.succeeded) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => BookingConfirmationScreen(booking: widget.booking, paymentConfirmed: true)),
                (route) => route.isFirst,
          );
        } else if (state.status == BookingStatus.paymentPending ||
            state.status == BookingStatus.paymentPendingAuthorization) {
          // BookingCubit est fourni localement à cette route (pas à la racine
          // de l'app comme FlightBookingBloc) : il faut le repropager
          // explicitement, la nouvelle route poussée n'en hérite pas.
          final cubit = context.read<BookingCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: BookingPaymentPendingScreen(booking: widget.booking),
              ),
            ),
          );
        } else if (state.errorMessage != null && state.status == BookingStatus.awaitingPayment) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red.shade600),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Paiement', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Montant à régler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(
                            amount?.format() ?? '—',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: secondaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Mode de règlement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 16),
                    _buildMethodSelector(primaryColor),
                    const SizedBox(height: 24),
                    if (_selectedPaymentMethod == 0)
                      _buildStripeHandoffNotice(primaryColor)
                    else
                      _buildMobileMoneyForm(primaryColor),
                  ],
                ),
              ),
              _buildBottomAction(primaryColor, secondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(Color primaryColor) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Carte / Wallet'), icon: Icon(Icons.credit_card_rounded)),
        ButtonSegment(value: 1, label: Text('Mobile Money'), icon: Icon(Icons.phone_android_rounded)),
      ],
      selected: {_selectedPaymentMethod},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => setState(() => _selectedPaymentMethod = selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: primaryColor.withValues(alpha: 0.1),
        selectedForegroundColor: primaryColor,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade200),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  /// Même message de confiance que côté Next.js (PaymentForm) : carte/Google
  /// Pay/Apple Pay/PayPal ne collectent rien ici, tout se passe chez Stripe à
  /// l'étape suivante (voir ExternalPaymentScreen).
  Widget _buildStripeHandoffNotice(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
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
        TextFormField(
          controller: _phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration('Numéro de téléphone (ex: 6xxxxxxxxx)', Icons.phone, primaryColor),
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

  InputDecoration _inputDecoration(String label, IconData icon, Color primaryColor) {
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

  Widget _buildBottomAction(Color primaryColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 32, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: BlocBuilder<BookingCubit, BookingFlowState>(
        builder: (context, state) {
          final isLoading = state.status == BookingStatus.payingNow;
          return SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _selectedPaymentMethod == 0 ? 'Continuer vers le paiement sécurisé' : 'Payer',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          );
        },
      ),
    );
  }
}
