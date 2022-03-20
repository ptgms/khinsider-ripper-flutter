import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // I have no idea.
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
}

class _SettingsPageState extends State<SettingsPage> {
  var folderToSave = "Default: Path of executable";

  void saveLocation() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("location", pathToSaveIn);
  }

  @override
  Widget build(BuildContext context) {
    var defaultText = "Default: Path of executable";

    if (pathToSaveIn == "") {
      folderToSave = defaultText;
    } else {
      if (Platform.isAndroid && pathToSaveIn == "/storage/emulated/0/Download") {
        folderToSave = "Default: Downloads folder";
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

    GlobalKey _dropdownTheme = GlobalKey();
    GlobalKey _dropdownTracklist = GlobalKey();
    GlobalKey _dropdownPopUp = GlobalKey();

    if ((Platform.isAndroid || Platform.isIOS) && maxDownloads == 1) {
      colorDownloadButton = Colors.green;
    } else if (maxDownloads >= 6) {
      colorDownloadButton = Colors.red;
    }

    if (!(Platform.isMacOS || Platform.isIOS || Platform.isAndroid) && trackListSelect == 0) {
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
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      splashRadius = 1.0;
    }

    String titleAppBar = "Settings";
    double? heightTitleBar = 40.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    AppBar? settingsAppBar = AppBar(
        title: const Text("Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            Navigator.pop(context);
          },
        ));
    double? widthOfBorder;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      settingsAppBar = null;
    } else if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      widthOfBorder = 0.0;
    }

    return Scaffold(
        //appBar: settingsAppBar,
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
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  darkTheme: SettingsThemeData(
                      settingsListBackground: Theme.of(context).cardColor,
                      settingsSectionBackground: sectionColor,
                      titleTextColor: Theme.of(context).textTheme.bodyText1!.color!),
                  //platform: DevicePlatform.android,
                  sections: [
                    if (!Platform.isIOS)
                      SettingsSection(
                        title: const Text('Saving Path'),
                        tiles: <SettingsTile>[
                          SettingsTile.navigation(
                            title: const Text('Path'),
                            value: Text(folderToSave),
                            onPressed: (context) async {
                              if (Platform.isAndroid) {
                                var status = await Permission.storage.status;
                                if (!status.isGranted) {
                                  await Permission.storage.request();
                                }
                              }
                              String? path = await FilePicker.platform.getDirectoryPath(
                                  dialogTitle: "Choose Download Folder",
                                  initialDirectory: Directory(homeDirectory()).path);

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
                              title: const Text("Reset path"),
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
                      title: const Text('Appearance'),
                      tiles: <SettingsTile>[
                        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                          SettingsTile.switchTile(
                            title: const Text('Custom Window Border'),
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
                                content: const Text('Relaunch the App for the changes to take effect.'),
                                action: SnackBarAction(
                                    //textColor: Colors.white,
                                    label: 'Exit',
                                    onPressed: () {
                                      exit(0);
                                    }),
                              ));
                            },
                          ),
                        SettingsTile.switchTile(
                          title: const Text('Favorites is home-page'),
                          description: const Text('If off, search will be home-page. Requires restart.'),
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
                              content: const Text('Restart the app?'),
                              action: SnackBarAction(
                                  //textColor: Colors.white,
                                  label: 'Restart',
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
                              items: const [
                                DropdownMenuItem(
                                  child: Text("System", textAlign: TextAlign.center),
                                  value: "System",
                                ),
                                DropdownMenuItem(
                                  child: Text("Light", textAlign: TextAlign.center),
                                  value: "Light",
                                ),
                                DropdownMenuItem(
                                  child: Text("Dark"),
                                  value: "Dark",
                                ),
                                DropdownMenuItem(child: Text("Black"), value: "Black"),
                              ]),
                          title: const Text('App Theme'),
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
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: const Text('Restart the app?'),
                                action: SnackBarAction(
                                    //textColor: Colors.white,
                                    label: 'Restart',
                                    onPressed: () {
                                      Phoenix.rebirth(context);
                                    }),
                              ));
                            },
                            title: const Text("Material Design 3"))
                      ],
                    ),
                    SettingsSection(
                      title: const Text("Behavior"),
                      tiles: [
                        SettingsTile.navigation(
                          title: const Text("Track-list tap behavior"),
                          description: const Text("The action that occurs when tapped on item in the track-list."),
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
                                if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid)
                                  const DropdownMenuItem(
                                    child: Text("Preview song"),
                                    value: "Preview",
                                  ),
                                const DropdownMenuItem(
                                  child: Text("Open in Browser"),
                                  value: "Browser",
                                ),
                                const DropdownMenuItem(
                                  child: Text("Download song"),
                                  value: "Download",
                                )
                              ]),
                          onPressed: (context) {
                            openDropdown(_dropdownTracklist);
                          },
                        ),
                        SettingsTile.navigation(
                          title: const Text("Pop-Ups"),
                          description: const Text("The pop-up displayed when downloading an song/album."),
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
                              items: const [
                                DropdownMenuItem(
                                  child: Text("Auto"),
                                  value: "Auto",
                                ),
                                DropdownMenuItem(
                                  child: Text("Pop-up"),
                                  value: "Pop-up",
                                ),
                                DropdownMenuItem(
                                  child: Text("Bottom"),
                                  value: "Bottom",
                                )
                              ]),
                          onPressed: (context) {
                            openDropdown(_dropdownPopUp);
                          },
                        ),
                        SettingsTile.navigation(
                          title: const Text("Concurrent Downloads"),
                          description: const Text("Currently unused."),
                          value: Row(children: [Text(maxDownloads.toString() + " - ", style: TextStyle(color: colorDownloadButton)), Text("Unused", style: TextStyle(color: Theme.of(context).errorColor),)]),
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
                                                    const ListTile(
                                                      contentPadding: EdgeInsets.all(10),
                                                      title: Text("Concurrent Downloads"),
                                                      subtitle: Text(
                                                          "Change the amount of concurrent downloads allowed by the app. Recommended to set to '1' on mobile devices."),
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
