import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/main.dart';
import 'package:khinrip/settings_language.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

String homeDirectory() {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
      return Platform.environment['HOME']!;
    case 'windows':
      return Platform.environment['USERPROFILE']!;
    case 'android':
      return '/storage/emulated/0/';
    case 'ios':
      return "";
    case 'fuchsia':
      return "/";
    default:
      return "/";
  }
}

Future<void> saveSettings() async {
  final prefs = await SharedPreferences.getInstance();

  prefs.setBool("fav_home", favoriteHome);
  prefs.setInt("app_theme", appTheme);
  prefs.setInt("track_behavior", trackListBehavior);
  prefs.setInt("popup_style", popupStyle);
  prefs.setBool("material_3", md3);
  prefs.setBool("window_border", windowBorder);
  // prefs.setBool("analytics", analytics);
}

class _SettingsPageState extends State<SettingsPage> {
  var folderToSave = "Default: Path of executable";

  void saveLocation() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("location", pathToSaveIn);
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    var defaultText = t
        .defaultLocation("Path of executable"); //"Default: Path of executable";
    folderToSave = defaultText;

    if (pathToSaveIn == "") {
      folderToSave = defaultText;
    } else {
      if (Platform.isAndroid &&
          pathToSaveIn == "/storage/emulated/0/Download") {
        folderToSave = t.defaultLocation("Downloads");
      } else {
        folderToSave = pathToSaveIn;
      }
    }

    var sectionColor = Colors.white10; //Theme.of(context).cardColor;
    if (appTheme == 3) {
      sectionColor = Colors.white10;
    }

    var themes = ["System", "Light", "Dark", "Black"];
    var trackListBehaviorStrings = [
      "Preview",
      "Browser",
      "Download"
    ];
    var popupBehaviorStrings = [
      "Auto",
      "Pop-up",
      "Bottom"
    ];

    var trackListSelect = trackListBehavior;
    var colorDownloadButton = Theme.of(context).hintColor;

    GlobalKey _dropdownTheme = GlobalKey();
    GlobalKey _dropdownTracklist = GlobalKey();
    GlobalKey _dropdownPopUp = GlobalKey();

    if ((Platform.isAndroid || Platform.isIOS) && maxDownloads == 1) {
      colorDownloadButton = Colors.green;
    } else if (maxDownloads >= 6) {
      colorDownloadButton = Colors.red;
    }

    if (!(Platform.isMacOS || Platform.isIOS || Platform.isAndroid) &&
        trackListSelect == 0) {
      trackListSelect = 1;
    }

    void openDropdown(GlobalKey toOpen) {
      toOpen.currentContext?.visitChildElements((element) {
        if (element.widget is Semantics) {
          element.visitChildElements((element) {
            if (element.widget is Actions) {
              element.visitChildElements((element) {
                Actions.invoke(element, const ActivateIntent());
              });
            }
          });
        }
      });
    }

