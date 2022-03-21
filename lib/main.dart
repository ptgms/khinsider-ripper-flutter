import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:khinrip/search_page.dart';
import 'package:khinrip/settings_page.dart';
import 'package:khinrip/structs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'favorite_view.dart';
import 'config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
  windowBorder = prefs.getBool("window_border") ?? true;
  analytics = prefs.getBool("analytics") ?? true;
  // ------

  if ((Platform.isAndroid || Platform.isIOS || Platform.isMacOS) && analytics) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // convert favorites in string list format to albumstruct list
  if (favNames != null && favLink != null) {
    for (var i = 0; i < favNames.length; i++) {
      favorites.add(AlbumStruct(favNames[i], favLink[i]));
    }
  }
  runApp(Phoenix(child: const MyApp()));

  if ((Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    doWhenWindowReady(() {
      const initialSize = Size(550, 384);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = "Khinsider Ripper";
      appWindow.show();
    });
    //runApp();
  }
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
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: Theme.of(context).textTheme.bodyMedium!.color,
      iconMouseOver: Theme.of(context).textTheme.bodyMedium!.color,
    );

    Widget resMaxButton = MaximizeWindowButton(colors: buttonColors);

    if (appWindow.isMaximized) {
      resMaxButton = RestoreWindowButton(colors: buttonColors);
    }

    return SizedBox(
      child: Row(
        //crossAxisAlignment: CrossAxisAlignment.start,
        //mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MinimizeWindowButton(colors: buttonColors),
          resMaxButton,
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
    double splashRadius = 35.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      splashRadius = 1.0;
    }
    List<Widget> actions = [
      if (favoriteHome)
        IconButton(
          splashRadius: splashRadius,
          onPressed: () async {
            final _ = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchWidget()));
            //FirebaseCrashlytics.instance.crash();
            setState(() {
              bodyToPush = const FavoriteWidget();
            });
          },
          icon: const Icon(Icons.search),
        ),
      if (favoriteHome)
        IconButton(
          splashRadius: splashRadius,
          onPressed: (() {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
          icon: const Icon(Icons.settings_rounded),
        ),
    ];
    String titleAppBar = widget.title;
    double? heightTitleBar = 40.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }
    AppBar? mainAppBar = AppBar(
      centerTitle: false,
      title: Text(widget.title),
      actions: actions,
    );

    AppBar? display = mainAppBar;

    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      display = null;
    }
    
    double? widthOfBorder;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      mainAppBar = null;
    } else if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      widthOfBorder = 0.0;
    }

    return Scaffold(
        appBar: display,
        body: WindowBorder(
            width: widthOfBorder,
            color: Theme.of(context).backgroundColor,
            child: Column(children: [
              if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux))
                SizedBox(
                    child: Container(
                        color: Theme.of(context).cardColor,
                        child: Row(children: [
                          if (Platform.isMacOS) const SizedBox(width: 60),
                          if (!favoriteHome)
                            IconButton(
                              splashRadius: splashRadius,
                              icon: const Icon(Icons.navigate_before),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
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
                                  )))),
                          if (windowBorder) Row(children: actions),
                          const SizedBox(child: WindowButtons())
                        ]))),
              if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder && mainAppBar != null)
                mainAppBar,
              Expanded(child: bodyToPush)
            ])));
  }
}
