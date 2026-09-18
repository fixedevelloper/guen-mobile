import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/checkout_request_dto.dart';
import '../booking_offer_context.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'booking_payment_screen.dart';

class BookingContactScreen extends StatelessWidget {
  final BookingOfferContext offer;

  const BookingContactScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingCubit>(),
      child: _BookingContactView(offer: offer),
    );
  }
}

class _TravelerFormRow {
  final TextEditingController nameController = TextEditingController();

  void dispose() => nameController.dispose();
}

class _BookingContactView extends StatefulWidget {
  final BookingOfferContext offer;

  const _BookingContactView({required this.offer});

  @override
  State<_BookingContactView> createState() => _BookingContactViewState();
}

class _BookingContactViewState extends State<_BookingContactView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<_TravelerFormRow> _travelers = [_TravelerFormRow()];
  int _quantity = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    for (final t in _travelers) {
      t.dispose();
    }
    super.dispose();
  }

  void _addTraveler() => setState(() => _travelers.add(_TravelerFormRow()));

  void _removeTraveler(int index) {
    if (_travelers.length <= 1) return;
    setState(() {
      _travelers[index].dispose();
      _travelers.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final travelers = _travelers
        .map((t) => CheckoutTravelerDto(fullName: t.nameController.text.trim()))
        .toList();

    context.read<BookingCubit>().submitCheckout(CheckoutRequestDto(
      offerId: widget.offer.offerId,
      offerType: widget.offer.offerType,
      contactEmail: _emailController.text.trim(),
      contactFullName: _fullNameController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      travelers: travelers,
      quantity: widget.offer.isHotel ? _quantity : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return BlocListener<BookingCubit, BookingFlowState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == BookingStatus.awaitingPayment && state.booking != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BookingPaymentScreen(booking: state.booking!)),
          );
        } else if (state.status == BookingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Erreur'), backgroundColor: Colors.red.shade600),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Vos coordonnées', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    _buildOfferSummary(secondaryColor),
                    const SizedBox(height: 24),
                    const Text('Responsable de la réservation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _textField(_emailController, 'Email de contact', Icons.email_outlined, primaryColor,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null),
                    const SizedBox(height: 16),
                    _textField(_fullNameController, 'Nom complet', Icons.person_outline_rounded, primaryColor,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null),
                    const SizedBox(height: 16),
                    _textField(_phoneController, 'Téléphone', Icons.phone_android_outlined, primaryColor,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null),
                    if (widget.offer.isHotel) ...[
                      const SizedBox(height: 24),
                      _quantitySelector(primaryColor),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Voyageurs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        TextButton.icon(
                          onPressed: _addTraveler,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._travelers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final traveler = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _textField(
                                traveler.nameController,
                                'Voyageur ${index + 1}',
                                Icons.badge_outlined,
                                primaryColor,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                              ),
                            ),
                            if (_travelers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                                onPressed: () => _removeTraveler(index),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              _buildBottomAction(secondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferSummary(Color highlightColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.offer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(widget.offer.subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 12),
          Text(widget.offer.price.format(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: highlightColor)),
        ],
      ),
    );
  }

  Widget _quantitySelector(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Nombre de chambres', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(
      TextEditingController controller,
      String label,
      IconData icon,
      Color primaryColor, {
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildBottomAction(Color actionColor) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 32, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: BlocBuilder<BookingCubit, BookingFlowState>(
        builder: (context, state) {
          final isLoading = state.status == BookingStatus.checkingOut;
          return SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Continuer vers le paiement', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
