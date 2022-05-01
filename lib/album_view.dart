import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khinrip/downloading_view.dart';
import 'package:khinrip/favorite_view.dart';
import 'package:khinrip/main.dart';
import 'package:khinrip/track_list.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:palette_generator/palette_generator.dart';

class AlbumView extends StatefulWidget {
  const AlbumView({Key? key, required this.tags}) : super(key: key);

  final AlbumTags tags;

  @override
  // ignore: no_logic_in_create_state
  _AlbumViewState createState() => _AlbumViewState(tags: tags);
}

class _AlbumViewState extends State<AlbumView> {
  final AlbumTags tags;

  bool isExpanded = false;

  ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));

  _AlbumViewState({required this.tags});

  @override
  void initState() {
    if (tags.coverURL[0] != "" && tags.coverURL[0] != "none") {
      extractColor(tags.coverURL).then((value) {
        setState(() {});
      });
    }
    super.initState();
  }

  void showDownloadModal(bool isPopUp, context) {
    var t = AppLocalizations.of(context)!;
    if (!isPopUp) {
      showModalBottomSheet<String>(
        shape: cardShape,
        builder: (BuildContext context) {
          return Wrap(children: [
            Card(
                shape: cardShape,
                child: ListTile(
                  title: Text(t.downloadAlbum),
                  subtitle: Text(downloadText),
                )),
            Container(height: 30, color: Colors.transparent),
            Container(
              height: 20,
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              alignment: Alignment.bottomLeft,
              child: Text(
                t.formats,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            if (tags.mp3)
              Card(
                  shape: cardShape,
                  child: InkWell(
                      customBorder: cardShape,
                      onTap: () => Navigator.pop(context, 'mp3'),
                      child: ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: Text(t.downloadIn("MP3")),
                      ))),
            if (tags.flac)
              Card(
                  shape: cardShape,
                  child: InkWell(
                      customBorder: cardShape,
                      onTap: () => Navigator.pop(context, 'flac'),
                      child: ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: Text(t.downloadIn("FLAC")),
                      ))),
            if (tags.ogg)
              Card(
                  shape: cardShape,
                  child: InkWell(
                      customBorder: cardShape,
                      onTap: () => Navigator.pop(context, 'ogg'),
                      child: ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: Text(t.downloadIn("OGG")),
                      ))),
            Card(
                shape: cardShape,
                child: InkWell(
                  customBorder: cardShape,
                  child: ListTile(
                    leading: const Icon(Icons.cancel_outlined),
                    title: Text(t.cancel),
                  ),
                  onTap: () => Navigator.pop(context, null),
                )),
          ]);
        },
        context: context,
      ).then((value) {
        if (value != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DownloadingView(tags: tags, type: value)),
          );

          //downloadAlbum(tags, value);
        }
      });
    } else {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(title: Text(t.downloadAlbum), content: Text(downloadText), actions: getButtons(tags, context)),
      ).then((value) {
        if (value != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DownloadingView(tags: tags, type: value)),
          );

          //downloadAlbum(tags, value);
        }
      });
    }
  }

  Widget favCell(AlbumTags tags, context) {
    var t = AppLocalizations.of(context)!;
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    // the add/remove from favorites cell/button.
    if (foundInFavorites(
        // if album being viewed is in favorites, show remove button
        AlbumStruct(tags.albumName, tags.albumLink.replaceAll(baseUrl, ""), ""))) {
      return SizedBox(
          child: Card(
              shape: cardShape,
              child: InkWell(
                  customBorder: cardShape,
                  onTap: (() {
                    favorites.removeAt(
                        locateInFavorites(AlbumStruct(tags.albumName, tags.albumLink.replaceAll(baseUrl, ""), "")));
                    setState(() {
                      saveFavs();
                      favUpdater.value += 1;
                    });
                  }),
                  child: ListTile(
                    minLeadingWidth: 8,
                    title: Text(t.removeFromFavs),
                    leading: const Icon(Icons.star_rounded),
                  ))));
    } else {
      // if not, show the add button
      return SizedBox(
          child: Card(
              shape: cardShape,
              child: InkWell(
                  customBorder: cardShape,
                  onTap: (() {
                    favorites
                        .add(AlbumStruct(tags.albumName, tags.albumLink.replaceAll(baseUrl, ""), tags.coverURL[0]));
                    setState(() {
                      saveFavs();
                      favUpdater.value += 1;
                    });
                  }),
                  child: ListTile(
                    minLeadingWidth: 8,
                    title: Text(t.addToFavs),
                    // trailing: const Icon(Icons.chevron_right),
                    leading: const Icon(Icons.star_outline_rounded),
                  ))));
    }
  }

  Widget downloadCell(isPopUp, t) {
    return SizedBox(
        // download album button
        child: Card(
            shape: cardShape,
            child: InkWell(
                customBorder: cardShape,
                onTap: () {
                  showDownloadModal(isPopUp, context);
                },
                child: ListTile(
                  minLeadingWidth: 8,
                  title: Text(t.downloadAllTracks),
                  leading: const Icon(Icons.download_rounded),
                ))));
  }

  List<Widget> getButtons(AlbumTags tags, context) {
    var t = AppLocalizations.of(context)!;
    // gets the available formats for the download alert and returns a widget list with options
    return <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context, null),
        child: Text(t.cancel, style: const TextStyle(color: Colors.red)),
      ),
      if (tags.mp3)
        TextButton(
          onPressed: () => Navigator.pop(context, 'mp3'),
          child: const Text('MP3'),
        ),
      if (tags.flac)
        TextButton(
          onPressed: () => Navigator.pop(context, 'flac'),
          child: const Text('FLAC'),
        ),
      if (tags.ogg)
        TextButton(
          onPressed: () => Navigator.pop(context, 'ogg'),
          child: const Text('OGG'),
        ),
    ];
  }

  String downloadText = ""; // download add-on text if no custom path specified.
  int currentCover = 0;
  int _current = 0;
  final CarouselController _controller = CarouselController();
  Color stockAlbumColor = const Color.fromRGBO(71, 71, 71, 0.2);
  List<Color> albumCardColor = [];

  Future<void> extractColor(List<String> images) async {
    for (var image in images) {
      var imgBytes = (await NetworkAssetBundle(Uri.parse(image)).load(image)).buffer.asUint8List();
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImage(await decodeImageFromList(imgBytes));
      albumCardColor.add(paletteGenerator.dominantColor!.color);
    }
  }

  Widget albumCover(AlbumTags tags, context) {
    Widget albumBuild = Container();
    Decoration albumImage = const BoxDecoration();
    if (tags.coverURL[0] != "none" && tags.coverURL[0] != "") {
      if (tags.coverURL.length == 1) {
        albumImage = BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(getRoundedValue())),
            color: const Color.fromRGBO(71, 71, 71, 0.2),
            image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(tags.coverURL[currentCover])));
        albumBuild = AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              decoration: albumImage,
            ));
      } else {
        albumBuild = ShaderMask(
          shaderCallback: (Rect rect) {
            return const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
              stops: [0.0, 0.1, 0.9, 1.0], // 10% purple, 80% transparent, 10% purple
            ).createShader(rect);
          },
          blendMode: BlendMode.dstOut,
          child: CarouselSlider(
            items: tags.coverURL.map((item) {
              albumImage = BoxDecoration(
                  color: albumCardColor.length != tags.coverURL.length
                      ? stockAlbumColor
                      : albumCardColor[tags.coverURL.indexOf(item)],
                  image: DecorationImage(fit: BoxFit.contain, image: NetworkImage(item)));
              return ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(getRoundedValue())),
                  child: Container(
                    color: Theme.of(context).cardColor,
                    child: Stack(
                      children: <Widget>[
                        Container(decoration: albumImage),
                        //Image.network(item, fit: BoxFit.fill),
                        Positioned(
                          bottom: 0.0,
                          left: 0.0,
                          right: 0.0,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color.fromARGB(200, 0, 0, 0), Color.fromARGB(0, 0, 0, 0)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                            child: Text(
                              'Cover #${tags.coverURL.indexOf(item) + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ));
            }).toList(),
            carouselController: _controller,
            options: CarouselOptions(
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 1.22,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                }),
          ),
        );
      }
    } else {
      albumImage = BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(getRoundedValue())),
        color: const Color.fromRGBO(71, 71, 71, 0.2),
        //image: DecorationImage(fit: BoxFit.cover, image: NetworkImage(tags.coverURL[currentCover])
      );
      albumBuild = AspectRatio(
          aspectRatio: 1 / 1,
          child: Container(
            decoration: albumImage,
            child: const Icon(
              Icons.album,
              size: 100.0,
            ),
          ));
    }

    //Widget albumCover = SizedBox(child: albumBuild, height: 400, width: 400);
    return Center(
        child: Container(
            constraints: BoxConstraints(maxWidth: 400, maxHeight: MediaQuery.of(context).size.height / 1.5),
            child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue())),
                child: albumBuild)));
  }

  Widget albumDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tags.coverURL.asMap().entries.map((entry) {
        return GestureDetector(
          onTap: () => _controller.animateToPage(entry.key),
          child: Container(
            width: 12.0,
            height: 12.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                    .withOpacity(_current == entry.key ? 0.9 : 0.4)),
          ),
        );
      }).toList(),
    );
  }

