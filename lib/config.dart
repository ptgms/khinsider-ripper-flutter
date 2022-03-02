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
// The track list behavior on tap
var trackListBehavior = 0;
//Notifies app if theme changes
ValueNotifier<int> notifier = ValueNotifier(0);

// Welcome to janky-hut, may I take your order?
ValueNotifier<int> favUpdater = ValueNotifier(0);

Future<String> get localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<String> get localPathAndroid async {
  final directory = await getExternalStorageDirectory();

  return directory!.path;
}

bool foundInFavorites(AlbumStruct element) {
  for (var fav in favorites) {
    if (fav.albumName == element.albumName &&
        fav.albumLink == element.albumLink) {
      return true;
    }
  }
  return false;
}

int locateInFavorites(AlbumStruct element) {
  for (var i = 0; i < favorites.length; i++) {
    if (favorites[i].albumName == element.albumName &&
        favorites[i].albumLink == element.albumLink) {
      return i;
    }
  }
  return -1;
}
