library config.globals;

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:khinrip/structs.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'album_view.dart';

// Variables telling our App where to find stuff.
String baseUrl = "https://downloads.khinsider.com";
String baseSearchUrl = "/search?search=";
String baseAlbumUrl = "/game-soundtracks/album/";
String allPlatformsUrl = "/console-list";
String top40Url = "/top40";

// List of saved favorites
List<AlbumStruct> favorites = [];

// The path to save the music to. Empty on iOS.
String pathToSaveIn = "";

// The apps theme (0 = system, 1 = light, 2 = dark)
var appTheme = 1;
// If the favorite page is the default home screen
var favoriteHome = true;
// The track list behavior on tap (0=preview, 1=preview in browser, 2=download)
// since on some platforms, preview doesnt work, it will automatically use 1.
var trackListBehavior = 0;
// The download format popup style (0=auto, 1=alert, 2=bottom sheet)
var popupStyle = 0;
//Notifies app if theme changes
ValueNotifier<int> notifier = ValueNotifier(0);
//Downloads allowed at the same time
var maxDownloads = 1;
// Material Design 3 enabled
var md3 = false;
// Custom Window Border (Desktop only)
var windowBorder = true;
// Language code
var setLanguage = "en";
// Analytics
var analytics = true;
// Behavior of the "Preview" panel. If true, it shows Navigate back/forth, if false, go back/forward 5 secs
var nextTrackPrev = true;

ValueNotifier<int> currentDownload = ValueNotifier(0);

// We load in the languages.json at start, as it requires an "await", making it not beneficial to load in later.
String languageJson = "";

// Welcome to janky-hut, may I take your order?
ValueNotifier<int> favUpdater = ValueNotifier(0);

Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

double getRoundedValue() {
  if (md3) {
    return 16;
  } else {
    return 5;
  }
}

bool foundInFavorites(AlbumStruct element) {
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
}

var busy = false;

Future<void> goToAlbum(BuildContext context, aName, aLink) async {
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
  String albumName = aName;
  String albumLink = baseUrl + aLink;
  List<String> trackURL = [];
  List<String> coverURL = [];

  List<String> tags = [];
  List<String> trackSizeMP3 = [];
  List<String> trackSizeFLAC = [];
  List<String> trackSizeOGG = [];

  Uri completedUrl = Uri.parse(baseUrl + aLink.replaceAll(baseUrl, ""));

  //debugPrint(completed_url.toString());

  AlbumTags toPush = AlbumTags(
      tracks, trackDuration, "Null", albumLink, trackURL, coverURL, false, false, false, tags, trackSizeMP3, trackSizeFLAC, trackSizeOGG);

  http.read(completedUrl).then((contents) {
    BeautifulSoup bs = BeautifulSoup(contents);

    for (var element in bs.findAll('', class_: 'albumImage')) {
      var imgurl = element.find('a')!['href'];
      //debugPrint(imgurl);
      coverURL.add(imgurl!);
    }

    if (coverURL.isEmpty) {
      coverURL.add("none");
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

    toPush = AlbumTags(tracks, trackDuration, albumName.replaceAll("&amp;", "&"), albumLink, trackURL, coverURL, mp3, flac, ogg, tags,
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
