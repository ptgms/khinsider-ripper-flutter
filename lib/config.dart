library config.globals;

import 'package:flutter/material.dart';
import 'package:khinrip/structs.dart';
import 'package:path_provider/path_provider.dart';

// Variables telling our App where to find stuff.
String baseUrl = "https://downloads.khinsider.com";
String baseSearchUrl = "/search?search=";
String baseAlbumUrl = "/game-soundtracks/album/";

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
