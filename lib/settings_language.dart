import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/main.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSettings extends StatefulWidget {
  const LanguageSettings({Key? key}) : super(key: key);

  @override
  State<LanguageSettings> createState() => _LanguageSettingsState();
}

class _LanguageSettingsState extends State<LanguageSettings> {
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("language", setLanguage);
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    double splashRadius = 35.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      splashRadius = 1.0;
    }

    String titleAppBar = t.languageOption;
    double? heightTitleBar = 40.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    AppBar? settingsAppBar = AppBar(
        title: Text(t.languageOption),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            Navigator.pop(context);
          },
        ));
    AppBar? display = settingsAppBar;

    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      display = null;
    }
    double? widthOfBorder;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      settingsAppBar = null;
    } else if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      widthOfBorder = 0.0;
    }

    var sectionColor = Colors.white10; //Theme.of(context).cardColor;
    if (appTheme == 3) {
      sectionColor = Colors.white10;
    }

    var languages = context.findAncestorWidgetOfExactType<MaterialApp>()?.supportedLocales;
    List<SettingsTile> sectionsLanguages = [];
    Widget selectedMark = Container();
    String defaultLocale = Platform.localeName.split("_")[0];
    if (setLanguage == "system") {
      selectedMark = const Icon(Icons.check);
    }

    if (!["en", "de", "pl", "nl", "ar"].contains(defaultLocale)) {
      defaultLocale = "en";
    }

    var config = File('assets/languages.json');
    var str = config.readAsStringSync();
    var data = json.decode(str);

    var systemLanguage = SettingsTile.navigation(
        title: Text(t.themeSystem),
        leading: Text(data[defaultLocale + "_flag"]),
        trailing: selectedMark,
        onPressed: (value) {
          setState(() {
            setLanguage = "system";
            saveSettings();
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(t.relaunchNotice),
            action: SnackBarAction(
                //textColor: Colors.white,
                label: t.restart,
                onPressed: () {
                  Phoenix.rebirth(context);
                }),
          ));
        });
    for (var item in languages!) {
      var selected = item.languageCode == setLanguage;
      Widget selectedMark = Container();
      if (selected) {
        selectedMark = const Icon(Icons.check);
      }
      sectionsLanguages.add(SettingsTile.navigation(
          title: Text(data[item.languageCode]),
          leading: Text(data[item.languageCode + "_flag"]),
          trailing: selectedMark,
          onPressed: (value) {
            setState(() {
              setLanguage = item.languageCode;
              saveSettings();
            });

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(t.relaunchNotice),
              action: SnackBarAction(
                  //textColor: Colors.white,
                  label: t.restart,
                  onPressed: () {
                    Phoenix.rebirth(context);
                  }),
            ));
          }));
    }

    var devicePlat = DevicePlatform.iOS;
    if (Platform.isAndroid) {
      devicePlat = DevicePlatform.android;
    }

    return Scaffold(
        appBar: display,
        body: WindowBorder(
            width: widthOfBorder,
            color: Theme.of(context).backgroundColor,
            child: Column(children: [
              if ((Platform.isLinux || Platform.isMacOS || Platform.isWindows))
                SizedBox(
                    child: Container(
                        color: Theme.of(context).cardColor,
                        child: Row(children: [
                          if (Platform.isMacOS) const SizedBox(width: 60),
                          if (windowBorder)
                            IconButton(
                                splashRadius: splashRadius,
                                icon: const Icon(Icons.navigate_before),
                                onPressed: () {
                                  Navigator.pop(context);
                                }),
                          Expanded(
                              child: SizedBox(
                                  height: heightTitleBar,
                                  child: MoveWindow(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
                                      child: Text(
                                        titleAppBar,
                                        style: Theme.of(context).textTheme.headline6,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ))),
                          const WindowButtons()
                        ]))),
              if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
                  !windowBorder &&
                  settingsAppBar != null)
                settingsAppBar,
              Expanded(
                  child: SettingsList(
                      platform: devicePlat,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      darkTheme: SettingsThemeData(
                          settingsListBackground: Theme.of(context).cardColor,
                          settingsSectionBackground: sectionColor,
                          titleTextColor: Theme.of(context).textTheme.bodyText1!.color!),
                      //platform: DevicePlatform.android,
                      sections: [
                        if (!Platform.isIOS && !Platform.isMacOS) SettingsSection(tiles: [systemLanguage]), 
                        SettingsSection(tiles: sectionsLanguages)]))
            ])));
  }
}
