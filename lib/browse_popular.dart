import 'dart:io';

//import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:khinrip/window.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;

import 'browse_platform.dart';

class PopularWidget extends StatefulWidget {
  const PopularWidget({Key? key}) : super(key: key);

  @override
  State<PopularWidget> createState() => _PopularWidgetState();
}

class _PopularWidgetState extends State<PopularWidget> {
  List<Widget> popularList = [];

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

  Widget getTitleText(albumImageURL, name, albumURL, position) {
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
              subtitle: Marquee(child: Text(position + " - " + albumURL)),
            )));
  }

  Widget getCard(albumImageURL, name, albumURL, position) {
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    return Card(
        shape: cardShape,
        child: InkWell(
            customBorder: cardShape,
            mouseCursor: MouseCursor.uncontrolled,
            onTap: () async {
              if (!busy) {
                await goToAlbum(context, name, albumURL);
                //await goToAlbum(context, index);
              }
            },
            child: getTitleText(albumImageURL, name, albumURL, position)));
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
    Uri completedUrl = Uri.parse(baseUrl + top40Url);
    var contents = await http.read(completedUrl);

    BeautifulSoup bs = BeautifulSoup(contents);

    var link = bs.find('', id: 'top40')!.find('tbody');

    var firstRun = true;

    for (var row in link!.findAll('tr')) {
      if (firstRun) {
        firstRun = false;
        continue;
      }

      var albumImage = row.children[0].find('a')!.find('img')!.getAttrValue('src');
      var name = row.children[2].find('a')!.getText();
      var albumURL = row.children[2].find('a')!.getAttrValue('href')!.replaceAll("http://downloads.khinsider.com", "");
      var position = row.children[1].getText();

      popularList.add(getCard(albumImage, name, albumURL, position));
    }

    return popularList;
  }

  List<SettingsTile> platforms = [];

  Future<List<SettingsTile>> _loadPlatforms() async {
    Uri completedUrl = Uri.parse(baseUrl + allPlatformsUrl);
    var contents = await http.read(completedUrl);

    BeautifulSoup bs = BeautifulSoup(contents);

    var link = bs.find('', id: 'pageContent');

    for (var row in link!.findAll('a')) {
      platforms.add(SettingsTile.navigation(
        title: Text(row.text),
        onPressed: (context) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PlatformBrowse(
                      path: row.getAttrValue('href')!,
                      platform: row.text,
                    )),
          );
        },
      ));
    }

    return platforms;
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    double splashRadius = 35.0;

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      splashRadius = 1.0;
    }

    String titleAppBar = t.browse;
    double? heightTitleBar = 40.0;
    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    AppBar? settingsAppBar = AppBar(
        title: Text(t.browse),
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

    Widget displayPlatforms = FutureBuilder<List<SettingsTile>>(
        future: _loadPlatforms(),
        builder: (context, snapshot) {
          List<SettingsTile> value = [];
          if (!snapshot.hasData) {
            value = [SettingsTile(title: Text("Loading"))];
          } else {
            value = snapshot.data!;
          }
          return SettingsList(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              platform: devicePlat,
              darkTheme: SettingsThemeData(
                  settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
                  settingsSectionBackground: sectionColor,
                  titleTextColor: Theme.of(context).textTheme.bodyText1!.color!),
              sections: [SettingsSection(tiles: value)]);
        });

    Widget popularWidget = FutureBuilder<List<Widget>>(
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
                  t.popular,
                  style: TextStyle(fontSize: 24),
                ),
              ));
          value.add(Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text(
              t.platform,
              style: TextStyle(fontSize: 24),
            ),
          ));
          value.add(displayPlatforms);
          return ListView(
            children: value,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          );
        });

    return MainWindow(
      appBar: settingsAppBar,
      display: display,
      actionsWindow: actionsWindow,
      title: t.browse,
      body: popularWidget,
      actions: const [],
    );
  }
}
