import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:khinrip/favorite_view.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/main.dart';
import 'package:khinrip/settings_page.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:http/http.dart' as http;

import 'album_view.dart';

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
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text("Try adjusting your search term.", textAlign: TextAlign.center)),
        ),
      ]));
}

SizedBox emptySearch() {
  return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Center(
            child: Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text("Start a search!", style: TextStyle(fontSize: 25), textAlign: TextAlign.center))),
        Center(
          child: Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Text("Start searching to show results!", textAlign: TextAlign.center)),
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

var busy = false;

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

  Future<void> goToAlbum(BuildContext context, int index) async {
    if (busy) {
      debugPrint("Im busy yo");
      return;
    } else {
      busy = true;
    }

    // ignore: prefer_typing_uninitialized_variables
    var mp3, flac, ogg = false;

    List<String> tracks = [];
    List<String> trackDuration = [];
    String albumName = _searchResults[index].albumName;
    String albumLink = baseUrl + _searchResults[index].albumLink;
    List<String> trackURL = [];
    List<String> coverURL = [];

    List<String> tags = [];
    List<String> trackSizeMP3 = [];
    List<String> trackSizeFLAC = [];
    List<String> trackSizeOGG = [];

    Uri completedUrl = Uri.parse(baseUrl + _searchResults[index].albumLink.replaceAll(baseUrl, ""));

    //debugPrint(completed_url.toString());

    AlbumTags toPush = AlbumTags(tracks, trackDuration, "Null", albumLink, trackURL, coverURL, false, false, false,
        tags, trackSizeMP3, trackSizeFLAC, trackSizeOGG);

    http.read(completedUrl).then((contents) {
      BeautifulSoup bs = BeautifulSoup(contents);

      for (var element in bs.findAll('img')) {
        var imgurl = element['src'];
        //debugPrint(imgurl);
        if (imgurl!.startsWith("/album_views.php")) {
          coverURL.add("https://i.ibb.co/cgRJ97N/unknown.png");
        } else {
          coverURL.add(element['src']!);
        }
      }

      var link = bs.find('', id: 'songlist');

      for (var row in link!.findAll('tbody')) {
        debugPrint("row");
        for (var col in row.findAll('tr')) {
          if (col.id != "") {
            debugPrint("COL-ID: " + col.id);
          }
          if (col.id == "songlist_header" || col.id == "songlist_footer") {
            for (var tag in col.findAll('th')) {
              tags.add(tag.text);
            }
            debugPrint('TAGS: ' + tags.toString());

            flac = tags.contains('FLAC');
            mp3 = tags.contains('MP3');
            ogg = tags.contains('OGG');
            continue;
          }

          List<String> temptag = [];

          var songname = tags.indexOf('Song Name');

          for (var title in col.findAll('td')) {
            temptag.add(title.text);
            if (title.find('a') != null) {
              var titleurl = title.find('a')!.attributes['href'];

              if ((titleurl != "" || titleurl != null) && !trackURL.contains(titleurl)) {
                trackURL.add(titleurl!);
              }
            }
          }

          if (temptag.length == tags.length + 1) {
            trackDuration.add(temptag[songname + 1]);
            tracks.add(temptag[songname]);

            if (mp3) {
              trackSizeMP3.add(temptag[tags.indexOf('MP3') + 1]);
            }
            if (flac) {
              trackSizeFLAC.add(temptag[tags.indexOf('FLAC') + 1]);
            }
            if (ogg) {
              trackSizeOGG.add(temptag[tags.indexOf('OGG') + 1]);
            }
          }
        }
      }

      toPush = AlbumTags(tracks, trackDuration, albumName, albumLink, trackURL, coverURL, mp3, flac, ogg, tags,
          trackSizeMP3, trackSizeFLAC, trackSizeOGG);

      debugPrint("Final: " + toPush.albumName);
      if (toPush.albumName != "Null") {
        busy = false;
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => AlbumView(
                    tags: toPush,
                  )),
        );
      } else {
        busy = false;
        debugPrint("error");
      }
      //debugPrint(toPush.coverURL.toString());
    });
    /**/
  }

  /*bool foundInFavorites(AlbumStruct element) {
    for (var fav in favorites) {
      if (fav.albumName == element.albumName && fav.albumLink == element.albumLink) {
        return true;
      }
    }
    return false;
  }

  int locateInFavorites(AlbumStruct element) {
    for (var i = 0; i < favorites.length; i++) {
      if (favorites[i].albumName == element.albumName && favorites[i].albumLink == element.albumLink) {
        return i;
      }
    }
    return -1;
  }*/

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

      if (searchResults.contains(AlbumStruct(resultName, redirectUri.toString()))) {
        return;
      }

      searchResults.add(AlbumStruct(resultName, redirectUri.toString()));

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
        var link = bs.find('', id: 'EchoTopic');

        for (var row in link!.findAll('p')) {
          for (var col in row.findAll('a')) {
            if (col['href']!.contains("game-soundtracks/browse/") || col['href']!.contains("/forums/")) {
              continue;
            }
            if (col['href']!.contains("game-soundtracks/browse/")) {
              continue;
            }

            String colContent = col.text;
            String colHref = col['href']!;

            searchResults.add(AlbumStruct(colContent, colHref));
          }
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
      bodyDisplay = emptySearch();
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
                return Card(
                    shape: cardShape,
                    child: InkWell(
                      splashColor: Colors.accents.first,
                      mouseCursor: MouseCursor.uncontrolled,
                      onTap: () {
                        debugPrint("Tapped " + _searchResults[index].albumName);
                        goToAlbum(context, index);
                      },
                      child: Column(
                        children: [
                          ListTile(
                            trailing: IconButton(
                              icon: foundInFavorites(searchResults[index])
                                  ? const Icon(Icons.star)
                                  : const Icon(Icons.star_border),
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
                        ],
                      ),
                    ));
              }) /**/
          );
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
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      splashRadius = 1.0;
    }

    List<Widget> actions = [
            if (!favoriteHome)
              IconButton(
                splashRadius: splashRadius,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FavoriteHome(
                                  title: 'Favorites',
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
              if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) const WindowButtons()
          ];

    Widget searchBox = Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(color: colorSearch, borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: TextField(
                onSubmitted: (term) async {
                  searchPressed(term);
                },
                controller: fieldText,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      splashRadius: splashRadius,
                      icon: const Icon(Icons.clear, size: 17.0,),
                      onPressed: () {
                        fieldText.clear();
                      },
                    ),
                    hintText: 'Search for OSTs',
                    border: InputBorder.none),
              ),
            ),
          );

    AppBar? searchAppBar = AppBar(
          // The search area here
          title: searchBox
          actions: actions
        );
    
    String titleAppBar = "Search";
    double? heightTitleBar = 40.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    double? widthOfBorder;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      searchAppBar = null;
    } else if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      widthOfBorder = 0.0;
    }

    return Scaffold(
        //appBar: searchAppBar,
        body: WindowBorder(
          width: widthOfBorder,
            color: Theme.of(context).backgroundColor,
            child: Column(children: [
              if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux))
                SizedBox(
                    child: Container(
                        color: Theme.of(context).cardColor,
                        child: Row(
                          children: [ 
                            if (Platform.isMacOS) const SizedBox(width: 60),
                            if (favoriteHome && windowBorder) IconButton(splashRadius: splashRadius, icon: const Icon(Icons.navigate_before), onPressed: () {
                              Navigator.pop(context);
                            }
                          ),
                                Expanded(child: SizedBox(height: heightTitleBar, child: MoveWindow(child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
                                  child: Text(titleAppBar, style: Theme.of(context).textTheme.headline6, textAlign: TextAlign.center,),
                                ),))),
                                if (windowBorder) Expanded(child: searchBox)
                              ]
                        ))),
              if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder && searchAppBar != null)
                searchAppBar,
              Expanded(child: bodyDisplay)
            ])));
  }
}
