import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/generated/app_localizations.dart';
import '../locale/locale_cubit.dart';

/// Dialogue de choix de langue (FR/EN), partagé entre l'écran Profil et
/// l'accueil. `LocaleCubit` est un singleton fourni à la racine de l'app
/// (voir main.dart) : accessible depuis n'importe quel écran sans wiring
/// supplémentaire.
void showLanguagePicker(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final localeCubit = context.read<LocaleCubit>();
  final currentCode = Localizations.localeOf(context).languageCode;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return SimpleDialog(
        title: Text(l10n.languagePickerTitle),
        children: [
          SimpleDialogOption(
            onPressed: () {
              localeCubit.setLocale(const Locale('fr'));
              Navigator.of(dialogContext).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.languageFrench),
                if (currentCode == 'fr') const Icon(Icons.check_rounded, size: 18),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              localeCubit.setLocale(const Locale('en'));
              Navigator.of(dialogContext).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.languageEnglish),
                if (currentCode == 'en') const Icon(Icons.check_rounded, size: 18),
              ],
            ),
          ),
        ],
      );
    },
  );
}
