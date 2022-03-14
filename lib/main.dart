import 'dart:io';

import 'package:flutter/material.dart';
import 'package:khinrip/search_page.dart';
import 'package:khinrip/settings_page.dart';
import 'package:khinrip/structs.dart';
import 'package:window_size/window_size.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'favorite_view.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // on desktops, the window title would be something random otherwise.
    setWindowTitle('Khinsider Ripper');
    setWindowMinSize(const Size(512, 384));
  }

  // --- load preferences ---
  final prefs = await SharedPreferences.getInstance();

  var favNames = prefs.getStringList("favs_name");
  var favLink = prefs.getStringList("favs_link");

  pathToSaveIn = prefs.getString("location") ?? "";
  favoriteHome = prefs.getBool("fav_home") ?? true;
  appTheme = prefs.getInt("app_theme") ?? 0;
  trackListBehavior = prefs.getInt("track_behavior") ?? 0;
  popupStyle = prefs.getInt("popup_style") ?? 0;
  maxDownloads = prefs.getInt("max_downloads") ?? 1;
  md3 = prefs.getBool("material_3") ?? false;
  // ------

  // convert favorites in string list format to albumstruct list
  if (favNames != null && favLink != null) {
    for (var i = 0; i < favNames.length; i++) {
      favorites.add(AlbumStruct(favNames[i], favLink[i]));
    }
  }
  runApp(Phoenix(child: const MyApp()));
  //runApp();
}

var dark = true;

ThemeData amoledTheme = ThemeData(
    brightness: Brightness.dark,
    backgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(color: Colors.black),
    cardColor: Colors.black,
    scaffoldBackgroundColor: Colors.black,
    shadowColor: Colors.grey,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.black),
    dialogBackgroundColor: Colors.grey);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //final ValueNotifier<int> _notifier = ValueNotifier(appTheme);
    return ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (_, mode, __) {
          var theme = ThemeMode.system;
          switch (appTheme) {
            case 0:
              theme = ThemeMode.system;
              break;
            case 1:
              theme = ThemeMode.light;
              break;
            case 2:
              theme = ThemeMode.dark;
              break;
            case 3:
              theme = ThemeMode.dark;
              break;
            default:
          }
          return MaterialApp(
            title: 'Khinsider Ripper',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light().copyWith(useMaterial3: md3),
            darkTheme: (appTheme == 3) ? amoledTheme : ThemeData.dark().copyWith(useMaterial3: md3),
            themeMode: theme,
            home: favoriteHome ? const FavoriteHome(title: 'Khinsider Ripper') : const SearchWidget(),
          );
        });
  }
}

class FavoriteHome extends StatefulWidget {
  const FavoriteHome({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<FavoriteHome> createState() => _FavoriteHomeState();
}

class _FavoriteHomeState extends State<FavoriteHome> {
  var bodyToPush = const FavoriteWidget();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(widget.title),
          actions: [
            if (favoriteHome)
              IconButton(
                onPressed: () async {
                  final _ = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchWidget()));
                  setState(() {
                    bodyToPush = const FavoriteWidget();
                  });
                },
                icon: const Icon(Icons.search),
              ),
            if (favoriteHome)
              IconButton(
                onPressed: (() {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                }),
                icon: const Icon(Icons.settings_rounded),
              )
          ],
        ),
        body: bodyToPush);
  }
}
