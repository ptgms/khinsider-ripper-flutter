import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/settings_language.dart';
import 'package:khinrip/window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

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
  prefs.setBool("nextTrackPrev", nextTrackPrev);
  prefs.setInt("max_downloads", maxDownloads);
  // prefs.setBool("analytics", analytics);
}

class _SettingsPageState extends State<SettingsPage> {
  var folderToSave = "Default: Path of executable";

  void saveLocation() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("location", pathToSaveIn);
  }

  String languageCurrent = "";

  void _loadData() async {
    final loadedData = await rootBundle.loadString('assets/languages.json');
    var data = json.decode(loadedData);
    setState(() {
      languageCurrent = setLanguage == "system" ? "System" : data["${context.findAncestorWidgetOfExactType<MaterialApp>()!.locale!.languageCode}_flag"];
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
    var defaultText = t.defaultLocation("Path of executable"); //"Default: Path of executable";
    folderToSave = defaultText;

    if (pathToSaveIn == "") {
      folderToSave = defaultText;
    } else {
      if (Platform.isAndroid && pathToSaveIn == "/storage/emulated/0/Download") {
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
    var trackListBehaviorStrings = ["Preview", "Browser", "Download"];
    var popupBehaviorStrings = ["Auto", "Pop-up", "Bottom"];

    var trackListSelect = trackListBehavior;
    var colorDownloadButton = Theme.of(context).hintColor;

    GlobalKey dropdownTheme = GlobalKey();
    GlobalKey dropdownTracklist = GlobalKey();
    GlobalKey dropdownPopUp = GlobalKey();

    if ((Platform.isAndroid || Platform.isIOS) && maxDownloads == 1) {
      colorDownloadButton = Colors.green;
    } else if (maxDownloads >= 6) {
      colorDownloadButton = Colors.red;
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

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      splashRadius = 1.0;
    }

    String titleAppBar = t.settingsView;
    double? heightTitleBar = 40.0;
    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder) {
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

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      display = null;
    }
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      settingsAppBar = null;
    }

    //var config = File('assets/languages.json');

    //var str = config.readAsStringSync();

    var devicePlat = DevicePlatform.iOS;
    if (Platform.isAndroid) {
      devicePlat = DevicePlatform.android;
    }

    List<Widget> actionsWindow = [
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
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ))),
        ),
      )),
    ];

    Widget bodyDisplay = SettingsList(
      platform: devicePlat,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      darkTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).cardColor,
          settingsSectionBackground: sectionColor,
          titleTextColor: Theme.of(context).textTheme.bodyLarge!.color!),
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
                  String? path = await FilePicker.platform.getDirectoryPath(dialogTitle: t.filePickerChoose, initialDirectory: Directory(homeDirectory()).path);

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
              value: Text(languageCurrent),
              onPressed: (context) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettings()));
              },
            ),
            if (Platform.isMacOS || Platform.isLinux || Platform.isWindows)
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                  key: dropdownTheme,
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
                      value: "System",
                      child: Text(t.themeSystem, textAlign: TextAlign.center),
                    ),
                    DropdownMenuItem(
                      value: "Light",
                      child: Text(t.themeLight, textAlign: TextAlign.center),
                    ),
                    DropdownMenuItem(
                      value: "Dark",
                      child: Text(t.themeDark),
                    ),
                    DropdownMenuItem(value: "Black", child: Text(t.themeBlack)),
                  ]),
              title: Text(t.appTheme),
              onPressed: (context) {
                openDropdown(dropdownTheme);
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
                title: const Text("Material Design 3"))
          ],
        ),
        SettingsSection(
          title: Text(t.behavior),
          tiles: [
            SettingsTile.navigation(
              title: Text(t.trackListTapBehavior),
              description: Text(t.trackListTapBehaviorDescription),
              trailing: DropdownButton<String>(
                  key: dropdownTracklist,
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
                    DropdownMenuItem(
                      value: "Preview",
                      child: Text(t.trackListPreview),
                    ),
                    DropdownMenuItem(
                      value: "Browser",
                      child: Text(t.trackListBrowser),
                    ),
                    DropdownMenuItem(
                      value: "Download",
                      child: Text(t.trackListDownload),
                    )
                  ]),
              onPressed: (context) {
                openDropdown(dropdownTracklist);
              },
            ),
            SettingsTile.switchTile(
                initialValue: nextTrackPrev,
                onToggle: (value) {
                  setState(() {
                    nextTrackPrev = value;
                    saveSettings();
                  });
                },
                title: Text(t.previewPanelBehavior),
                description: Text(t.previewPanelBehaviorDescription)),
            SettingsTile.navigation(
              title: Text(t.popUps),
              description: Text(t.popUpsDescription),
              trailing: DropdownButton<String>(
                  key: dropdownPopUp,
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
                      value: "Auto",
                      child: Text(t.popupBehaviorAuto),
                    ),
                    DropdownMenuItem(
                      value: "Pop-up",
                      child: Text(t.popupBehaviorPopup),
                    ),
                    DropdownMenuItem(
                      value: "Bottom",
                      child: Text(t.popupBehaviorBottom),
                    )
                  ]),
              onPressed: (context) {
                openDropdown(dropdownPopUp);
              },
            ),
            SettingsTile.navigation(
              title: Text(t.concurrentDownloads),
              value: Row(children: [
                Text(maxDownloads.toString(), style: TextStyle(color: colorDownloadButton)),
              ]),
              onPressed: (context) {
                showDialog(
                        builder: (BuildContext context) {
                          return StatefulBuilder(builder: (context, setStateAlert) {
                            return Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                child: SizedBox(
                                    width: (MediaQuery.of(context).size.width / 4) * 3,
                                    height: 163,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          contentPadding: const EdgeInsets.all(10),
                                          title: Text(t.concurrentDownloads),
                                          subtitle: Text(t.concurrentDownloadsDescription),
                                        ),
                                        Slider(
                                            min: 1,
                                            max: 10,
                                            label: maxDownloads.toString(),
                                            divisions: 9,
                                            value: maxDownloads.toDouble(),
                                            onChanged: (value) {
                                              setStateAlert(() {
                                                maxDownloads = value.toInt();
                                                saveSettings();
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
    );

    return MainWindow(
      appBar: settingsAppBar,
      display: display,
      actionsWindow: actionsWindow,
      title: t.settingsView,
      body: bodyDisplay,
      actions: const [],
    );
  }
}
