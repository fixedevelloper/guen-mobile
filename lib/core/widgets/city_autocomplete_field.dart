import 'dart:async';
import 'package:flutter/material.dart';
import '../network/geo_api_client.dart';

/// Champ ville avec autocomplétion sur `/api/geo/cities`, débounce 300ms et
/// seuil de 2 caractères — même comportement que `LocationAutocomplete` /
/// `PickLocationAutocomplete` côté frontend Next.js.
///
/// Implémenté en liste inline (pas via `RawAutocomplete`) : ce widget calcule
/// ses options de façon asynchrone (appel réseau), et `RawAutocomplete` ne
/// réinvoque `optionsBuilder` que sur les changements de son propre
/// `TextEditingController`/`FocusNode` — un `setState` déclenché après coup
/// par le debounce ne le fait PAS réafficher les résultats. Une liste
/// affichée directement dans notre propre `build()` réagit immédiatement à
/// `setState`, sans dépendre de ce mécanisme interne.
class CityAutocompleteField extends StatefulWidget {
  final GeoApiClient geoApiClient;
  final String label;
  final IconData icon;
  final String? initialValue;
  final ValueChanged<String> onCitySelected;

  const CityAutocompleteField({
    super.key,
    required this.geoApiClient,
    required this.label,
    required this.icon,
    required this.onCitySelected,
    this.initialValue,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  List<CityOption> _options = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Laisse le temps au tap sur une suggestion de se déclencher avant de
      // masquer la liste (onTap d'un ListTile arrive après la perte de focus).
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) setState(() => _options = const []);
      });
    }
  }

  void _onTextChanged(String query) {
    widget.onCitySelected(query);
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _options = const [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await widget.geoApiClient.searchCities(query);
      if (!mounted || query != _controller.text) return;
      setState(() {
        _options = results;
        _isLoading = false;
      });
    });
  }

  void _selectOption(CityOption option) {
    _controller.text = option.title;
    widget.onCitySelected(option.code);
    setState(() => _options = const []);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(widget.icon, color: Colors.grey.shade400, size: 20),
            suffixIcon: _isLoading
                ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Champ requis' : null,
        ),
        if (_options.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final option = _options[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_city_rounded, size: 20),
                  title: Text(option.title),
                  subtitle: option.subtitle.isNotEmpty ? Text(option.subtitle) : null,
                  onTap: () => _selectOption(option),
                );
              },
            ),
          ),
      ],
    );
  }
}
