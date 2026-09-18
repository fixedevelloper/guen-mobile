import 'package:flutter/material.dart';
import '../models/provider_quote.dart';

/// Affiche la quote la moins chère en avant, puis les autres fournisseurs en
/// dessous — même présentation que les cartes de résultats du frontend
/// Next.js (hôtels, véhicules, meublés).
class QuotePriceSection extends StatelessWidget {
  final List<ProviderQuote> quotes;
  final String priceLabel;
  final Color highlightColor;
  final ValueChanged<ProviderQuote>? onQuoteSelected;

  const QuotePriceSection({
    super.key,
    required this.quotes,
    required this.highlightColor,
    this.priceLabel = 'Total',
    this.onQuoteSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (quotes.isEmpty) return const SizedBox.shrink();
    final sorted = sortedByPrice(quotes);
    final cheapest = sorted.first;
    final rest = sorted.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onQuoteSelected != null ? () => onQuoteSelected!(cheapest) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(priceLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(
                cheapest.price.format(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: highlightColor),
              ),
            ],
          ),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...rest.map((q) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: onQuoteSelected != null ? () => onQuoteSelected!(q) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(q.providerType.name, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  Text(q.price.format(), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }
}