    double splashRadius = 35.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
        windowBorder) {
      splashRadius = 1.0;
    }

    String titleAppBar = t.settingsView;
    double? heightTitleBar = 40.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
        !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    AppBar? settingsAppBar = AppBar(
        title: Text(t.settingsView),
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
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
        windowBorder) {
      settingsAppBar = null;
    } else if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
        !windowBorder) {
      widthOfBorder = 0.0;
    }

    var config = File('assets/languages.json');
    var str = config.readAsStringSync();
    var data = json.decode(str);

    var langaugeCurrent = data[context.findAncestorWidgetOfExactType<MaterialApp>()!.locale!.languageCode + "_flag"];
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
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 5, 0, 0),
                                      child: Text(
                                        titleAppBar,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline6,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ))),
                          const WindowButtons()
                        ]))),
              if ((Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux) &&
                  !windowBorder &&
                  settingsAppBar != null)
                settingsAppBar,
              Expanded(
                child: SettingsList(
                  platform: devicePlat,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  darkTheme: SettingsThemeData(
                      settingsListBackground: Theme.of(context).cardColor,
                      settingsSectionBackground: sectionColor,
                      titleTextColor:
                          Theme.of(context).textTheme.bodyText1!.color!),
                  //platform: DevicePlatform.android,
                  sections: [
                    if (!Platform.isIOS)
                      SettingsSection(
                        title: Text(t.savingPath),
                        tiles: <SettingsTile>[
                          SettingsTile.navigation(
                            title: Text(t.path),
                            value: Text(folderToSave),
                            onPressed: (context) async {
                              if (Platform.isAndroid) {
                                var status = await Permission.storage.status;
                                if (!status.isGranted) {
                                  await Permission.storage.request();
                                }
                              }
                              String? path = await FilePicker.platform
                                  .getDirectoryPath(
                                      dialogTitle: t.filePickerChoose,
                                      initialDirectory:
                                          Directory(homeDirectory()).path);

                              if (path != null) {
                                setState(() {
                                  pathToSaveIn = path;
                                  saveLocation();
                                  folderToSave = path;
                                });
                              }
                            },
                          ),
                          if (!Platform.isIOS && pathToSaveIn != "")
                            SettingsTile.navigation(
                              trailing: Container(),
                              title: Text(t.resetPath),
                              onPressed: (context) {
                                setState(() {
                                  pathToSaveIn = "";
                                  saveLocation();
                                  folderToSave = defaultText;
                                });
                              },
                            )
                        ],
                      ),
                    SettingsSection(
                      title: Text(t.appearance),
                      tiles: <SettingsTile>[
                        SettingsTile.navigation(
                          title: Text(t.languageOption),
                          trailing: Text(langaugeCurrent),
                          onPressed: (context) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LanguageSettings()));
                          },
                        ),
                        if (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux)
                          SettingsTile.switchTile(
                            title: Text(t.customWindow),
                            initialValue: windowBorder,
                            onToggle: (value) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              //debugPrint(value.toString());
                              setState(() {
                                windowBorder = value;
                                saveSettings();
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(t.relaunchNotice),
                                action: SnackBarAction(
                                    //textColor: Colors.white,
                                    label: t.exit,
                                    onPressed: () {
                                      exit(0);
                                    }),
                              ));
                            },
                          ),
                        SettingsTile.switchTile(
                          title: Text(t.favHomePage),
                          description: Text(t.favHomePageDescription),
                          initialValue: favoriteHome,
                          onToggle: (value) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            //debugPrint(value.toString());
                            setState(() {
                              favoriteHome = value;
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
                          },
                        ),
                        SettingsTile.navigation(
                          trailing: DropdownButton<String>(
                              alignment: AlignmentDirectional.centerEnd,
                              key: _dropdownTheme,
                              icon: const Icon(Icons.chevron_right_outlined),
                              underline: Container(),
                              //iconSize: 0.0,
                              value: themes[appTheme],
                              onChanged: (value) {
                                switch (value) {
                                  case "System":
                                    setState(() {
                                      appTheme = 0;
                                      notifier.value = 0;
                                    });
                                    break;
                                  case "Light":
                                    setState(() {
                                      appTheme = 1;
                                      notifier.value = 1;
                                    });
                                    break;
                                  case "Dark":
                                    setState(() {
                                      appTheme = 2;
                                      notifier.value = 2;
                                    });
                                    break;
                                  case "Black":
                                    setState(() {
                                      appTheme = 3;
                                      notifier.value = 3;
                                    });
                                    break;
                                  default:
                                }
                                saveSettings();
                              },
                              items: [
                                DropdownMenuItem(
                                  child: Text(t.themeSystem,
                                      textAlign: TextAlign.center),
                                  value: "System",
                                ),
                                DropdownMenuItem(
                                  child: Text(t.themeLight,
                                      textAlign: TextAlign.center),
                                  value: "Light",
                                ),
                                DropdownMenuItem(
                                  child: Text(t.themeDark),
                                  value: "Dark",
                                ),
                                DropdownMenuItem(
                                    child: Text(t.themeBlack), value: "Black"),
                              ]),
                          title: Text(t.appTheme),
                          onPressed: (context) {
                            openDropdown(_dropdownTheme);
                          },
                        ),
                        SettingsTile.switchTile(
                            initialValue: md3,
                            onToggle: (value) {
                              setState(() {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                md3 = value;
                                saveSettings();
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(t.relaunchNotice),
                                action: SnackBarAction(
                                    //textColor: Colors.white,
                                    label: t.restart,
                                    onPressed: () {
                                      Phoenix.rebirth(context);
                                    }),
                              ));
                            },
                            title: const Text("Material Design 3"))
                      ],
                    ),
                    SettingsSection(
                      title: Text(t.behavior),
                      tiles: [
                        /*if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
                          SettingsTile.switchTile(
                              initialValue: analytics,
                              onToggle: (value) {
                                setState(() {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  analytics = value;
                                  saveSettings();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: const Text('You have to relaunch the App for the changes to take effect.'),
                                  action: SnackBarAction(
                                      //textColor: Colors.white,
                                      label: 'Exit',
                                      onPressed: () {
                                        exit(0);
                                      }),
                                ));
                              },
                              title: const Text("Analytics"),
                              description: TextButton(
                                  onPressed: () {
                                    showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) => AlertDialog(
                                        title: const Text('Analytics'),
                                        content: const Text("Analytics collects ONLY the following data:\n"
                                            "•Crashes (including platform and OS)\n•When a song is downloaded (without the actual songname)\n"
                                            "No identifiable data (like device IDs, the Song you are trying to Download, etc) are collected.\n"
                                            "You can fully opt out. By unchecking, the Analytic component does not even get initialised."),
                                        actions: [
                                          TextButton(
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                              ),
                                              onPressed: () => Navigator.pop(context, null),
                                              child: const Text("OK")),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Text("Learn more"))),*/
                        SettingsTile.navigation(
                          title: Text(t.trackListTapBehavior),
                          description: Text(t.trackListTapBehaviorDescription),
                          trailing: DropdownButton<String>(
                              key: _dropdownTracklist,
                              alignment: AlignmentDirectional.centerEnd,
                              icon: const Icon(Icons.chevron_right_outlined),
                              underline: Container(),
                              value: trackListBehaviorStrings[trackListSelect],
                              onChanged: (value) {
                                debugPrint(value);
                                switch (value) {
                                  case "Preview":
                                    setState(() {
                                      trackListBehavior = 0;
                                    });
                                    break;
                                  case "Browser":
                                    setState(() {
                                      trackListBehavior = 1;
                                    });
                                    break;
                                  case "Download":
                                    setState(() {
                                      trackListBehavior = 2;
                                    });
                                    break;
                                  default:
                                    return;
                                }
                                saveSettings();
                              },
                              items: [
                                if (Platform.isIOS ||
                                    Platform.isMacOS ||
                                    Platform.isAndroid)
                                  DropdownMenuItem(
                                    child: Text(t.trackListPreview),
                                    value: "Preview",
                                  ),
                                DropdownMenuItem(
                                  child: Text(t.trackListBrowser),
                                  value: "Browser",
                                ),
                                DropdownMenuItem(
                                  child: Text(t.trackListDownload),
                                  value: "Download",
                                )
                              ]),
                          onPressed: (context) {
                            openDropdown(_dropdownTracklist);
                          },
                        ),
                        SettingsTile.navigation(
                          title: Text(t.popUps),
                          description: Text(t.popUpsDescription),
                          trailing: DropdownButton<String>(
                              key: _dropdownPopUp,
                              alignment: AlignmentDirectional.centerEnd,
                              icon: const Icon(Icons.chevron_right_outlined),
                              underline: Container(),
                              value: popupBehaviorStrings[popupStyle],
                              onChanged: (value) {
                                debugPrint(value);
                                switch (value) {
                                  case "Auto":
                                    setState(() {
                                      popupStyle = 0;
                                    });
                                    break;
                                  case "Pop-up":
                                    setState(() {
                                      popupStyle = 1;
                                    });
                                    break;
                                  case "Bottom":
                                    setState(() {
                                      popupStyle = 2;
                                    });
                                    break;
                                  default:
                                    return;
                                }
                                saveSettings();
                              },
                              items: [
                                DropdownMenuItem(
                                  child: Text(t.popupBehaviorAuto),
                                  value: "Auto",
                                ),
                                DropdownMenuItem(
                                  child: Text(t.popupBehaviorPopup),
                                  value: "Pop-up",
                                ),
                                DropdownMenuItem(
                                  child: Text(t.popupBehaviorBottom),
                                  value: "Bottom",
                                )
                              ]),
                          onPressed: (context) {
                            openDropdown(_dropdownPopUp);
                          },
                        ),
                        SettingsTile.navigation(
                          title: Text(t.concurrentDownloads),
                          description: Text(t.currentlyUnused),
                          value: Row(children: [
                            Text(maxDownloads.toString() + " - ",
                                style: TextStyle(color: colorDownloadButton)),
                            Text(
                              "Unused",
                              style: TextStyle(
                                  color: Theme.of(context).errorColor),
                            )
                          ]),
                          onPressed: (context) {
                            showDialog(
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                          builder: (context, setStateAlert) {
                                        return Dialog(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12.0)),
                                            child: SizedBox(
                                                width: (MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        4) *
                                                    3,
                                                height: 163,
                                                child: Column(
                                                  children: [
                                                    ListTile(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      title: Text(t
                                                          .concurrentDownloads),
                                                      subtitle: Text(t
                                                          .concurrentDownloadsDescription),
                                                    ),
                                                    Slider(
                                                        min: 1,
                                                        max: 10,
                                                        label: maxDownloads
                                                            .toString(),
                                                        divisions: 9,
                                                        value: maxDownloads
                                                            .toDouble(),
                                                        onChanged: (value) {
                                                          setStateAlert(() {
                                                            maxDownloads =
                                                                value.toInt();
                                                          });
                                                        })
                                                  ],
                                                )));
                                      });
                                    },
                                    context: context)
                                .then((value) => setState(
                                      () {},
                                    ));
                          },
                        )
                      ],
                    )
                  ],
                ),
              )
            ])));
  }
}
