import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/download_utils.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:native_context_menu/native_context_menu.dart';
import 'package:share_plus/share_plus.dart';

import 'main.dart';

class TrackView extends StatefulWidget {
  const TrackView({Key? key, required this.tags}) : super(key: key);

  final AlbumTags tags;

  @override
  // ignore: no_logic_in_create_state
  _TrackViewState createState() => _TrackViewState(tags: tags);
}

class _TrackViewState extends State<TrackView> {
  final AlbumTags tags;

  String playingURL = "";
  var busy = false;

  List<Widget> getButtons(AlbumTags tags, int index) {
    return <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context, null),
        child: const Text('Cancel', style: TextStyle(color: Colors.red)),
      ),
      if (tags.mp3)
        TextButton(
          onPressed: () => Navigator.pop(context, 'mp3'),
          child: Text('MP3 (' + tags.trackSizeMP3[index] + ')'),
        ),
      if (tags.flac)
        TextButton(
          onPressed: () => Navigator.pop(context, 'flac'),
          child: Text('FLAC (' + tags.trackSizeFLAC[index] + ')'),
        ),
      if (tags.ogg)
        TextButton(
          onPressed: () => Navigator.pop(context, 'ogg'),
          child: Text('OGG (' + tags.trackSizeOGG[index] + ')'),
        ),
    ];
  }

  AudioPlayer audioPlayer = AudioPlayer();

  Dialog previewDialog(AlbumTags tags, int index) {
    debugPrint(tags.trackURL[index]);

    if (playingURL != "") {
      audioPlayer.setUrl(playingURL);
      audioPlayer.resume();
    }
    audioPlayer.setReleaseMode(ReleaseMode.STOP);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: SizedBox(
        height: 300.0,
        width: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 150,
              height: 150,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Image(
                  image: NetworkImage(tags.coverURL[0]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
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
            const Padding(padding: EdgeInsets.only(top: 10.0)),
            IconButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await audioPlayer.stop();
                },
                icon: const Icon(Icons.stop))
          ],
        ),
      ),
    );
  }

  _TrackViewState({required this.tags});

  String getSnackBarContent(String pathToSaveIn) {
    if (Platform.isAndroid) {
      if (pathToSaveIn != "" && pathToSaveIn != "/storage/emulated/0/Download") {
        return "Saved to $pathToSaveIn!";
      }
      return "Saved to Downloads!";
    } else if (Platform.isIOS) {
      return "Saved to Files App!";
    } else {
      return "Saved to $pathToSaveIn!";
    }
  }

  Future<void> downloadSong(int index, String value) async {
    if (busy) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      dismissDirection: DismissDirection.none,
      //duration: const Duration(seconds: 30),
      content: Text("Please wait, downloading..."),
      behavior: SnackBarBehavior.floating,
    ));
    await downloadFile(tags, index, value);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(getSnackBarContent(pathToSaveIn)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(getRoundedValue()));

    String downloadText = "";
    if (pathToSaveIn == "" && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      downloadText = "Warning: No saving path specified! Using the programs' directory.\n";
    }

    bool isPopup = true;

    if (popupStyle == 0) {
      isPopup = !(MediaQuery.of(context).size.width < 400);
    } else if (popupStyle == 1) {
      isPopup = true;
    } else if (popupStyle == 2) {
      isPopup = false;
    }

    void showDownloadPopup(int index) {
      if (!isPopup) {
        showModalBottomSheet<String>(
          shape: cardShape,
          builder: (BuildContext context) {
            return Wrap(children: [
              Card(
                  shape: cardShape,
                  child: ListTile(
                    title: const Text("Download song"),
                    subtitle: Text(downloadText + tags.tracks[index]),
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
                    shape: cardShape,
                    child: InkWell(
                        onTap: () => Navigator.pop(context, 'mp3'),
                        child: ListTile(
                          leading: const Icon(Icons.download_rounded),
                          title: const Text("Download in MP3"),
                          subtitle: Text(tags.trackSizeMP3[index]),
                        ))),
              if (tags.flac)
                Card(
                    shape: cardShape,
                    child: InkWell(
                        onTap: () => Navigator.pop(context, 'flac'),
                        child: ListTile(
                          leading: const Icon(Icons.download_rounded),
                          title: const Text("Download in FLAC"),
                          subtitle: Text(tags.trackSizeFLAC[index]),
                        ))),
              if (tags.ogg)
                Card(
                    shape: cardShape,
                    child: InkWell(
                        onTap: () => Navigator.pop(context, 'ogg'),
                        child: ListTile(
                          leading: const Icon(Icons.download_rounded),
                          title: const Text("Download in OGG"),
                          subtitle: Text(tags.trackSizeOGG[index]),
                        ))),
              Card(
                  shape: cardShape,
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
            downloadSong(index, value);
          }
        });
      } else {
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
              title: const Text('Download song'), content: Text(tags.tracks[index]), actions: getButtons(tags, index)),
        ).then((value) {
          if (value != null) {
            downloadSong(index, value);
          }
        });
      }
    }

    Widget trackItem(int index) {
      return InkWell(
          customBorder: cardShape,
          onLongPress: () {
            if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
              showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                      title: Text(tags.tracks[index]),
                      content: SizedBox(
                        height: 224,
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.ios_share_rounded),
                              title: const Text('Share Track'),
                              onTap: () {
                                Navigator.of(context).pop();
                                Share.share("Check out this Song '" +
                                    tags.tracks[index] +
                                    "' on Khinsider!\n" +
                                    baseUrl +
                                    tags.trackURL[index]);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.download_rounded),
                              title: const Text('Download Track'),
                              onTap: () {
                                Navigator.of(context).pop();
                                showDownloadPopup(index);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.open_in_browser_rounded),
                              title: const Text('Open in Browser'),
                              onTap: () {
                                Navigator.of(context).pop();
                                launch(baseUrl + tags.trackURL[index]);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.copy_rounded),
                              title: const Text("Copy URL"),
                              onTap: () {
                                Navigator.of(context).pop();
                                Clipboard.setData(ClipboardData(text: baseUrl + tags.trackURL[index]));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  dismissDirection: DismissDirection.none,
                                  duration: Duration(seconds: 1),
                                  content: Text("Copied URL to clipboard!"),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              },
                            )
                          ],
                        ),
                      )));
            }
          },
          onTap: () async {
            if (trackListBehavior == 0 && (Platform.isMacOS || Platform.isAndroid || Platform.isIOS)) {
              if (!busy) {
                busy = true;
                Uri completedUrl = Uri.parse(baseUrl + tags.trackURL[index]);

                await http.read(completedUrl).then((contents) {
                  BeautifulSoup bs = BeautifulSoup(contents);

                  var element = bs.find('', id: 'EchoTopic')!;

                  for (var link in element.findAll('a')) {
                    if (link.attributes['href'] != null) {
                      if (link.attributes['href']!.endsWith(".mp3")) {
                        playingURL = link.attributes['href']!;
                      } else if (link.attributes['href']!.endsWith(".ogg")) {
                        playingURL = link.attributes['href']!;
                      }
                    }
                  }
                });

                await showDialog(context: context, builder: (BuildContext context) => previewDialog(tags, index));
                debugPrint("dismissed");
                audioPlayer.stop();
                playingURL = "";
                busy = false;
              }
            } else if ((Platform.isWindows && trackListBehavior == 0) || trackListBehavior == 1) {
              Uri completedUrl = Uri.parse(baseUrl + tags.trackURL[index]);

              await http.read(completedUrl).then((contents) {
                BeautifulSoup bs = BeautifulSoup(contents);

                var element = bs.find('', id: 'EchoTopic')!;

                for (var link in element.findAll('a')) {
                  if (link.attributes['href'] != null) {
                    if (link.attributes['href']!.endsWith(".mp3")) {
                      playingURL = link.attributes['href']!;
                    } else if (link.attributes['href']!.endsWith(".ogg")) {
                      playingURL = link.attributes['href']!;
                    }
                  }
                }
              });
              await launch(playingURL);
              playingURL = "";
            } else if (trackListBehavior == 2) {
              showDownloadPopup(index);
            }
          },
          child: Row(
            children: [
              Container(width: 55, height: 55, alignment: Alignment.center, child: Text((index + 1).toString())),
              Expanded(
                child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(child: Text(tags.tracks[index], style: const TextStyle(fontSize: 16))),
                        Marquee(
                            child: Text(tags.trackURL[index], style: const TextStyle(fontSize: 12, color: Colors.grey)))
                      ],
                    )),
                flex: 2,
              ),
              if (trackListBehavior != 2)
                IconButton(
                    onPressed: () async {
                      showDownloadPopup(index);
                    },
                    icon: const Icon(Icons.download_rounded))
            ],
          ));
    }

    String titleAppBar = "Tracks";
    double? heightTitleBar = 40.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
      titleAppBar = "";
      heightTitleBar = 30.0;
    }
    double splashRadius = 35.0;
    if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
      splashRadius = 1.0;
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      AppBar? trackListAppBar = AppBar(
        title: const Text("Tracks"),
      );

      AppBar? display = trackListAppBar;

      if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        display = null;
      }

      double? widthOfBorder;
      if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && windowBorder) {
        trackListAppBar = null;
      } else if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) && !windowBorder) {
        widthOfBorder = 0.0;
      }
      return Scaffold(
          appBar: display,
          body: WindowBorder(
              width: widthOfBorder,
              color: Theme.of(context).backgroundColor,
              child: Column(children: [
                if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux))
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
                if ((Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
                    !windowBorder &&
                    trackListAppBar != null)
                  trackListAppBar,
                Expanded(
                    child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        itemCount: tags.tracks.length,
                        itemBuilder: ((context, index) {
                          return SizedBox(
                              height: 55,
                              child: Card(
                                  shape: cardShape,
                                  child: ContextMenuRegion(
                                      onItemSelected: ((item) {
                                        switch (item.title) {
                                          case "Download Track":
                                            showDownloadPopup(index);
                                            break;
                                          case "Open in Browser":
                                            launch(baseUrl + tags.trackURL[index]);
                                            break;
                                          case "Copy URL":
                                            Clipboard.setData(ClipboardData(text: baseUrl + tags.trackURL[index]));
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                              dismissDirection: DismissDirection.none,
                                              duration: Duration(seconds: 1),
                                              content: Text("Copied URL to clipboard!"),
                                              behavior: SnackBarBehavior.floating,
                                            ));
                                            break;
                                          default:
                                            break;
                                        }
                                      }),
                                      menuItems: [
                                        MenuItem(title: "Download Track"),
                                        MenuItem(title: "Open in Browser"),
                                        MenuItem(title: "Copy URL"),
                                      ],
                                      child: trackItem(index))));
                        })))
              ])));
    } else {
      return Scaffold(
          appBar: AppBar(
            title: const Text("Tracks"),
          ),
          body: ListView.builder(
              itemCount: tags.tracks.length,
              itemBuilder: ((context, index) {
                return SizedBox(height: 55, child: Card(shape: cardShape, child: trackItem(index)));
              })));
    }
  }
}
