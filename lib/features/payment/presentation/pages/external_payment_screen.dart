import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/web_config.dart';
import '../../../../core/models/booking_response.dart';

/// Écran de relais pour un paiement Carte / Google Pay / Apple Pay / PayPal.
///
/// Le backend route ces méthodes vers Stripe par défaut
/// (StripePaymentGateway, ui_mode=embedded_page) et ne renvoie qu'un
/// client_secret de Checkout *Session* - un objet Stripe différent d'un
/// PaymentIntent, et incompatible avec le PaymentSheet natif de
/// flutter_stripe (qui n'existe de toute façon que sur Android/iOS/Web, pas
/// desktop). Plutôt que de réinventer Stripe côté Dart, on renvoie le payeur
/// vers la page de paiement Next.js déjà correcte (PaymentForm +
/// StripeCheckoutDialog, qui monte l'Embedded Checkout de Stripe), puis on
/// sonde la réservation jusqu'à ce qu'elle passe CONFIRMED/PAID ou
/// FAILED/CANCELLED - la confirmation réelle vient du webhook Stripe côté
/// serveur (StripeWebhookController), pas de cet écran.
///
/// Réutilisé tel quel par le checkout vol et le checkout générique
/// (hôtel/véhicule/meublé) : [fetchBooking] découple l'écran du client API
/// concret (FlightApiClient vs BookingApiClient) à utiliser pour sonder.
class ExternalPaymentScreen extends StatefulWidget {
  final String bookingId;
  final Future<BookingResponse> Function(String bookingId) fetchBooking;
  final VoidCallback onConfirmed;

  const ExternalPaymentScreen({
    super.key,
    required this.bookingId,
    required this.fetchBooking,
    required this.onConfirmed,
  });

  @override
  State<ExternalPaymentScreen> createState() => _ExternalPaymentScreenState();
}

class _ExternalPaymentScreenState extends State<ExternalPaymentScreen> {
  static const _resolvedStatuses = {'CONFIRMED', 'PAID'};
  static const _failedStatuses = {'FAILED', 'CANCELLED'};

  Timer? _pollTimer;
  bool _launched = false;
  bool _polling = false;
  String? _error;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openWebCheckout() async {
    final locale = Localizations.localeOf(context).languageCode;
    final uri = Uri.parse('${WebConfig.baseUrl}/$locale/payment/${widget.bookingId}');

    setState(() => _error = null);

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!opened) {
      setState(() => _error = "Impossible d'ouvrir le navigateur. Réessayez.");
      return;
    }
    setState(() => _launched = true);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    setState(() => _polling = true);
    _checkStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    try {
      final booking = await widget.fetchBooking(widget.bookingId);
      if (!mounted) return;
      if (_resolvedStatuses.contains(booking.status)) {
        _pollTimer?.cancel();
        widget.onConfirmed();
      } else if (_failedStatuses.contains(booking.status)) {
        _pollTimer?.cancel();
        setState(() {
          _polling = false;
          _error = "Le paiement n'a pas abouti. Vous pouvez réessayer.";
        });
      }
    } catch (_) {
      // Un tick de polling raté n'est pas une erreur à afficher - le
      // prochain réessaiera (même logique que PaymentStatusRefreshRequested).
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) => _pollTimer?.cancel(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Paiement sécurisé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
            onPressed: () {
              _pollTimer?.cancel();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: Icon(Icons.lock_outline_rounded, size: 40, color: primaryColor),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Paiement sécurisé par Stripe',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  _launched
                      ? "Terminez votre paiement dans l'onglet qui vient de s'ouvrir. "
                          "Cette page se met à jour automatiquement une fois le paiement confirmé."
                      : "Vous allez être redirigé vers notre page de paiement sécurisée : vos "
                          "informations de carte (ou Google Pay / Apple Pay / PayPal) sont saisies "
                          "directement chez notre partenaire Stripe, jamais dans l'application.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_rounded, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Chiffrement de niveau bancaire',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_polling) ...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text('En attente de la confirmation du paiement…', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 20),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _openWebCheckout,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(_launched ? 'Rouvrir la page de paiement' : 'Continuer vers le paiement sécurisé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                if (_launched) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _checkStatus,
                    child: const Text("J'ai terminé le paiement — vérifier maintenant"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
