import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;

import 'window.dart';

class PlatformBrowse extends StatefulWidget {
  const PlatformBrowse({Key? key, required this.path, required this.platform}) : super(key: key);

  final String path;
  final String platform;

  @override
  // ignore: no_logic_in_create_state
  State<PlatformBrowse> createState() => _PlatformBrowseState(path: path, platform: platform);
}

class _PlatformBrowseState extends State<PlatformBrowse> {
  _PlatformBrowseState({required this.path, required this.platform});
  final String path;
  final String platform;

  Future<void> saveFavs() async {
    // save favorites in preferences
    List<String> favNames = [];
    List<String> favLinks = [];
    List<String> favCover = [];

    for (var favItem in favorites) {
      favNames.add(favItem.albumName);
      favLinks.add(favItem.albumLink);
      favCover.add(favItem.albumCover);
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList("favs_name", favNames);
    await prefs.setStringList("favs_link", favLinks);
    await prefs.setStringList("favs_cover", favCover);
  }

  Widget getTitleText(albumImageURL, name, albumURL) {
    // gets the cell text for a particular favorite
    Widget noPicFound = const Icon(Icons.album);
    Decoration favoriteImage = const BoxDecoration();
    if (albumImageURL != "none" && albumImageURL != "") {
      noPicFound = Container();
      favoriteImage = BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(getRoundedValue())),
          color: const Color.fromRGBO(71, 71, 71, 0.2),
          image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(albumImageURL)));
    }

    var favStruct = AlbumStruct(name, albumURL, albumImageURL);

    return ValueListenableBuilder<int>(
        valueListenable: favUpdater,
        builder: ((context, value, child) => ListTile(
              leading: Container(width: 50, height: 50, decoration: favoriteImage, child: noPicFound),
              title: Marquee(child: Text(name)),
              trailing: IconButton(
                icon: foundInFavorites(favStruct) ? const Icon(Icons.star) : const Icon(Icons.star_border),
                onPressed: () {
                  if (foundInFavorites(favStruct)) {
                    favorites.removeAt(locateInFavorites(favStruct));
                  } else {
                    favorites.add(favStruct);
                  }
                  setState(() {
                    saveFavs();
                    favUpdater.value += 1;
                  });
                },
              ),
              subtitle: Marquee(child: Text(albumURL)),
            )));
  }

  Widget getCard(albumImageURL, name, albumURL) {
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    return Card(
        shape: cardShape,
        child: InkWell(
            customBorder: cardShape,
            mouseCursor: MouseCursor.uncontrolled,
            onTap: () async {
              debugPrint("Tapped on popular " + name);
              if (!busy) {
                await goToAlbum(context, name, albumURL);
                //await goToAlbum(context, index);
              }
            },
            child: getTitleText(albumImageURL, name, albumURL)));
  }

  SizedBox loadingIndicator() {
    return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Center(
              child: CircularProgressIndicator(), // Text("Start a search!", style: TextStyle(fontSize: 25),
            )
          ],
        ));
  }

  Future<List<Widget>> _loadData() async {
    List<Widget> mostDownloads = [];
    Uri completedUrl = Uri.parse(baseUrl + path);
    var contents = await http.read(completedUrl);

    BeautifulSoup bs = BeautifulSoup(contents);

    var link = bs.find('table')!.find('tbody');

    for (var row in link!.findAll('tr')) {
      for (var album in row.findAll('td', class_: 'albumIconLarge')) {
        var albumImage = "";
        if (album.children[0].find('img') != null) {
          albumImage = album.children[0].find('img')!.getAttrValue('src')!;
        }

        var name = album.children[0].find('p')!.getText();
        var albumURL = album.children[0].getAttrValue('href')!.replaceAll("http://downloads.khinsider.com", "");
        mostDownloads.add(getCard(albumImage, name, albumURL));
      }
    }

    return mostDownloads;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(path);
    var t = AppLocalizations.of(context)!;
    double splashRadius = 35.0;

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      splashRadius = 1.0;
    }

    String titleAppBar = t.browsingPlatform(platform);
    double? heightTitleBar = 40.0;
    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    AppBar? settingsAppBar = AppBar(
        title: Text(t.browsingPlatform(platform)),
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

    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      settingsAppBar = null;
    }

    var sectionColor = Colors.white10; //Theme.of(context).cardColor;
    if (appTheme == 3) {
      sectionColor = Colors.white10;
    }

    // [
    //if (!Platform.isIOS && !Platform.isMacOS) SettingsSection(tiles: [systemLanguage]),
    //SettingsSection(tiles: sectionsLanguages)]

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
                  style: Theme.of(context).textTheme.headline6,
                  textAlign: TextAlign.center,
                ),
              ))),
        ),
      )),
    ];

    Widget mostDownloads = FutureBuilder<List<Widget>>(
        future: _loadData(),
        builder: (context, snapshot) {
          List<Widget> value = [];
          if (!snapshot.hasData) {
            return loadingIndicator();
          } else {
            value = snapshot.data!;
          }
          value.insert(
              0,
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Text(
                  t.mostDownloaded,
                  style: TextStyle(fontSize: 24),
                ),
              ));
          return ListView(
            children: value,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          );
        });

    return MainWindow(
      appBar: settingsAppBar,
      display: display,
      actionsWindow: actionsWindow,
      title: t.browsingPlatform(platform),
      body: mostDownloads,
      actions: const [],
    );
  }
}
