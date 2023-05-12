import 'package:flutter/material.dart';
import 'package:khinrip/download_utils.dart';
import 'package:khinrip/structs.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:khinrip/config.dart';

// ignore: must_be_immutable
class DownloadingView extends StatefulWidget {
  AlbumTags tags;
  String type;

  DownloadingView({Key? key, required this.tags, required this.type}) : super(key: key);

  @override
  // ignore: no_logic_in_create_state, library_private_types_in_public_api
  _DownloadingViewState createState() =>
      // ignore: no_logic_in_create_state
      _DownloadingViewState(tags: tags, type: type);
}

int currentIndex = 0; // currently downloading song
bool busy = false; // if app already doing something async
bool cancel = false; // if user cancelled out
//String etaTime = "..."; // estimated time remaining
ValueNotifier<String> etaTime = ValueNotifier("...");

class _DownloadingViewState extends State<DownloadingView> {
  // goes through all tracks in album and uses function in download_utils to download each track
  Future<bool> downloadAlbum(AlbumTags tags, String type) async {
  if (!busy) {
    busy = true;

    // Create a list of lists of tasks, where each task is a Future<bool>.
    // Each list of tasks will be downloaded together.
    List<Future<bool>> tasks = [];

    // Download each track in the album.
    for (var i = 0; i < tags.trackURL.length; i++) {
      if (cancel) {
        return false;
      }
      tasks.add(downloadFileFromAlbum(tags, i, type));
    }

    // Split tasks into groups of maxDownloads.
    List<List<Future<bool>>> splitTasks = [];
    for (var i = 0; i < tasks.length; i += maxDownloads) {
      splitTasks.add(tasks.sublist(i, i + maxDownloads > tasks.length ? tasks.length : i + maxDownloads));
    }

    // Reset the number of downloads.
    currentDownload.value = 0;

    // Start downloading the tracks.
    var time = DateTime.now();

    // Download each list of tracks per group in parallel and wait for them to finish and get the results.
    // the function downloadFileFromAlbum returns a Future<bool> which is true if the download was successful.
    // If the download was successful, increment the number of downloads. If not, don't increment and cancel the download.
    List<Future<void>> downloadFutures = [];

for (var i = 0; i < splitTasks.length - 1; i++) {
  for (var j = 0; j < splitTasks[i].length; j++) {
    if (cancel) {
      return false;
    }
    var downloadFuture = splitTasks[i][j].then((value) {
      if (value) {
        currentDownload.value++;
        DateTime currentTime = DateTime.now();
        Duration elapsedDuration = currentTime.difference(time);
        int currentIteration = (i * maxDownloads) + j + 1;
        int remainingIterations = tasks.length - currentIteration;
        Duration remainingDuration = elapsedDuration * remainingIterations;
        etaTime.value = remainingDuration.toString().split(".")[0];
        debugPrint("Done with $j in group $i");
      } else {
        cancel = true;
      }
    });
    downloadFutures.add(downloadFuture);
  }
}

await Future.wait(downloadFutures);

    // Download the last group of tasks.
    if (splitTasks.isNotEmpty) {
      await Future.wait(splitTasks.last).then((value) {
        debugPrint("Done with group ${splitTasks.length - 1}");
        currentDownload.value += splitTasks.last.length;
      });
    }

    // Done!
    debugPrint("Done");
    currentDownload.value = 0;
    busy = false;
    return true;
  }
  return false;
}




  // download progress
  SizedBox downloadingRightNow(context) {
    var t = AppLocalizations.of(context)!;
    return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Center(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Marquee(
                      child: Text(t.downloadingAlbum(tags.albumName), style: const TextStyle(fontSize: 25), textAlign: TextAlign.center)))),
          Center(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: ValueListenableBuilder<int>(
                  valueListenable: currentDownload,
                  builder: (context, value, child) {
                    return Text("$value / ${tags.trackURL.length}", textAlign: TextAlign.center);
                  },
                )), //Text(currentIndex.toString() + " / " + tags.trackURL.length.toString(), textAlign: TextAlign.center)),
          ),
          Center(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: ValueListenableBuilder<int>(
                      valueListenable: currentDownload,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(value: value / tags.trackURL.length);
                      }))),
          Center(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Marquee(child: Text(t.downloadThread(maxDownloads.toString()), textAlign: TextAlign.center)))),
                  Center(child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Marquee(child: ValueListenableBuilder<String>(
                      valueListenable: etaTime,
                      builder: (context, value, child) {
                        if (value == "...") {
                          return Container();
                        }
                        return Text(t.download_eta(value), textAlign: TextAlign.center);
                      },
                    )))),
        ]));
  }

  AlbumTags tags;
  String type;

  _DownloadingViewState({required this.tags, required this.type});
  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
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
          title: Text(t.downloadingAlbum("Album")),
        ),
        body: downloadingRightNow(context));
  }
}
