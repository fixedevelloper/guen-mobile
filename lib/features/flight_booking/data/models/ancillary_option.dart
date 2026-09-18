// ignore_for_file: constant_identifier_names
import 'package:equatable/equatable.dart';
import '../../../../core/models/provider_quote.dart';

/// Reflète com.guentours.provider.AncillaryType. INSURANCE est une ligne propre à
/// GuenTours (jamais envoyée à un fournisseur) ; BAGGAGE/MEAL/SEAT viennent de
/// l'API "ancillaries" du fournisseur. Membres en SCREAMING_CASE délibérément :
/// ils reproduisent les valeurs exactes envoyées par le backend (voir
/// AncillaryType.fromString) — ne pas renommer en lowerCamelCase.
enum AncillaryType {
  BAGGAGE,
  MEAL,
  SEAT,
  INSURANCE,
  UNKNOWN;

  static AncillaryType fromString(String? value) {
    return AncillaryType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AncillaryType.UNKNOWN,
    );
  }
}

/// Reflète com.guentours.provider.SeatLayout — placement/attributs dans la
/// grille cabine d'un siège, présent uniquement quand type == SEAT.
/// totalRows/totalColumns/seatGroups/cabinClass décrivent la grille entière du
/// segment et sont répétés à l'identique sur chaque siège de ce segment.
class SeatLayout extends Equatable {
  final String row;
  final String column;
  final String status;
  final bool exitRow;
  final bool accessible;
  final bool bassinet;
  final bool toilet;
  final bool galley;
  final int totalRows;
  final int totalColumns;
  final List<String> seatGroups;
  final String? cabinClass;

  const SeatLayout({
    required this.row,
    required this.column,
    required this.status,
    this.exitRow = false,
    this.accessible = false,
    this.bassinet = false,
    this.toilet = false,
    this.galley = false,
    this.totalRows = 0,
    this.totalColumns = 0,
    this.seatGroups = const [],
    this.cabinClass,
  });

  factory SeatLayout.fromJson(Map<String, dynamic> json) {
    return SeatLayout(
      row: json['row'] as String? ?? '',
      column: json['column'] as String? ?? '',
      status: json['status'] as String? ?? '',
      exitRow: json['exitRow'] as bool? ?? false,
      accessible: json['accessible'] as bool? ?? false,
      bassinet: json['bassinet'] as bool? ?? false,
      toilet: json['toilet'] as bool? ?? false,
      galley: json['galley'] as bool? ?? false,
      totalRows: json['totalRows'] as int? ?? 0,
      totalColumns: json['totalColumns'] as int? ?? 0,
      seatGroups: List<String>.from(json['seatGroups'] ?? const []),
      cabinClass: json['cabinClass'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        row,
        column,
        status,
        exitRow,
        accessible,
        bassinet,
        toilet,
        galley,
        totalRows,
        totalColumns,
        seatGroups,
        cabinClass,
      ];
}

/// Reflète com.guentours.booking.web.AncillaryOptionResponse. `id` est la clé de
/// cache (OfferCache) à renvoyer dans TravelerRequest.selectedAncillaryIds pour
/// choisir cet extra au checkout - jamais le jeton fournisseur brut, qui reste
/// côté serveur.
class AncillaryOption extends Equatable {
  final String id;
  final AncillaryType type;
  final String? segmentId;
  final String? code;
  final String label;
  final Money price;

  /// "T1".."Tn" pour un extra lié à un voyageur précis ; null pour un extra au
  /// niveau de la réservation entière (ex: INSURANCE).
  final String? paxRef;

  /// Non-null uniquement quand type == SEAT.
  final SeatLayout? seatLayout;

  const AncillaryOption({
    required this.id,
    required this.type,
    this.segmentId,
    this.code,
    required this.label,
    required this.price,
    this.paxRef,
    this.seatLayout,
  });

  factory AncillaryOption.fromJson(Map<String, dynamic> json) {
    return AncillaryOption(
      id: json['id'] as String? ?? '',
      type: AncillaryType.fromString(json['type'] as String?),
      segmentId: json['segmentId'] as String?,
      code: json['code'] as String?,
      label: json['label'] as String? ?? '',
      price: Money.fromJson(json['price'] as Map<String, dynamic>? ?? const {}),
      paxRef: json['paxRef'] as String?,
      seatLayout: json['seatLayout'] != null
          ? SeatLayout.fromJson(json['seatLayout'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, type, segmentId, code, label, price, paxRef, seatLayout];
}
