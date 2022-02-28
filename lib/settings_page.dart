import 'dart:io';

import 'package:flutter/material.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
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
      // iOS doesn't really have a home directory.
      return "/";
    case 'fuchsia':
      // I have no idea.
      return "/";
    default:
      return "/";
  }
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

    return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: ListView(
          children: [
            Container(height: 30, color: Colors.transparent),
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
            Container(
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
          ],
        ));
  }
}
