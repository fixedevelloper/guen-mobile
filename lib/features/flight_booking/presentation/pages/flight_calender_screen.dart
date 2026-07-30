import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightCalenderScreen extends StatefulWidget {
  const FlightCalenderScreen({super.key});

  @override
  State<FlightCalenderScreen> createState() => _FlightCalenderScreenState();
}

class _FlightCalenderScreenState extends State<FlightCalenderScreen> {
  DateTime? _selectedDate;
  final DateTime _currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary; // Bleu 15a4e6
    final secondaryColor = Theme.of(context).colorScheme.secondary; // Vert 7bcd4f

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Date de départ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Indicateurs de jours de la semaine (Lu, Ma, Me...)
          _buildWeekDaysHeader(),

          Divider(color: Colors.grey.shade100, height: 1),

          // Calendrier défilant (Juillet / Août 2026 d'après le storyboard actuel)
          Expanded(
            child: ListView.builder(
              itemCount: 12, // Affiche les 12 prochains mois
              itemBuilder: (context, index) {
                final monthDate = DateTime(_currentDate.year, _currentDate.month + index, 1);
                return _buildMonthCalendar(monthDate, primaryColor);
              },
            ),
          ),

          // Zone de validation basse
          _buildBottomActionSection(secondaryColor),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    final weekDays = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((day) => SizedBox(
          width: 40,
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMonthCalendar(DateTime monthDate, Color highlightColor) {
    final String monthName = DateFormat('MMMM yyyy', 'fr_FR').format(monthDate);
    final int daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final int firstDayOffset = DateTime(monthDate.year, monthDate.month, 1).weekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthName.substring(0, 1).toUpperCase() + monthName.substring(1),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox.shrink();

              final dayNumber = index - firstDayOffset + 1;
              final cellDate = DateTime(monthDate.year, monthDate.month, dayNumber);
              final isSelected = _selectedDate != null &&
                  DateUtils.isSameDay(_selectedDate!, cellDate);
              final isPast = cellDate.isBefore(DateTime(_currentDate.year, _currentDate.month, _currentDate.day));

              return GestureDetector(
                onTap: isPast ? null : () {
                  setState(() => _selectedDate = cellDate);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? highlightColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isPast ? Colors.grey.shade300 : Colors.black87),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionSection(Color actionColor) {
    final formattedDate = _selectedDate != null
        ? DateFormat('EEE, d MMM yyyy', 'fr_FR').format(_selectedDate!)
        : 'Sélectionnez une date';

    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 36, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date sélectionnée', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const SizedBox(height: 4),
              Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          ElevatedButton(
            onPressed: _selectedDate == null ? null : () {
              Navigator.pop(context, _selectedDate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}