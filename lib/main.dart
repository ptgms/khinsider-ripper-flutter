import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl_standalone.dart';
import 'package:khinrip/search_page.dart';
import 'package:khinrip/settings_page.dart';
import 'package:khinrip/structs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:titlebar_buttons/titlebar_buttons.dart';
import 'package:window_manager/window_manager.dart';
import 'favorite_view.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- load preferences ---
  final prefs = await SharedPreferences.getInstance();

  var favNames = prefs.getStringList("favs_name");
  var favLink = prefs.getStringList("favs_link");
  var favCover = prefs.getStringList("favs_cover");

  var defaultLang = "system";

  pathToSaveIn = prefs.getString("location") ?? "";
  favoriteHome = prefs.getBool("fav_home") ?? true;
  appTheme = prefs.getInt("app_theme") ?? 0;
  trackListBehavior = prefs.getInt("track_behavior") ?? 0;
  popupStyle = prefs.getInt("popup_style") ?? 0;
  maxDownloads = prefs.getInt("max_downloads") ?? 1;
  md3 = prefs.getBool("material_3") ?? false;
  windowBorder = prefs.getBool("window_border") ?? true;
  setLanguage = prefs.getString("language") ?? defaultLang;

  // analytics = prefs.getBool("analytics") ?? true;
  // ------

  /*if ((Platform.isAndroid || Platform.isIOS || Platform.isMacOS) && analytics) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }*/

  // convert favorites in string list format to albumstruct list
  if (favNames != null && favLink != null) {
    for (var i = 0; i < favNames.length; i++) {
      favorites.add(AlbumStruct(favNames[i], favLink[i], favCover?[i] ?? ""));
    }
  }

  await findSystemLocale();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(800, 600),
      minimumSize: Size(550, 384),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(Phoenix(child: const MyApp()));
  //runApp();
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    ThemeType _currentThemeType = ThemeType.adwaita;
    return Row(children: [
      InkWell(
        autofocus: true,
        child: DecoratedMinimizeButton(
          type: _currentThemeType,
          onPressed: () => windowManager.minimize(),
        ),
      ),
      InkWell(
        child: DecoratedMaximizeButton(
          type: _currentThemeType,
          onPressed: () {
            windowManager.isMaximized().then((value) {
              if (value) {
                windowManager.restore();
              } else {
                windowManager.maximize();
              }
            });
          },
        ),
      ),
      InkWell(
        child: DecoratedCloseButton(
          type: _currentThemeType,
          onPressed: () => exit(0),
        ),
      ),
      const SizedBox(width: 5),
    ]);
    /*
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
    );*/
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
    var language = "";
    if (setLanguage == "system") {
      String defaultLocale = Platform.localeName.split("_")[0];

      if (!["en", "de", "pl", "nl", "ar", "fr", "es"].contains(defaultLocale)) {
        defaultLocale = "en";
      }

      language = defaultLocale;
    } else {
      language = setLanguage;
    }

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
            onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.khinsiderRipper,
            //title: "Khinsider Ripper",
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('de', ''),
              Locale('nl', ''),
              Locale('pl', ''),
              Locale('ar', ''),
              Locale('fr', ''),
              Locale('es', '')
            ],
            debugShowCheckedModeBanner: false,
            locale: Locale(language, ''),
            theme: ThemeData.light().copyWith(useMaterial3: md3),
            darkTheme: (appTheme == 3) ? amoledTheme : ThemeData.dark().copyWith(useMaterial3: md3),
            themeMode: theme,
            home: favoriteHome ? const FavoriteHome(title: "Khinsider Ripper") : const SearchWidget(),
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
    var t = AppLocalizations.of(context)!;
    double splashRadius = 35.0;
    if ((Platform.isMacOS || Platform.isLinux) && windowBorder) {
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
    String titleAppBar = t.khinsiderRipper;
    double? heightTitleBar = 40.0;
    if ((Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }
    AppBar? mainAppBar = AppBar(
      centerTitle: false,
      title: Text(widget.title),
      actions: actions,
    );

    AppBar? display = mainAppBar;

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      display = null;
    }

    double? widthOfBorder;
    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      mainAppBar = null;
    } else if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder) {
      widthOfBorder = 0.0;
    }

    if (/*Platform.isWindows || */ Platform.isAndroid || Platform.isIOS) {
      widthOfBorder = 0.0;
    }

    return Scaffold(
        appBar: display,
        body: Container(
            //width: widthOfBorder,
            //color: Theme.of(context).backgroundColor,
            child: Column(children: [
          if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows))
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
                      if (windowBorder) Row(children: actions),
                      const SizedBox(child: WindowButtons())
                    ]))),
          if ((Platform.isMacOS || Platform.isLinux) && !windowBorder && mainAppBar != null) mainAppBar,
          Expanded(child: bodyToPush)
        ])));
  }
}
