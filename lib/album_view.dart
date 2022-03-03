import 'dart:io';

import 'package:flutter/material.dart';
import 'package:khinrip/downloading_view.dart';
import 'package:khinrip/favorite_view.dart';
import 'package:khinrip/track_list.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class AlbumView extends StatefulWidget {
  const AlbumView({Key? key, required this.tags}) : super(key: key);

  final AlbumTags tags;

  @override
  // ignore: no_logic_in_create_state
  _AlbumViewState createState() => _AlbumViewState(tags: tags);
}

// The small cell at the top containing the album information
Widget albumView(AlbumTags tags) {
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
      child: Row(children: [
    Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: const Color.fromRGBO(71, 71, 71, 0.2),
            image: DecorationImage(
                fit: BoxFit.contain, image: NetworkImage(tags.coverURL[0])))),
    Expanded(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
          child: SizedBox(
            height: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Marquee(
                    child: Text(tags.albumName,
                        style: const TextStyle(fontSize: 20))),
                Marquee(
                    child: Text(tags.albumLink,
                        style: const TextStyle(color: Colors.grey))),
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomRight,
                    child: Text("Available Formats: " + availableAddon,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                )
              ],
            ),
          )),
      flex: 2,
    ),
    IconButton(
        onPressed: () async {
          await launch(tags.albumLink);
        },
        icon: const Icon(Icons.open_in_browser))
  ]));
}

class _AlbumViewState extends State<AlbumView> {
  final AlbumTags tags;

  bool isExpanded = false;

  _AlbumViewState({required this.tags});

  void showDownloadModal(bool isPopUp) {
    if (!isPopUp) {
      showModalBottomSheet<String>(
        builder: (BuildContext context) {
          return Wrap(children: [
            Card(
                child: ListTile(
              title: const Text("Download Album"),
              subtitle: Text(downloadText),
            )),
            Container(height: 30, color: Colors.transparent),
            Container(
              height: 20,
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
              alignment: Alignment.bottomLeft,
              child: const Text(
                "Formats",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            if (tags.mp3)
              Card(
                  child: InkWell(
                      onTap: () => Navigator.pop(context, 'mp3'),
                      child: const ListTile(
                        leading: Icon(Icons.download_rounded),
                        title: Text("Download in MP3"),
                      ))),
            if (tags.flac)
              Card(
                  child: InkWell(
                      onTap: () => Navigator.pop(context, 'flac'),
                      child: const ListTile(
                        leading: Icon(Icons.download_rounded),
                        title: Text("Download in FLAC"),
                      ))),
            if (tags.ogg)
              Card(
                  child: InkWell(
                      onTap: () => Navigator.pop(context, 'ogg'),
                      child: const ListTile(
                        leading: Icon(Icons.download_rounded),
                        title: Text("Download in OGG"),
                      ))),
            Card(
                child: InkWell(
              child: const ListTile(
                leading: Icon(Icons.cancel_outlined),
                title: Text("Cancel"),
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
            MaterialPageRoute(
                builder: (context) => DownloadingView(tags: tags, type: value)),
          );

          //downloadAlbum(tags, value);
        }
      });
    } else {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: const Text('Download Album'),
            content: Text(downloadText),
            actions: getButtons(tags)),
      ).then((value) {
        if (value != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DownloadingView(tags: tags, type: value)),
          );

          //downloadAlbum(tags, value);
        }
      });
    }
  }

  Widget favCell(AlbumTags tags) {
    // the add/remove from favorites cell/button.
    if (foundInFavorites(
        // if album being viewed is in favorites, show remove button
        AlbumStruct(tags.albumName, tags.albumLink.replaceAll(baseUrl, "")))) {
      return SizedBox(
          child: Card(
              child: InkWell(
                  onTap: (() {
                    favorites.removeAt(locateInFavorites(AlbumStruct(
                        tags.albumName,
                        tags.albumLink.replaceAll(baseUrl, ""))));
                    setState(() {
                      saveFavs();
                      favUpdater.value += 1;
                    });
                  }),
                  child: const ListTile(
                    title: Text("Remove from Favorites"),
                    trailing: Icon(Icons.chevron_right),
                    leading: Icon(Icons.star_rounded),
                  ))));
    } else {
      // if not, show the add button
      return SizedBox(
          child: Card(
              child: InkWell(
                  onTap: (() {
                    favorites.add(AlbumStruct(tags.albumName,
                        tags.albumLink.replaceAll(baseUrl, "")));
                    setState(() {
                      saveFavs();
                      favUpdater.value += 1;
                    });
                  }),
                  child: const ListTile(
                    title: Text("Add to Favorites"),
                    trailing: Icon(Icons.chevron_right),
                    leading: Icon(Icons.star_outline_rounded),
                  ))));
    }
  }

  List<Widget> getButtons(AlbumTags tags) {
    // gets the available formats for the download alert and returns a widget list with options
    return <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context, null),
        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
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
    downloadText = tags.albumName;
    if (pathToSaveIn == "" && Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux) {
      downloadText =
          "Warning: No saving path specified! Using the programs' directory.\n" +
              tags.albumName;
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        albumView(tags),
        Container(height: 30, color: Colors.transparent),
        Container(
          height: 20,
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          alignment: Alignment.bottomLeft,
          child: const Text(
            "Options",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        favCell(tags),
        SizedBox(
            // download album button
            child: Card(
                child: InkWell(
                    onTap: () {
                      showDownloadModal(isPopUp);
                    },
                    child: const ListTile(
                      title: Text("Download all Tracks"),
                      trailing: Icon(Icons.chevron_right),
                      leading: Icon(Icons.download_rounded),
                    )))),
        Container(height: 30, color: Colors.transparent), // little spacer
        Container(
          // spacer/category text
          height: 20,
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          alignment: Alignment.bottomLeft,
          child: Text(
            "Tracks: " + tags.tracks.length.toString(),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Container(
            padding: EdgeInsets.zero,
            child: Card(
                // view all tracks button
                child: InkWell(
                    mouseCursor: MouseCursor.uncontrolled,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TrackView(
                                  tags: tags,
                                )),
                      );
                    },
                    child: const ListTile(
                      title: Text("View all Tracks"),
                      leading: Icon(Icons.view_list_rounded),
                      trailing: Icon(Icons.chevron_right),
                    )))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPopup = true;

    if (popupStyle == 0) {
      isPopup = !(MediaQuery.of(context).size.width < 400);
    } else if (popupStyle == 1) {
      isPopup = true;
    } else if (popupStyle == 2) {
      isPopup = false;
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text("Album Details"),
        ),
        body: buildAlbumScreen(context, tags, isPopup));
  }
}
