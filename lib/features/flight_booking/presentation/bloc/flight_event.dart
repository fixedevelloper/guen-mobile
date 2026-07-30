abstract class FlightEvent { const FlightEvent(); }
class SearchFlightsEvent extends FlightEvent {
  final String from; final String to; final String date;
  const SearchFlightsEvent({required this.from, required this.to, required this.date});
}
