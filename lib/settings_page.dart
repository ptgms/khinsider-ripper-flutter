import 'dart:io';

import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:khinrip/config.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:permission_handler/permission_handler.dart';
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
}

class _SettingsPageState extends State<SettingsPage> {
  var folderToSave = "Default: Path of executable";

  void saveLocation() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("location", pathToSaveIn);
  }

  @override
  Widget build(BuildContext context) {
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    var defaultText = "Default: Path of executable";
    double toAdd = 0;

    if (Platform.isAndroid) {
      defaultText = "Default: Downloads folder";
      toAdd = 10;
    }

    if (pathToSaveIn == "") {
      folderToSave = defaultText;
    } else {
      if (Platform.isAndroid && pathToSaveIn == "/storage/emulated/0/Download") {
        folderToSave = "Default: Downloads folder";
      } else {
        folderToSave = pathToSaveIn;
      }
    }

    var themes = ["System", "Light", "Dark", "AMOLED"];
    var trackListBehaviorStrings = ["Preview", "Browser", "Download"];
    var popupBehaviorStrings = ["Auto", "Pop-up", "Bottom"];

    var trackListSelect = trackListBehavior;
    var colorDownloadButton = Theme.of(context).hintColor;

    if ((Platform.isAndroid || Platform.isIOS) && maxDownloads == 1) {
      colorDownloadButton = Colors.green;
    } else if (maxDownloads >= 6) {
      colorDownloadButton = Colors.red;
    }

    if (!(Platform.isMacOS || Platform.isIOS || Platform.isAndroid) && trackListSelect == 0) {
      trackListSelect = 1;
    }
    return Scaffold(
        appBar: AppBar(
            title: const Text("Settings"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                Navigator.pop(context);
              },
            )),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: ListView(
            children: [
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS || Platform.isAndroid)
                Container(height: 30, color: Colors.transparent),
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS || Platform.isAndroid)
                Container(
                    height: 20 + toAdd,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    alignment: Alignment.bottomLeft,
                    child: Row(children: [
                      const Text(
                        "Saving path",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              setState(() {
                                pathToSaveIn = "";
                                saveLocation();
                                folderToSave = defaultText;
                              });
                            },
                            child: const Text("Set default"),
                          ),
                        ),
                      ),
                    ])),
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS || Platform.isAndroid)
                SizedBox(
                    height: 55,
                    child: Card(
                      child: OutlinedButton(
                        onPressed: () async {
                          if (Platform.isAndroid) {
                            var status = await Permission.storage.status;
                            if (!status.isGranted) {
                              await Permission.storage.request();
                            }
                          }
                          String? path = await FilesystemPicker.open(
                            rootName: "Home folder",
                            title: 'Use folder',
                            context: context,
                            rootDirectory: Directory(homeDirectory()),
                            fsType: FilesystemType.folder,
                            pickText: 'Use this folder for Downloads',
                            folderIconColor: Colors.teal,
                          );

                          if (path != null) {
                            setState(() {
                              pathToSaveIn = path;
                              saveLocation();
                              folderToSave = path;
                            });
                          }
                        },
                        child: Marquee(child: Text(folderToSave)),
                      ),
                    )),
              Container(height: 30, color: Colors.transparent),
              Container(
                  height: 20,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  alignment: Alignment.bottomLeft,
                  child: const Text("Appearance", style: TextStyle(color: Colors.grey))),
              SizedBox(
                  child: Card(
                      shape: cardShape,
                      child: ListTile(
                        title: const Text("Favorites is home-page"),
                        subtitle: const Text("If off, search will be home-page. Requires restart."),
                        trailing: Switch(
                          value: favoriteHome,
                          onChanged: (bool value) {
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
                      ))),
              //Container(height: 10, color: Colors.transparent),
              SizedBox(
                  child: Card(
                      shape: cardShape,
                      child: ListTile(
                        title: const Text("App Theme"),
                        //subtitle: const Text("If none selected, System will be used."),
                        trailing: DropdownButton<String>(
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
                                case "AMOLED":
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
                                child: Text("System"),
                                value: "System",
                              ),
                              DropdownMenuItem(
                                child: Text("Light"),
                                value: "Light",
                              ),
                              DropdownMenuItem(
                                child: Text("Dark"),
                                value: "Dark",
                              ),
                              DropdownMenuItem(child: Text("AMOLED"), value: "AMOLED"),
                            ]),
                      ))),
              SizedBox(
                  child: Card(
                      shape: cardShape,
                      child: ListTile(
                        title: const Text("Material Design 3"),
                        trailing: Switch(
                          value: md3,
                          onChanged: (bool value) {
                            //debugPrint(value.toString());
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
                        ),
                      ))),
              Container(height: 30, color: Colors.transparent),
              Container(
                  height: 20,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  alignment: Alignment.bottomLeft,
                  child: const Text("Behavior", style: TextStyle(color: Colors.grey))),
              SizedBox(
                  child: Card(
                      shape: cardShape,
                      child: ListTile(
                        title: const Text("Track-list tap behavior"),
                        subtitle: const Text("The action that occurs when tapped on item in the track-list."),
                        //subtitle: const Text("If none selected, System will be used."),
                        trailing: DropdownButton<String>(
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
                      ))),
              SizedBox(
                  child: Card(
                      shape: cardShape,
                      child: ListTile(
                        title: const Text("Pop-ups"),
                        subtitle: const Text("The pop-up displayed when downloading an song/album."),
                        //subtitle: const Text("If none selected, System will be used."),
                        trailing: DropdownButton<String>(
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
                      ))),
              SizedBox(
                  child: Card(
                      shape: cardShape,
                      child: ListTile(
                        title: const Text("Concurrent Downloads"),
                        subtitle: const Text("The maximum amount of concurrent downloads that occur."),
                        //subtitle: const Text("If none selected, System will be used."),
                        trailing: OutlinedButton(
                            child: Text(maxDownloads.toString(), style: TextStyle(color: colorDownloadButton)),
                            onPressed:
                                null /*() {
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
                  }, */
                            ),
                      ))),
            ],
          ),
        ));
  }
}
