import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:khinrip/downloading_view.dart';
import 'package:khinrip/favorite_view.dart';
import 'package:khinrip/main.dart';
import 'package:khinrip/track_list.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AlbumView extends StatefulWidget {
  const AlbumView({Key? key, required this.tags}) : super(key: key);

  final AlbumTags tags;

  @override
  // ignore: no_logic_in_create_state
  _AlbumViewState createState() => _AlbumViewState(tags: tags);
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

  Widget noPicFound = const Icon(Icons.album);
    Decoration albumImage = const BoxDecoration();
    if (tags.coverURL[0] != "none" && tags.coverURL[0] != "") {
      noPicFound = Container();
      albumImage = BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(getRoundedValue())),
              color: const Color.fromRGBO(71, 71, 71, 0.2),
              image: DecorationImage(fit: BoxFit.contain, image: NetworkImage(tags.coverURL[0])));
    }

  return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue())),
      child: Row(children: [
        Container(
            width: 100,
            height: 100,
            decoration: albumImage,
            child: noPicFound),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Marquee(child: Text(tags.albumName, style: const TextStyle(fontSize: 20))),
                    Marquee(child: Text(tags.albumLink, style: const TextStyle(color: Colors.grey))),
                    Expanded(
                      child: Container(
                        alignment: Alignment.bottomRight,
                        child: Text(t.availableFormats(availableAddon),
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    )
                  ],
                ),
              )),
          flex: 2,
        ),
        IconButton(
            onPressed: () async {
              await launchUrl(Uri.parse(tags.albumLink));
            },
            icon: const Icon(Icons.open_in_browser))
      ]));
}

class _AlbumViewState extends State<AlbumView> {
  final AlbumTags tags;

  bool isExpanded = false;

  ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));

  _AlbumViewState({required this.tags});

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
                      child:  ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: Text(t.downloadIn("FLAC")),
                      ))),
            if (tags.ogg)
              Card(
                  shape: cardShape,
                  child: InkWell(
                      customBorder: cardShape,
                      onTap: () => Navigator.pop(context, 'ogg'),
                      child:  ListTile(
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
                    title: Text(t.removeFromFavs),
                    trailing: const Icon(Icons.chevron_right),
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
                    favorites.add(AlbumStruct(tags.albumName, tags.albumLink.replaceAll(baseUrl, ""), tags.coverURL[0]));
                    setState(() {
                      saveFavs();
                      favUpdater.value += 1;
                    });
                  }),
                  child: ListTile(
                    title: Text(t.addToFavs),
                    trailing: const Icon(Icons.chevron_right),
                    leading: const Icon(Icons.star_outline_rounded),
                  ))));
    }
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

  Widget buildAlbumScreen(BuildContext context, AlbumTags tags, bool isPopUp) {
    var t = AppLocalizations.of(context)!;
    downloadText = tags.albumName;
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));
    if (pathToSaveIn == "" && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      downloadText = t.noDefaultPath + tags.albumName;
    }
    debugPrint(pathToSaveIn);
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        albumView(tags, context),
        Container(height: 30, color: Colors.transparent),
        Container(
          height: 20,
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          alignment: Alignment.bottomLeft,
          child: Text(
            t.options,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        favCell(tags, context),
        SizedBox(
            // download album button
            child: Card(
                shape: cardShape,
                child: InkWell(
                    customBorder: cardShape,
                    onTap: () {
                      showDownloadModal(isPopUp, context);
                    },
                    child: ListTile(
                      title: Text(t.downloadAllTracks),
                      trailing: const Icon(Icons.chevron_right),
                      leading: const Icon(Icons.download_rounded),
                    )))),
        Container(height: 30, color: Colors.transparent), // little spacer
        Container(
          // spacer/category text
          height: 20,
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          alignment: Alignment.bottomLeft,
          child: Text(
            t.viewAllTracks + ": " + tags.tracks.length.toString(),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Container(
            padding: EdgeInsets.zero,
            child: Card(
                shape: cardShape,
                // view all tracks button
                child: InkWell(
                    customBorder: cardShape,
                    mouseCursor: MouseCursor.uncontrolled,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrackView(
                                  tags: tags, width: 400.0
                                )),
                      );
                    },
                    child: ListTile(
                      title: Text(t.viewAllTracks),
                      leading: const Icon(Icons.view_list_rounded),
                      trailing: const Icon(Icons.chevron_right),
                    )))),
      ],
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
              if ((Platform.isMacOS || Platform.isLinux) &&
                  !windowBorder &&
                  albumViewAppBar != null)
                albumViewAppBar,
              Expanded(child: buildAlbumScreen(context, tags, isPopup))
            ])));
  }
}
