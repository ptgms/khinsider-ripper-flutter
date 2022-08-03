import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:khinrip/favorite_view.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/main.dart';
import 'package:khinrip/settings_page.dart';
import 'package:khinrip/structs.dart';
import 'package:khinrip/window.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'album_view.dart';
import 'browse_popular.dart';

SizedBox noResults() {
  return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Center(
            child: Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text("No results!", style: TextStyle(fontSize: 25), textAlign: TextAlign.center))),
        Center(
          child: Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0), child: Text("Try adjusting your search term.", textAlign: TextAlign.center)),
        ),
      ]));
}

SizedBox emptySearch(context) {
  var t = AppLocalizations.of(context)!;
  return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text(t.startSearch, style: const TextStyle(fontSize: 25), textAlign: TextAlign.center))),
        Center(
          child:
              Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 0), child: Text(t.startSearchDescription, textAlign: TextAlign.center)),
        ),
      ]));
}

SizedBox searchingIndicator() {
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

var _searchResults = searchResults;

//var busy = false;

class SearchWidget extends StatefulWidget {
  const SearchWidget({Key? key}) : super(key: key);

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

List<AlbumStruct> searchResults = [];
String searchTermBefore = "";

class _SearchWidgetState extends State<SearchWidget> {
  final fieldText = TextEditingController();
  var searched = false;

  bool searching = false;

  Future<void> searchPressed(String term) async {
    if (term == "") {
      debugPrint(term);
      searched = false;
      searchResults = [];
      searchTermBefore = term;
      return;
    }
    searchResults = [];
    searchTermBefore = term;
    searched = true;

    setState(() {
      searching = true;
    });

    Uri searchURL = Uri.parse(baseUrl + baseSearchUrl + Uri.encodeFull(term));
    debugPrint(searchURL.toString());

    http.Request req = http.Request("Get", searchURL)..followRedirects = false;
    http.Client baseClient = http.Client();
    http.StreamedResponse response = await baseClient.send(req);
    Uri redirectUri = Uri.parse(response.headers['location'] ?? "error");

    if (redirectUri.toString().contains("game-soundtracks/album")) {
      String resultName = redirectUri.toString().replaceAll(baseUrl + baseAlbumUrl, "");

      if (searchResults.contains(AlbumStruct(resultName, redirectUri.toString(), ""))) {
        return;
      }

      searchResults.add(AlbumStruct(resultName, redirectUri.toString(), ""));

      setState(() {
        searching = false;
        for (var search in searchResults) {
          debugPrint(search.albumName);
        }
        _searchResults = searchResults;
      });
    } else {
      http.read(searchURL).then((contents) {
        //debugPrint(contents);
        BeautifulSoup bs = BeautifulSoup(contents);
        var link = bs.find('table', class_: 'albumList');

        for (var row in link!.findAll('tr')) {
          String albumNameTemp = "";
          String albumLinkTemp = "";
          String albumCoverTemp = "none";

          /*for (var col in row.findAll('tr')) {
            if (col['href']!.contains("game-soundtracks/browse/") || col['href']!.contains("/forums/")) {
              continue;
            }
            if (col['href']!.contains("game-soundtracks/browse/")) {
              continue;
            }

            String colContent = col.text;
            String colHref = col['href']!;

            searchResults.add(AlbumStruct(colContent, colHref));
          }*/
          if (row.children[0].innerHtml == "") {
            continue;
          }
          if (row.children[0].find('img') != null) {
            albumCoverTemp = row.children[0].find('img')!['src']!;
          }
          albumNameTemp = row.children[1].find('a')!.innerHtml;
          albumLinkTemp = row.children[1].find('a')!['href']!;
          searchResults.add(AlbumStruct(albumNameTemp, albumLinkTemp, albumCoverTemp));
        }

        setState(() {
          searching = false;
          for (var search in searchResults) {
            debugPrint(search.albumName);
          }
          _searchResults = searchResults;
        });
        //fieldText.text = searchTermBefore;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    Widget bodyDisplay;

    double width = MediaQuery.of(context).size.width;
    int widthCard = 400;

    int heightCard = 72;

    if (width < widthCard) {
      widthCard = width.toInt() - 1;
    }

    int count = width ~/ widthCard;

    widthCard = width ~/ count;

    if (searching) {
      bodyDisplay = searchingIndicator();
    } else if (searched && _searchResults.isEmpty) {
      bodyDisplay = noResults();
    } else if (!searched) {
      bodyDisplay = emptySearch(context);
    } else {
      bodyDisplay = GridView.builder(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemCount: _searchResults.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            childAspectRatio: (widthCard / heightCard),
          ),
          itemBuilder: (context, index) => ValueListenableBuilder<int>(
              valueListenable: favUpdater,
              builder: (_, __, ___) {
                Widget noPicFound = const Icon(Icons.album);
                Decoration searchImage = const BoxDecoration();
                if (_searchResults[index].albumCover != "none" && _searchResults[index].albumCover != "") {
                  noPicFound = Container();
                  searchImage = BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(getRoundedValue())),
                      color: const Color.fromRGBO(71, 71, 71, 0.2),
                      image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(_searchResults[index].albumCover)));
                }
                return Card(
                    shape: cardShape,
                    child: InkWell(
                      customBorder: cardShape,
                      mouseCursor: MouseCursor.uncontrolled,
                      onTap: () {
                        debugPrint("Tapped " + _searchResults[index].albumName);
                        goToAlbum(context, _searchResults[index].albumName, _searchResults[index].albumLink);
                      },
                      child: ListTile(
                        leading: Container(width: 50, height: 50, decoration: searchImage, child: noPicFound),
                        trailing: IconButton(
                          icon: foundInFavorites(searchResults[index]) ? const Icon(Icons.star) : const Icon(Icons.star_border),
                          onPressed: () {
                            if (favorites.contains(searchResults[index])) {
                              favorites.removeAt(locateInFavorites(searchResults[index]));
                            } else {
                              favorites.add(searchResults[index]);
                            }
                            setState(() {
                              saveFavs();
                              favUpdater.value += 1;
                            });
                          },
                        ),
                        title: Marquee(child: Text(_searchResults[index].albumName)),
                        subtitle: Marquee(
                          child: Text(_searchResults[index].albumLink),
                        ),
                      ),
                    ));
              }));
    }

    var colorSearch = Colors.white;

    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    if (isDarkMode) {
      colorSearch = Colors.black54;
    }

    if (appTheme == 1) {
      //print(isDarkMode);
      colorSearch = Colors.white;
    } else if (appTheme == 2) {
      colorSearch = Colors.black54;
    }

    fieldText.text = searchTermBefore;
    debugPrint(searchTermBefore);

    double splashRadius = 35.0;
    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      splashRadius = 1.0;
    }

    List<Widget> actions = [
      if (!favoriteHome)
        IconButton(
          splashRadius: splashRadius,
          onPressed: () async {
            final _ = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PopularWidget()));
          },
          tooltip: t.browse,
          icon: const Icon(Icons.library_music),
        ),
      if (!favoriteHome)
        IconButton(
            splashRadius: splashRadius,
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FavoriteHome(
                            title: t.favorites,
                          )));
            },
            icon: const Icon(Icons.star_rounded)),
      if (!favoriteHome)
        IconButton(
          splashRadius: splashRadius,
          onPressed: (() {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
          icon: const Icon(Icons.settings_rounded),
        ),
      //if (!favoriteHome && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) const WindowButtons()
    ];

    ValueNotifier<bool> clearVisible = ValueNotifier(false);

    Widget searchBox = Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(color: colorSearch, borderRadius: BorderRadius.circular(10)),
      child: Center(
        child: TextField(
          onChanged: (value) {
            clearVisible.value = (value != "");
          },
          onSubmitted: (term) async {
            searchPressed(term);
          },
          controller: fieldText,
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<bool>(
                valueListenable: clearVisible,
                builder: ((context, value, child) => value
                    ? IconButton(
                        splashRadius: splashRadius,
                        icon: const Icon(
                          Icons.clear,
                          size: 17.0,
                        ),
                        onPressed: () {
                          fieldText.clear();
                          clearVisible.value = false;
                        },
                      )
                    : Container()),
              ),
              hintText: t.searchForOSTs,
              border: InputBorder.none),
        ),
      ),
    );

    AppBar? searchAppBar = AppBar(
        // The search area here
        title: searchBox,
        actions: actions);

    String titleAppBar = t.search;
    double? heightTitleBar = 40.0;
    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    AppBar? display = searchAppBar;

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      display = null;
    }

    if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && windowBorder) {
      searchAppBar = null;
    }

    List<Widget> actionsWindow = [
      if (Platform.isMacOS) const SizedBox(width: 60),
      if (favoriteHome && windowBorder)
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
      if (windowBorder) Expanded(child: searchBox),
    ];

    return MainWindow(
        appBar: searchAppBar, display: display, actions: actions, actionsWindow: actionsWindow, title: t.search, body: bodyDisplay);
  }
}
