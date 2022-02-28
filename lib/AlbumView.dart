import 'package:flutter/material.dart';
import 'package:khinrip/FavoriteView.dart';
import 'package:khinrip/TrackList.dart';
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

/*Widget albumViews(AlbumTags tags) {
  return Card(
      child: Row(
    children: [
      Container(
          decoration: BoxDecoration(
              color: Colors.red,
              image: DecorationImage(
                  fit: BoxFit.fill, image: NetworkImage(tags.coverURL[0])))),
      Column(children: [
        SizedBox(
          height: 110,
          child: ListTile(
            trailing: IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                await launch(tags.AlbumLink);
              },
            ),
            title: Marquee(
                child: Text(tags.AlbumName, style: TextStyle(fontSize: 25))),
            subtitle: Marquee(
              child: Text(tags.AlbumLink, style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const <Widget>[
            Text("Available formats: FLAC MP3 OGG"),
            SizedBox(width: 8),
          ],
        )
      ])
    ],
  ));
}*/

Widget albumView(AlbumTags tags) {
  String availableAddon = "";

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
                    child: Text(tags.AlbumName,
                        style: const TextStyle(fontSize: 20))),
                Marquee(
                    child: Text(tags.AlbumLink,
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
          await launch(tags.AlbumLink);
        },
        icon: const Icon(Icons.open_in_browser))
  ]));
}

class _AlbumViewState extends State<AlbumView> {
  final AlbumTags tags;

  bool isExpanded = false;

  _AlbumViewState({required this.tags});

  Widget favCell(AlbumTags tags) {
    if (foundInFavorites(
        AlbumStruct(tags.AlbumName, tags.AlbumLink.replaceAll(baseUrl, "")))) {
      return SizedBox(
          child: Card(
              child: InkWell(
                  onTap: (() {
                    favorites.removeAt(locateInFavorites(AlbumStruct(tags.AlbumName, tags.AlbumLink.replaceAll(baseUrl, ""))));
                    setState(() {
                      saveFavs();
                    });
                  }),
                  child: const ListTile(
                    title: Text("Remove from Favorites"),
                    trailing: Icon(Icons.chevron_right),
                    leading: Icon(Icons.star_rounded),
                  ))));
    } else {
      return SizedBox(
          child: Card(
              child: InkWell(
                  onTap: (() {
                    favorites.add(AlbumStruct(tags.AlbumName, tags.AlbumLink.replaceAll(baseUrl, "")));
                    setState(() {
                      saveFavs();
                    });
                  }),
                  child: const ListTile(
                    title: Text("Add to Favorites"),
                    trailing: Icon(Icons.chevron_right),
                    leading: Icon(Icons.star_outline_rounded),
                  ))));
    }
  }

  Widget buildAlbumScreen(BuildContext context, AlbumTags tags) {
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
        const SizedBox(
            child: Card(
                child: ListTile(
          title: Text("Download all Tracks"),
          trailing: Icon(Icons.chevron_right),
          leading: Icon(Icons.download_rounded),
        ))),
        Container(height: 30, color: Colors.transparent),
        Container(
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
    return Scaffold(
        appBar: AppBar(
          title: Text(tags.AlbumName),
        ),
        body: buildAlbumScreen(context, tags));
  }
}
