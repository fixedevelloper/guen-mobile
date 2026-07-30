import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guentravel/features/flight_booking/presentation/pages/passenger_info_screen.dart';
import '../bloc/flight_booking_bloc.dart';
import '../bloc/flight_booking_event.dart';
import '../bloc/flight_booking_state.dart';
import '../../data/models/seat_map_response.dart';

class FlightSeatScreen extends StatefulWidget {
  const FlightSeatScreen({super.key});

  @override
  State<FlightSeatScreen> createState() => _FlightSeatScreenState();
}

class _FlightSeatScreenState extends State<FlightSeatScreen> {
  final List<String> _selectedSeats = [];

  int get _requiredSeats => context.read<FlightBookingBloc>().state.passengerTypes.length;

  void _toggleSeatSelection(String seatNumber) {
    setState(() {
      if (_selectedSeats.contains(seatNumber)) {
        _selectedSeats.remove(seatNumber);
      } else if (_selectedSeats.length < _requiredSeats) {
        _selectedSeats.add(seatNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Choix des sièges', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<FlightBookingBloc, FlightBookingState>(
        builder: (context, state) {
          final seatMap = state.seatMap;
          if (seatMap == null) return const Center(child: CircularProgressIndicator());

          return Column(
            children: [
              _buildHeaderStatus(),
              _buildLegendRow(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPlaneNose(),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          children: List.generate(seatMap.rows, (rowIndex) {
                            final rowNum = rowIndex + 1;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 30, child: Text('$rowNum', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                ...List.generate(seatMap.columns.length, (colIndex) {
                                  // Ajouter un espacement pour le couloir central
                                  if (colIndex == seatMap.columns.length ~/ 2) const SizedBox(width: 20);

                                  final seatNo = '$rowNum${seatMap.columns[colIndex]}';
                                  final seat = seatMap.seats.firstWhere((s) => s.seatNumber == seatNo, orElse: () => Seat(seatNumber: seatNo, available: false));
                                  return _buildSeat(seat);
                                }),
                              ],
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildFooter(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaneNose() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      width: 100, height: 40,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: const BorderRadius.vertical(top: Radius.circular(50))),
      child: const Icon(Icons.flight_takeoff, color: Colors.white),
    );
  }

  Widget _buildSeat(Seat seat) {
    final isSelected = _selectedSeats.contains(seat.seatNumber);
    return GestureDetector(
      onTap: seat.available ? () => _toggleSeatSelection(seat.seatNumber) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        width: 35, height: 35,
        decoration: BoxDecoration(
          color: !seat.available ? Colors.grey.shade300 : (isSelected ? Colors.orangeAccent : Colors.blue.shade50),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.orange, width: 2) : Border.all(color: Colors.blue.shade100),
        ),
        child: Center(child: Text(seat.seatNumber.substring(seat.seatNumber.length-1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.blue.shade900))),
      ),
    );
  }

  Widget _buildHeaderStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text('${_selectedSeats.length} / $_requiredSeats sièges sélectionnés', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildLegendRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.blue.shade50, "Libre"),
          const SizedBox(width: 15),
          _legendItem(Colors.orangeAccent, "Choisi"),
          const SizedBox(width: 15),
          _legendItem(Colors.grey.shade300, "Occupé"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 11))]);
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: _selectedSeats.length == _requiredSeats ? () {
          context.read<FlightBookingBloc>().add(SeatsConfirmed(_selectedSeats));
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PassengerInfoScreen()));
        } : null,
        child: const Text("CONFIRMER LA SÉLECTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }
}