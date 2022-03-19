import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
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

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    doWhenWindowReady(() {
      const initialSize = Size(550, 384);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = "Khinsider Ripper";
      appWindow.show();
    });
  }
  //runApp();
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
        iconNormal: Theme.of(context).textTheme.bodyMedium!.color,
        mouseOver: Colors.grey,
        mouseDown: Colors.black54,
        iconMouseOver: Theme.of(context).textTheme.bodyMedium!.color,
        iconMouseDown: Theme.of(context).textTheme.bodyMedium!.color);

    final closeButtonColors = WindowButtonColors(
      mouseOver: Color(0xFFD32F2F),
      mouseDown: Color(0xFFB71C1C),
      iconNormal: Theme.of(context).textTheme.bodyMedium!.color,
      iconMouseOver: Theme.of(context).textTheme.bodyMedium!.color,
    );

    return SizedBox(
      child: Row(
        //crossAxisAlignment: CrossAxisAlignment.start,
        //mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MinimizeWindowButton(colors: buttonColors),
          MaximizeWindowButton(colors: buttonColors),
          CloseWindowButton(colors: closeButtonColors),
        ],
      ),
    );
  }
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
    List<Widget> actions = [
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
        ),
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) const SizedBox(height: 40, child: WindowButtons())
    ];

    AppBar? mainAppBar = AppBar(
      centerTitle: false,
      title: Text(widget.title),
      actions: actions,
    );

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      mainAppBar = null;
    }
    return Scaffold(
        appBar: mainAppBar,
        body: WindowBorder(
            color: Theme.of(context).backgroundColor,
            child: Column(children: [
              if (Platform.isLinux || Platform.isMacOS || Platform.isWindows)
                SizedBox(
                    child: Container(
                        color: Theme.of(context).cardColor,
                        child: Row(
                          children: [
                                if (!favoriteHome)
                                  IconButton(
                                    icon: const Icon(Icons.navigate_before),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                Expanded(
                                    child: SizedBox(
                                        height: 40,
                                        child: MoveWindow(
                                            child: Padding(
                                          padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
                                          child: Text(
                                            widget.title,
                                            style: Theme.of(context).textTheme.headline6,
                                            textAlign: TextAlign.center,
                                          ),
                                        ))))
                              ] +
                              actions,
                        ))),
              Expanded(child: bodyToPush)
            ])));
  }
}
