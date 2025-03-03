import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:quacker/constants.dart';
import 'package:quacker/generated/l10n.dart';
import 'package:pref/pref.dart';
import 'package:quacker/utils/iterables.dart';

class SettingsThemeFragment extends StatelessWidget {
  const SettingsThemeFragment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BasePrefService prefs = PrefService.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.theme)),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(children: [
          PrefDropdown(fullWidth: false, title: Text(L10n.of(context).theme_mode), pref: optionThemeMode, items: [
            DropdownMenuItem(
              value: 'system',
              child: Text(L10n.of(context).system),
            ),
            DropdownMenuItem(
              value: 'light',
              child: Text(L10n.of(context).light),
            ),
            DropdownMenuItem(
              value: 'dark',
              child: Text(L10n.of(context).dark),
            ),
          ]),
          PrefDropdown(title: Text(L10n.of(context).theme), fullWidth: false, pref: optionThemeColor, items: [
            const DropdownMenuItem(value: 'accent', child: Text('Accent')),
            ...themeColors.entries.getRange(0, themeColors.values.length - 1).map(
                (scheme) => DropdownMenuItem(value: scheme.key, child: Text(toBeginningOfSentenceCase(scheme.key)!)))
          ]),
          PrefSwitch(
            title: Text(L10n.of(context).true_black),
            pref: optionThemeTrueBlack,
            subtitle: Text(
              L10n.of(context).use_true_black_for_the_dark_mode_theme,
            ),
          ),
          PrefSwitch(
            title: Text(L10n.of(context).true_black_tweet_cards),
            pref: optionThemeTrueBlackTweetCards,
            disabled: !prefs.get(optionThemeTrueBlack),
            subtitle: Text(
              L10n.of(context).use_true_black_for_tweet_cards,
            ),
          ),
          PrefSwitch(
            title: Text(L10n.of(context).show_navigation_labels),
            pref: optionShowNavigationLabels,
          ),
        ]),
      ),
    );
  }
}

class _createColorPickerDialog extends StatefulWidget {
  State<_createColorPickerDialog> createState() => _createColorPickerDialogState();
}

class _createColorPickerDialogState extends State<_createColorPickerDialog> {
  Widget build(BuildContext context) {
    var prefService = PrefService.of(context);

    Color? color = Color(0x0);
    if (prefService.get(optionThemeColor) != false) {
      color = Color(prefService.get(optionThemeColor));
    }
    var selectedColor = color;

    return PrefDialog(
      title: Text(L10n.of(context).pick_a_color),
      actions: <Widget>[
        TextButton(
          child: Text(L10n.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(L10n.of(context).ok),
          onPressed: () {
            setState(() {
              prefService.set(optionThemeColor, int.parse("0x${selectedColor.value}"));
            });
            Navigator.of(context).pop();
          },
        ),
      ],
      children: [
        SingleChildScrollView(
          child: MaterialPicker(
            pickerColor: color,
            onColorChanged: (value) => setState(() {
              selectedColor = value;
            }),
            enableLabel: true,
          ),
        )
      ],
    );
  }
}
