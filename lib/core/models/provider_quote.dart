// ignore_for_file: constant_identifier_names
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Reflète com.guentours.provider.ProviderType — partagé par toutes les
/// verticales (vols, hôtels, véhicules, meublés). Membres en SCREAMING_CASE
/// délibérément : ils reproduisent les valeurs exactes envoyées par le
/// backend (voir ProviderType.fromString) et sont affichés tels quels
/// (voir quote_price_section.dart) — ne pas renommer en lowerCamelCase.
enum ProviderType {
  TRAVELOPRO,
  SABRE,
  TRAVELPORT,
  DIRECT,
  UNKNOWN;

  static ProviderType fromString(String value) {
    return ProviderType.values.firstWhere(
          (e) => e.name == value.toUpperCase(),
      orElse: () => ProviderType.UNKNOWN,
    );
  }
}

/// Reflète com.guentours.shared.Money — partagé par toutes les verticales.
/// Le backend sérialise `amount` comme un nombre à 2 décimales, mais on
/// parse défensivement en `num`/`String` (voir Next.js: `Number(amount)`).
class Money extends Equatable {
  final double amount;
  final String currency;

  const Money({required this.amount, required this.currency});

  factory Money.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return Money(
      amount: rawAmount is String ? double.tryParse(rawAmount) ?? 0.0 : (rawAmount as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'XAF',
    );
  }

  /// Formatage devise localisé, équivalent de `formatMoney()` côté Next.js.
  String format({String locale = 'fr_FR'}) {
    try {
      return NumberFormat.simpleCurrency(locale: locale, name: currency).format(amount);
    } catch (_) {
      return '${amount.toStringAsFixed(0)} $currency';
    }
  }

  @override
  String toString() => '${amount.toStringAsFixed(0)} $currency';

  @override
  List<Object?> get props => [amount, currency];
}

/// Reflète com.guentours.search.domain.ProviderQuote — le prix d'un
/// fournisseur pour une offre harmonisée donnée ; `offerId` sert à
/// résoudre l'offre exacte au checkout.
class ProviderQuote extends Equatable {
  final String offerId;
  final ProviderType providerType;
  final Money price;

  const ProviderQuote({
    required this.offerId,
    required this.providerType,
    required this.price,
  });

  factory ProviderQuote.fromJson(Map<String, dynamic> json) {
    return ProviderQuote(
      offerId: json['offerId'] as String? ?? '',
      providerType: ProviderType.fromString(json['providerType'] as String? ?? ''),
      price: Money.fromJson(json['price'] as Map<String, dynamic>? ?? const {}),
    );
  }

  @override
  List<Object?> get props => [offerId, providerType, price];
}

/// Trie les quotes par prix croissant et renvoie la moins chère en premier,
/// comme le fait systématiquement le frontend Next.js sur chaque carte de résultat.
List<ProviderQuote> sortedByPrice(List<ProviderQuote> quotes) {
  final sorted = List<ProviderQuote>.of(quotes);
  sorted.sort((a, b) => a.price.amount.compareTo(b.price.amount));
  return sorted;
}
