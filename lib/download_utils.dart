import 'dart:io';
import 'dart:typed_data';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'analytics_tools.dart';

String getSeperator() {
  if (Platform.isWindows) {
    return "\\";
  } else {
    return "/";
  }
}

// run multiple tasks in parallel with max concurrency and stream
Future<void> runMultiple(List<Future<bool>> tasks) async {
  await Future.wait(tasks);
}

Future<List<String>> getDirects(AlbumTags tags, String type) async {
  List<String> directLinks = [];
  Future.wait([getDirectLink(tags, 0, type)]);

  return directLinks;
}

Future<void> getDirectLink(AlbumTags tags, int index, String type) async {}

// for downloading a file from album - used in for loop
Future<bool> downloadFile(AlbumTags tags, int index, String type) async {
  await logEvent("downloadTrackAlbum");
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  String toDownload = "";
  debugPrint(baseUrl + tags.trackURL[index]);
  await http.read(Uri.parse(baseUrl + tags.trackURL[index])).then((contents) {
    BeautifulSoup bs = BeautifulSoup(contents);

    var element = bs.find('', id: 'pageContent')!;

    for (var link in element.findAll('a')) {
      debugPrint("iterating");
      if (link.attributes['href'] != null) {
        if (link.attributes['href']!.endsWith(".$type")) {
          toDownload = link.attributes['href']!;
          debugPrint(toDownload);
        }
      }
    }
    return false;
  });
  Uint8List bytes = (await NetworkAssetBundle(Uri.parse(toDownload)).load(toDownload)).buffer.asUint8List();
  final stream = Stream.fromIterable(bytes);
  final bytesSave = await stream.toList();
  var fileName = tags.tracks[index] + ".$type";
  debugPrint(await localPath);
  if (pathToSaveIn != "") {
    fileName = pathToSaveIn + getSeperator() + tags.tracks[index] + ".$type";
  } else if (pathToSaveIn == "" && Platform.isIOS) {
    fileName = await localPath + getSeperator() + tags.albumName.replaceAll(" ", "_") + getSeperator() + tags.tracks[index] + ".$type";
  } else if (pathToSaveIn == "" && Platform.isAndroid) {
    fileName = "/storage/emulated/0/Download" +
        getSeperator() +
        "KhinsiderRipper" +
        getSeperator() +
        tags.albumName.replaceAll(" ", "_") +
        getSeperator() +
        tags.tracks[index] +
        ".$type";
  }

  final _ = File(fileName).create(recursive: true).then(
    (file) {
      debugPrint(file.path);
      file.writeAsBytes(bytesSave);
    },
  );
  //download(stream, pathToSaveIn + "\\" + tags.tracks[index] + ".$type");
  return true;
}

// used for downloading singular file from the album, used in track view.
Future<bool> downloadFileFromAlbum(AlbumTags tags, int index, String type) async {
  await logEvent("downloadTrack");
  if (Platform.isAndroid) {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  String toDownload = "";
  await http.read(Uri.parse(baseUrl + tags.trackURL[index])).then((contents) {
    BeautifulSoup bs = BeautifulSoup(contents);

    var element = bs.find('', id: 'pageContent')!;

    for (var link in element.findAll('a')) {
      if (link.attributes['href'] != null) {
        if (link.attributes['href']!.endsWith(".$type")) {
          toDownload = link.attributes['href']!;
        }
      }
    }
    return false;
  });
  Uint8List bytes = (await NetworkAssetBundle(Uri.parse(toDownload)).load(toDownload)).buffer.asUint8List();
  final stream = Stream.fromIterable(bytes);
  final bytesSave = await stream.toList();
  var fileName = tags.albumName.replaceAll(" ", "_") + getSeperator() + tags.tracks[index] + ".$type";
  debugPrint(await localPath);
  if (pathToSaveIn != "") {
    fileName = pathToSaveIn + getSeperator() + tags.albumName.replaceAll(" ", "_") + getSeperator() + tags.tracks[index] + ".$type";
    getSeperator() + tags.tracks[index] + ".$type";
  } else if (pathToSaveIn == "" && Platform.isIOS) {
    fileName = await localPath + getSeperator() + tags.albumName.replaceAll(" ", "_") + getSeperator() + tags.tracks[index] + ".$type";
  } else if (pathToSaveIn == "" && Platform.isAndroid) {
    fileName = "/storage/emulated/0/Download" +
        getSeperator() +
        "KhinsiderRipper" +
        getSeperator() +
        tags.albumName.replaceAll(" ", "_") +
        getSeperator() +
        tags.tracks[index] +
        ".$type";
  }

  final _ = File(fileName).create(recursive: true).then(
    (file) {
      file.writeAsBytes(bytesSave);
    },
  );
  //download(stream, pathToSaveIn + "\\" + tags.tracks[index] + ".$type");
  return true;
}
