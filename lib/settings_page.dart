import 'dart:io';

import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:khinrip/config.dart';
import 'package:marquee_widget/marquee_widget.dart';
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
      // Probably want internal storage.
      return '/storage/sdcard0';
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
}

class _SettingsPageState extends State<SettingsPage> {
  var folderToSave = "Default: Path of executable";

  void saveLocation() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("location", pathToSaveIn);
  }

  @override
  Widget build(BuildContext context) {
    if (pathToSaveIn == "") {
      folderToSave = "Default: Path of executable";
    } else {
      folderToSave = pathToSaveIn;
    }

    var themes = ["System", "Light", "Dark"];

    return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: ListView(
            children: [
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                Container(height: 30, color: Colors.transparent),
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                Container(
                    height: 20,
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
                            onPressed: () {
                              setState(() {
                                pathToSaveIn = "";
                                saveLocation();
                                folderToSave = "Default: Path of executable";
                              });
                            },
                            child: const Text("Set default"),
                          ),
                        ),
                      ),
                    ])),
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                SizedBox(
                    height: 55,
                    child: Card(
                      child: OutlinedButton(
                        onPressed: () async {
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
                  child: const Text("Appearance",
                      style: TextStyle(color: Colors.grey))),
              SizedBox(
                  child: Card(
                      child: ListTile(
                title: const Text("Favorites is home-page"),
                subtitle: const Text(
                    "If off, search will be home-page. Requires restart."),
                trailing: Switch(
                  value: favoriteHome,
                  onChanged: (bool value) {
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
                        default:
                      }
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
                      )
                    ]),
              ))),
            ],
          ),
        ));
  }
}
