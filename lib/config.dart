library config.globals;

import 'package:khinrip/structs.dart';

// Variables telling our App where to find stuff.
String baseUrl = "https://downloads.khinsider.com";
String baseSearchUrl = "/search?search=";
String baseAlbumUrl = "/game-soundtracks/album/";

List<AlbumStruct> favorites = [];

String pathToSaveIn = "";

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
