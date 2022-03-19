import 'dart:io';

import 'package:flutter/material.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/download_utils.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';

// ignore: must_be_immutable
class DownloadingView extends StatefulWidget {
  AlbumTags tags;
  String type;

  DownloadingView({Key? key, required this.tags, required this.type}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _DownloadingViewState createState() =>
      // ignore: no_logic_in_create_state
      _DownloadingViewState(tags: tags, type: type);
}

int currentIndex = 0; // currently downloading song
bool busy = false; // if app already doing something async
bool cancel = false; // if user cancelled out

class _DownloadingViewState extends State<DownloadingView> {
  // goes through all tracks in album and uses function in download_utils to download each track
  Future<bool> downloadAlbum(AlbumTags tags, String type) async {
    if (!busy) {
      busy = true;

      for (var i = 0; i < tags.trackURL.length; i++) {
        if (cancel) {
          //cancel = false;
          return false;
        }
        setState(() {
          currentIndex = i;
        });
        await downloadFileFromAlbum(tags, i, type);
        if (cancel) {
          // Called again as user could have exited during await
          cancel = false;
          return false;
        }
      }
      currentIndex = 0;
      busy = false;
      Navigator.pop(context);
      return true;
    }
    return false;
  }

  // download progress
  SizedBox downloadingRightNow() {
    return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Center(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Marquee(
                      child: Text("Downloading " + tags.albumName + "...",
                          style: const TextStyle(fontSize: 25), textAlign: TextAlign.center)))),
          Center(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text(currentIndex.toString() + " / " + tags.trackURL.length.toString(),
                    textAlign: TextAlign.center)),
          ),
          Center(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: LinearProgressIndicator(value: currentIndex / tags.trackURL.length),
          ))
        ]));
  }

  AlbumTags tags;
  String type;

  _DownloadingViewState({required this.tags, required this.type});
  @override
  Widget build(BuildContext context) {
    downloadAlbum(tags, type);
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              cancel = true;
              currentIndex = 0;
              busy = false;
              Navigator.pop(context);
              //dispose();
            },
          ),
          title: const Text("Downloading..."),
        ),
        body: downloadingRightNow());
  }
}
