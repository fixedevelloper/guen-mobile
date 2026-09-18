import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/models/booking_response.dart';
import '../../../booking/presentation/pages/booking_confirmation_screen.dart';
import '../cubit/my_bookings_cubit.dart';
import '../cubit/my_bookings_state.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyBookingsCubit>()..load(),
      child: const _MyBookingsView(),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Mes réservations', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<MyBookingsCubit, MyBookingsState>(
        builder: (context, state) {
          if (state.status == MyBookingsStatus.loading || state.status == MyBookingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MyBookingsStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(state.errorMessage ?? 'Erreur inconnue.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<MyBookingsCubit>().load(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book_online_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune réservation pour le moment',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vos vols, hôtels, véhicules et logements réservés apparaîtront ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<MyBookingsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _BookingCard(booking: state.bookings[index]),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingResponse booking;

  const _BookingCard({required this.booking});

  IconData get _icon {
    switch (booking.offerType) {
      case 'HOTEL':
        return Icons.hotel_rounded;
      case 'CAR_RENTAL':
        return Icons.directions_car_rounded;
      case 'FURNISHED_RENTAL':
        return Icons.villa_rounded;
      case 'FLIGHT':
      case 'MULTI_CITY':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String get _title {
    switch (booking.offerType) {
      case 'HOTEL':
        return booking.hotelName ?? 'Réservation hôtel';
      case 'CAR_RENTAL':
        final label = [booking.vehicleBrand, booking.vehicleModel].where((e) => e != null).join(' ');
        return label.isNotEmpty ? label : 'Location de véhicule';
      case 'FURNISHED_RENTAL':
        return booking.propertyTitle ?? 'Location meublée';
      default:
        if (booking.origin != null && booking.destination != null) {
          return '${booking.origin} → ${booking.destination}';
        }
        return 'Réservation vol';
    }
  }

  String? get _subtitle {
    final format = DateFormat('dd MMM yyyy', 'fr_FR');
    switch (booking.offerType) {
      case 'HOTEL':
        if (booking.checkIn == null || booking.checkOut == null) return null;
        return '${format.format(booking.checkIn!)} → ${format.format(booking.checkOut!)}';
      case 'CAR_RENTAL':
        if (booking.rentalStart == null) return null;
        return format.format(booking.rentalStart!);
      default:
        if (booking.departureTime == null) return null;
        return format.format(booking.departureTime!);
    }
  }

  Color _statusColor(BuildContext context) {
    switch (booking.status) {
      case 'CONFIRMED':
      case 'PAID':
        return Colors.green;
      case 'CONFIRMING':
      case 'DEPOSIT_PAID':
      case 'PENDING_PAYMENT':
      case 'PENDING_HOLD':
        return Colors.orange;
      case 'FAILED':
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (booking.status) {
      case 'CONFIRMED':
        return 'Confirmée';
      case 'PAID':
        return 'Payée';
      case 'CONFIRMING':
        return 'Confirmation en cours';
      case 'DEPOSIT_PAID':
        return 'Acompte versé';
      case 'PENDING_PAYMENT':
        return 'En attente de paiement';
      case 'PENDING_HOLD':
        return 'En cours';
      case 'FAILED':
        return 'Échec';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return booking.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final subtitle = _subtitle;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookingConfirmationScreen(booking: booking)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(_icon, color: primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(color: _statusColor(context), fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            if (booking.price != null)
              Text(
                booking.price!.format(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
