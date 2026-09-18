/// Reflète com.guentours.provider.RoomOffer — GET /api/search/hotels/get-rooms.
/// `netPrice` et `maxOccupancyPerRoom` sont parsés défensivement (le backend
/// peut renvoyer un nombre ou une chaîne selon le fournisseur amont).
class RoomOffer {
  final String? productId;
  final String? roomType;
  final String? description;
  final String? roomCode;
  final String? fareType;
  final String? rateBasisId;
  final String currency;
  final double netPrice;
  final String? boardType;
  final String? maxOccupancyPerRoom;
  final String? inventoryType;
  final String? cancellationPolicy;
  final List<String> roomImages;
  final List<String> facilities;

  const RoomOffer({
    this.productId,
    this.roomType,
    this.description,
    this.roomCode,
    this.fareType,
    this.rateBasisId,
    required this.currency,
    required this.netPrice,
    this.boardType,
    this.maxOccupancyPerRoom,
    this.inventoryType,
    this.cancellationPolicy,
    this.roomImages = const [],
    this.facilities = const [],
  });

  /// Identifiant stable pour l'UI : productId sinon roomCode (le backend a le même repli).
  String get key => (productId != null && productId!.isNotEmpty) ? productId! : (roomCode ?? '');

  /// Occupation max entière, gère le format multi-chambres "2|t|2" du backend.
  int? get parsedMaxOccupancy {
    final raw = maxOccupancyPerRoom;
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(RegExp(r'\|t\|')).map((p) => int.tryParse(p.trim())).whereType<int>();
    return parts.isEmpty ? null : parts.reduce((a, b) => a > b ? a : b);
  }

  factory RoomOffer.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['netPrice'];
    return RoomOffer(
      productId: json['productId'] as String?,
      roomType: json['roomType'] as String?,
      description: json['description'] as String?,
      roomCode: json['roomCode'] as String?,
      fareType: json['fareType'] as String?,
      rateBasisId: json['rateBasisId'] as String?,
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'XAF',
      netPrice: rawPrice is String ? double.tryParse(rawPrice) ?? 0.0 : (rawPrice as num?)?.toDouble() ?? 0.0,
      boardType: json['boardType'] as String?,
      maxOccupancyPerRoom: json['maxOccupancyPerRoom']?.toString(),
      inventoryType: json['inventoryType'] as String?,
      cancellationPolicy: json['cancellationPolicy'] as String?,
      roomImages: (json['roomImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      facilities: (json['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