// The small cell at the top containing the album information
  Widget albumView(AlbumTags tags, context) {
    var t = AppLocalizations.of(context)!;
    String availableAddon = ""; // Building the String for "Available formats"

    if (tags.mp3) {
      availableAddon += "MP3 ";
    }
    if (tags.flac) {
      availableAddon += "FLAC ";
    }
    if (tags.ogg) {
      availableAddon += "OGG ";
    }

    return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue())),
        child: Row(children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: SizedBox(
                  //height: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Marquee(child: Text(tags.albumName, style: const TextStyle(fontSize: 20))),
                      Marquee(child: Text(tags.albumLink, style: const TextStyle(color: Colors.grey))),
                      const SizedBox(width: 200, child: Divider()),
                      Text(t.availableFormats(availableAddon),
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )),
            flex: 2,
          ),
        ]));
  }

  Widget albumOptions(AlbumTags tags, context, isPopUp, widthScreen) {
    //double width = 100;
    int widthCard = 170;

    int heightCard = 60;

    if (widthScreen < widthCard) {
      widthCard = widthScreen.toInt() - 1;
    }

    int count = widthScreen ~/ widthCard;

    if (count > 2) {
      count = 2;
    }

    widthCard = widthScreen ~/ count;

    //debugPrint(count.toString() + " - " + widthCard.toString());

    Widget albumOptions = GridView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          childAspectRatio: (widthCard / heightCard),
        ),
        children: [favCell(tags, context), downloadCell(isPopUp, AppLocalizations.of(context)!)]);

    return albumOptions;
  }

  Widget buildAlbumScreen(BuildContext context, AlbumTags tags, bool isPopUp) {
    var t = AppLocalizations.of(context)!;
    downloadText = tags.albumName;
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    if (pathToSaveIn == "" && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      downloadText = t.noDefaultPath + tags.albumName;
    }

    return Center(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          albumCover(tags, context),
          if (tags.coverURL.length > 1) albumDots(),
          Center(
            child: Container(constraints: const BoxConstraints(maxWidth: 500), child: albumView(tags, context)),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              height: 20,
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              alignment: Alignment.bottomLeft,
              child: Text(
                t.options,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    albumOptions(tags, context, isPopUp, constraints.maxWidth),
              ),
            ),
          ),
          Center(
              child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                      shape: cardShape,
                      child: InkWell(
                          customBorder: cardShape,
                          mouseCursor: MouseCursor.uncontrolled,
                          onTap: () {
                            launchUrl(Uri.parse(tags.albumLink));
                          },
                          child: ListTile(
                              title: Text(t.openInBrowser),
                              leading: const Icon(Icons.open_in_browser),
                              trailing: const Icon(Icons.chevron_right)))))),
          Container(height: 30, color: Colors.transparent), // little spacer
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              // spacer/category text
              height: 20,
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              alignment: Alignment.bottomLeft,
              child: Text(
                t.trackListView + ": " + tags.tracks.length.toString(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: isExpanded ? null : const BoxConstraints(maxWidth: 500),
              child: Card(
                  color: isExpanded ? Theme.of(context).cardColor.withAlpha(120) : Colors.transparent,
                  shadowColor: isExpanded ? null : Colors.transparent,
                  child: Column(children: [
                    Container(
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: Card(
                                shape: cardShape,
                                // view all tracks button
                                child: InkWell(
                                    customBorder: cardShape,
                                    mouseCursor: MouseCursor.uncontrolled,
                                    onTap: () {
                                      setState(() {
                                        isExpanded = !isExpanded;
                                      });
                                    },
                                    child: ListTile(
                                      title: isExpanded ? Text(t.hideAllTracks) : Text(t.viewAllTracks),
                                      leading: const Icon(Icons.view_list_rounded),
                                      trailing: isExpanded
                                          ? const Icon(Icons.arrow_upward_rounded)
                                          : const Icon(Icons.arrow_downward_rounded),
                                    ))),
                          ),
                        )),
                    Visibility(child: TrackView(tags: tags), visible: isExpanded),
                  ])),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    bool isPopup = true;

    if (popupStyle == 0) {
      isPopup = !(MediaQuery.of(context).size.width < 400);
    } else if (popupStyle == 1) {
      isPopup = true;
    } else if (popupStyle == 2) {
      isPopup = false;
    }

    String titleAppBar = t.albumView;
    double? heightTitleBar = 40.0;
    if ((Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }

    double splashRadius = 35.0;
    if ((Platform.isMacOS || Platform.isLinux) && windowBorder) {
      splashRadius = 1.0;
    }

    AppBar? albumViewAppBar = AppBar(
      title: Text(t.albumView),
    );

    AppBar? display = albumViewAppBar;

    if ((Platform.isMacOS || Platform.isLinux)) {
      display = null;
    }

    double? widthOfBorder;
    if ((Platform.isMacOS || Platform.isLinux) && windowBorder) {
      albumViewAppBar = null;
    } else if ((Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      widthOfBorder = 0.0;
    }

    if (Platform.isWindows || Platform.isAndroid || Platform.isIOS) {
      widthOfBorder = 0.0;
    }

    return Scaffold(
        appBar: display,
        body: WindowBorder(
            width: widthOfBorder,
            color: Theme.of(context).backgroundColor,
            child: Column(children: [
              if ((Platform.isMacOS || Platform.isLinux))
                SizedBox(
                    child: Container(
                        color: Theme.of(context).cardColor,
                        child: Row(children: [
                          if (Platform.isMacOS) const SizedBox(width: 60),
                          if (windowBorder)
                            IconButton(
                                splashRadius: splashRadius,
                                icon: const Icon(Icons.navigate_before),
                                onPressed: () {
                                  Navigator.pop(context);
                                }),
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
                                    ),
                                  ))),
                          const WindowButtons(),
                        ]))),
              if ((Platform.isMacOS || Platform.isLinux) && !windowBorder && albumViewAppBar != null) albumViewAppBar,
              Expanded(child: buildAlbumScreen(context, tags, isPopup))
            ])));
  }
}
