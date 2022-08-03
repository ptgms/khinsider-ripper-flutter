import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
//import 'package:native_context_menu/native_context_menu.dart' as ctxmenu;
import 'package:flutter/material.dart';
import 'package:khinrip/album_view.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

SizedBox noFavs(context) {
  // if no favs saved return placeholder
  var t = AppLocalizations.of(context)!;
  return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text(t.welcome, style: const TextStyle(fontSize: 25), textAlign: TextAlign.center))),
        Center(
          child: Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 0), child: Text(t.welcomeDescription, textAlign: TextAlign.center)),
        ),
      ]));
}

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

class FavoriteWidget extends StatefulWidget {
  const FavoriteWidget({Key? key}) : super(key: key);

  @override
  _FavoriteWidgetState createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  var _favorites = favorites;

  Widget getTitleText(int index) {
    // gets the cell text for a particular favorite
    Widget noPicFound = const Icon(Icons.album);
    Decoration favoriteImage = const BoxDecoration();
    if (favorites[index].albumCover != "none" && favorites[index].albumCover != "") {
      noPicFound = Container();
      favoriteImage = BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(getRoundedValue())),
          color: const Color.fromRGBO(71, 71, 71, 0.2),
          image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(favorites[index].albumCover)));
    }

    return ListTile(
      leading: Container(width: 50, height: 50, decoration: favoriteImage, child: noPicFound),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () {
          //appValueNotifier.update();
          favorites.removeAt(index);
          setState(() {
            _favorites = favorites;
            saveFavs();
          });
        },
      ),
      title: Marquee(child: Text(favorites[index].albumName)),
      subtitle: Marquee(
        child: Text(favorites[index].albumLink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    //List<Widget> TitleTextColumn = getTitleText();
    double width = MediaQuery.of(context).size.width;
    int widthCard = 400;

    int heightCard = 72;

    if (width < widthCard) {
      widthCard = width.toInt() - 1;
    }

    int count = width ~/ widthCard;

    widthCard = width ~/ count;

    if (Platform.isLinux || Platform.isMacOS) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ValueListenableBuilder<int>(
          valueListenable: favUpdater,
          builder: (_, __, ___) {
            if (favorites.isEmpty && favoriteHome) return noFavs(context);
            return GridView.builder(
                itemCount: favorites.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  childAspectRatio: (widthCard / heightCard),
                ),
                itemBuilder: (context, index) => Card(
                    shape: cardShape,
                    child: InkWell(
                        customBorder: cardShape,
                        mouseCursor: MouseCursor.uncontrolled,
                        onTap: () async {
                          debugPrint("Tapped on favorite " + favorites[index].albumName);
                          if (!busy) {
                            await goToAlbum(context, favorites[index].albumName, favorites[index].albumLink);
                          }
                        },
                        child: getTitleText(index))));
          },
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ValueListenableBuilder<int>(
          valueListenable: favUpdater,
          builder: (_, __, ___) {
            if (favorites.isEmpty && favoriteHome) return noFavs(context);
            return GridView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemCount: favorites.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  childAspectRatio: (widthCard / heightCard),
                ),
                itemBuilder: (context, index) => Card(
                    shape: cardShape,
                    child: InkWell(
                        customBorder: cardShape,
                        mouseCursor: MouseCursor.uncontrolled,
                        onLongPress: () {
                          showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                  title: Text(favorites[index].albumName),
                                  content: SizedBox(
                                    height: 112,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Text(t.removeFavorite),
                                          leading: const Icon(Icons.star_half_rounded),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            favorites.removeAt(index);
                                            setState(() {
                                              _favorites = favorites;
                                              saveFavs();
                                            });
                                          },
                                        ),
                                        ListTile(
                                          title: Text(t.openInBrowser),
                                          leading: const Icon(Icons.open_in_browser_rounded),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            launchUrl(Uri.parse(baseUrl + favorites[index].albumLink));
                                          },
                                        ),
                                      ],
                                    ),
                                  )));
                        },
                        onTap: () async {
                          debugPrint("Tapped on favorite " + favorites[index].albumName);
                          if (!busy) {
                            await goToAlbum(context, favorites[index].albumName, favorites[index].albumLink);
                          }
                        },
                        child: getTitleText(index))));
          },
        ),
      );
    }
  }
}
