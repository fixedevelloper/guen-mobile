import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/booking_response.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'booking_confirmation_screen.dart';

/// Affiché quand un paiement est PENDING (Mobile Money : confirmation USSD
/// asynchrone, résolue par un webhook gateway) ou PENDING_AUTHORIZATION
/// (carte : PIN/AVS/OTP/redirection 3DS synchrone). Poll GET /payments/{id}
/// pour le premier cas, collecte le code pour le second (voir
/// PaymentController côté Spring : aucun webhook ne résout cette étape seul).
/// Miroir de PaymentPendingScreen (flight_booking), pour le checkout
/// générique hôtel/véhicule/logement.
class BookingPaymentPendingScreen extends StatefulWidget {
  final BookingResponse booking;

  const BookingPaymentPendingScreen({super.key, required this.booking});

  @override
  State<BookingPaymentPendingScreen> createState() => _BookingPaymentPendingScreenState();
}

class _BookingPaymentPendingScreenState extends State<BookingPaymentPendingScreen> {
  Timer? _pollTimer;
  bool _dialogOpen = false;
  bool _redirectLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reactToState(context.read<BookingCubit>().state));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
      context.read<BookingCubit>().refreshPaymentStatus();
    });
  }

  void _reactToState(BookingFlowState state) {
    if (state.status == BookingStatus.paymentPending) {
      _startPolling();
      return;
    }
    if (state.status != BookingStatus.paymentPendingAuthorization) return;

    final authType = state.paymentResult?.authorizationType;
    if (authType == 'REDIRECT') {
      final url = state.paymentResult?.authorizationRedirectUrl;
      if (url != null && !_redirectLaunched) {
        _redirectLaunched = true;
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      _startPolling();
    } else if (authType == 'PIN' || authType == 'OTP') {
      if (!_dialogOpen) {
        _pollTimer?.cancel();
        _pollTimer = null;
        _showCodeDialog(authType);
      }
    } else {
      // This screen only ever gets reached for MOBILE_MONEY today (CARD is
      // routed to ExternalPaymentScreen before ever calling POST /payments -
      // see booking_payment_screen.dart), so a Stripe CLIENT_ACTION challenge
      // should never land here. Fail loudly instead of showing the wrong
      // "enter your PIN" prompt for a challenge type it can't actually
      // resolve, in case that assumption ever breaks.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Type d\'authentification non pris en charge : ${authType ?? "inconnu"}.'),
            backgroundColor: Colors.red.shade600),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showCodeDialog(String? authType) async {
    _dialogOpen = true;
    final controller = TextEditingController();
    final cubit = context.read<BookingCubit>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Authentification requise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authType == 'OTP'
                    ? 'Entrez le code OTP reçu par SMS pour confirmer le paiement.'
                    : 'Entrez le code PIN de votre carte pour confirmer le paiement.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Retour à l'écran de paiement
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                cubit.submitCardAuthorization(controller.text.trim());
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocListener<BookingCubit, BookingFlowState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == BookingStatus.succeeded) {
          _pollTimer?.cancel();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => BookingConfirmationScreen(booking: widget.booking, paymentConfirmed: true),
            ),
            (route) => route.isFirst,
          );
        } else if (state.status == BookingStatus.awaitingPayment) {
          // Échec définitif (FAILED) : retour à l'écran de paiement, qui
          // affichera errorMessage.
          _pollTimer?.cancel();
          Navigator.pop(context);
        } else {
          _reactToState(state);
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: BlocBuilder<BookingCubit, BookingFlowState>(
              builder: (context, state) {
                final isRedirect = state.paymentResult?.authorizationType == 'REDIRECT';
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isRedirect ? 'Finalisez l\'authentification dans votre navigateur' : 'Confirmation en cours',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isRedirect
                              ? 'Revenez sur l\'application une fois l\'authentification terminée.'
                              : 'Un code de confirmation a été envoyé sur votre téléphone (USSD). Composez-le pour valider le paiement.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler et revenir'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
