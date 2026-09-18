import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale';

/// Langue de l'app (FR/EN), persistée entre deux lancements. `null` tant que
/// la préférence sauvegardée n'a pas encore été lue au démarrage — le
/// MaterialApp doit alors suivre la langue du système via `supportedLocales`.
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) emit(Locale(code));
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
