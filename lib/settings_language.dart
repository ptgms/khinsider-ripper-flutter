import 'dart:convert';
import 'dart:io';

//import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/main.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

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

  List<AbstractSettingsSection> sectionsSettings = [];

  void _loadData() async {
    final _loadedData = await rootBundle.loadString('assets/languages.json');
    var languages = context.findAncestorWidgetOfExactType<MaterialApp>()?.supportedLocales;
    List<SettingsTile> sectionsLanguages = [];
    Widget selectedMark = Container();
    String defaultLocale = Platform.localeName.split("_")[0];
    if (setLanguage == "system") {
      selectedMark = const Icon(Icons.check);
    }

    if (!["en", "de", "pl", "nl", "ar", "fr", "es"].contains(defaultLocale)) {
      defaultLocale = "en";
    }
    Future.delayed(Duration.zero, () {
      var t = AppLocalizations.of(context)!;
      var data = json.decode(_loadedData);
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
        //debugPrint(data[item.languageCode + "_flag"]);
        List<Widget> credit = [];
        credit.add(Text(t.translatedBy("")));
        for (var contributer in data["credits"][item.languageCode]) {
          var finalCredit = data["credits"][item.languageCode].last;

          if (contributer["url"] == "") {
            credit.add(Text(contributer["name"]));
          } else {
            credit.add(InkWell(
                child: Text(
                  contributer["name"],
                  style: const TextStyle(color: Colors.blue),
                ),
                onTap: () {
                  launchUrl(Uri.parse(contributer["url"]));
                }));
          }

          if (finalCredit != contributer) {
            credit.add(const Text(", "));
          }
        }
        sectionsLanguages.add(SettingsTile.navigation(
            title: Text(data[item.languageCode]),
            description: Row(children: credit),
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
      setState(() {
        sectionsSettings = [
          SettingsSection(tiles: [systemLanguage]),
          SettingsSection(tiles: sectionsLanguages),
          SettingsSection(tiles: [
            SettingsTile.navigation(
              title: const Text("Crowdin"),
              onPressed: (value) => launchUrl(Uri.parse("https://crwd.in/khinsider-ripper-flutter")),
            )
          ], title: Text(t.helpTranslation))
        ];
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    double splashRadius = 35.0;

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      splashRadius = 1.0;
    }

    String titleAppBar = t.languageOption;
    double? heightTitleBar = 40.0;
    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder) {
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

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      display = null;
    }
    double? widthOfBorder;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      settingsAppBar = null;
    } else if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder) {
      widthOfBorder = 0.0;
    }

    var sectionColor = Colors.white10; //Theme.of(context).cardColor;
    if (appTheme == 3) {
      sectionColor = Colors.white10;
    }

    // [
    //if (!Platform.isIOS && !Platform.isMacOS) SettingsSection(tiles: [systemLanguage]),
    //SettingsSection(tiles: sectionsLanguages)]

    var devicePlat = DevicePlatform.iOS;
    if (Platform.isAndroid) {
      devicePlat = DevicePlatform.android;
    }

    return Scaffold(
        appBar: display,
        body: Container(
            //width: widthOfBorder,
            //color: Theme.of(context).backgroundColor,
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
                          child: GestureDetector(
                        onTapDown: (details) {
                          windowManager.startDragging();
                        },
                        onDoubleTap: () {
                          windowManager.isMaximized().then((value) {
                            if (value) {
                              windowManager.restore();
                            } else {
                              windowManager.maximize();
                            }
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: SizedBox(
                              height: heightTitleBar,
                              child: VirtualWindowFrame(
                                  child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
                                child: Text(
                                  titleAppBar,
                                  style: Theme.of(context).textTheme.headline6,
                                  textAlign: TextAlign.center,
                                ),
                              ))),
                        ),
                      )),
                      const WindowButtons()
                    ]))),
          if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder && settingsAppBar != null)
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
                  sections: sectionsSettings))
        ])));
  }
}
