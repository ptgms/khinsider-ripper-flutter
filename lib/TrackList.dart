import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/download_utils.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TrackView extends StatefulWidget {
  const TrackView({Key? key, required this.tags}) : super(key: key);

  final AlbumTags tags;

  @override
  _TrackViewState createState() => _TrackViewState(tags: tags);
}

class _TrackViewState extends State<TrackView> {
  final AlbumTags tags;

  String playingURL = "";

  AudioPlayer audioPlayer = AudioPlayer();

  Dialog previewDialog(AlbumTags tags, int index) {
    debugPrint(tags.trackURL[index]);

    if (playingURL != "") {
      audioPlayer.setUrl(playingURL);
      audioPlayer.resume();
    }
    audioPlayer.setReleaseMode(ReleaseMode.STOP);

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0)), //this right here
      child: Container(
        height: 300.0,
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 150,
              height: 150,
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Image(
                  image: NetworkImage(tags.coverURL[0]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
              child: Marquee(child: Text(tags.tracks[index])),
            ),
            /*
            Padding(
              padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: LinearProgressIndicator(value: 0.2),
            ),*/
            /*Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text("00:00:00")),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                        alignment: Alignment.centerRight,
                        child: Text("00:00:00")),
                  )
                ],
              ),
            ),*/
            Padding(padding: EdgeInsets.only(top: 10.0)),
            IconButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await audioPlayer.stop();
                },
                icon: Icon(Icons.stop))
          ],
        ),
      ),
    );
  }

  _TrackViewState({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Tracks"),
        ),
        body: ListView.builder(
            itemCount: tags.tracks.length,
            itemBuilder: ((context, index) {
              return SizedBox(
                  height: 55,
                  child: Card(
                      child: InkWell(
                          onTap: () async {
                            if (Platform.isMacOS ||
                                Platform.isAndroid ||
                                Platform.isIOS) {
                              Uri completedUrl =
                                  Uri.parse(baseUrl + tags.trackURL[index]);

                              await http.read(completedUrl).then((contents) {
                                BeautifulSoup bs = BeautifulSoup(contents);

                                var Element = bs.find('', id: 'EchoTopic')!;

                                for (var link in Element.findAll('a')) {
                                  if (link.attributes['href'] != null) {
                                    if (link.attributes['href']!
                                        .endsWith(".mp3")) {
                                      playingURL = link.attributes['href']!;
                                    } else if (link.attributes['href']!
                                        .endsWith(".ogg")) {
                                      playingURL = link.attributes['href']!;
                                    }
                                  }
                                }
                              });
                              await showDialog(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      previewDialog(tags, index));
                              debugPrint("dismissed");
                              audioPlayer.stop();
                              playingURL = "";
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor:
                                    const Color.fromARGB(255, 201, 96, 61),
                                content: const Text(
                                    'Due to technical limitations in your platform, the preview player is not yet available.'),
                                action: SnackBarAction(
                                    textColor: Colors.white,
                                    label: 'Preview in Browser instead',
                                    onPressed: () async {
                                      Uri completedUrl = Uri.parse(
                                          baseUrl + tags.trackURL[index]);

                                      await http
                                          .read(completedUrl)
                                          .then((contents) {
                                        BeautifulSoup bs =
                                            BeautifulSoup(contents);

                                        var Element =
                                            bs.find('', id: 'EchoTopic')!;

                                        for (var link in Element.findAll('a')) {
                                          if (link.attributes['href'] != null) {
                                            if (link.attributes['href']!
                                                .endsWith(".mp3")) {
                                              playingURL =
                                                  link.attributes['href']!;
                                            } else if (link.attributes['href']!
                                                .endsWith(".ogg")) {
                                              playingURL =
                                                  link.attributes['href']!;
                                            }
                                          }
                                        }
                                      });
                                      await launch(playingURL);
                                      playingURL = "";
                                    }),
                              ));
                            }
                          },
                          child: Row(
                            children: [
                              Container(
                                  width: 55,
                                  height: 55,
                                  alignment: Alignment.center,
                                  child: Text((index + 1).toString())),
                              Expanded(
                                child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Marquee(
                                            child: Text(tags.tracks[index],
                                                style: const TextStyle(
                                                    fontSize: 16))),
                                        Marquee(
                                            child: Text(tags.trackURL[index],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)))
                                      ],
                                    )),
                                flex: 2,
                              ),
                              IconButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      dismissDirection: DismissDirection.none,
                                      //duration: const Duration(seconds: 30),
                                      content: Text(
                                          "Please wait, downloading to $pathToSaveIn..."),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                    downloadFile(tags, index, 'mp3');
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text("Saved to $pathToSaveIn!"),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  },
                                  icon: const Icon(Icons.download_rounded))
                            ],
                          ))));
            })));
  }
}
