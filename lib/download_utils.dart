import 'dart:io';
import 'dart:typed_data';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

String getSeperator() {
  if (Platform.isWindows) {
    return "\\";
  } else {
    return "/";
  }
}

Future<bool> downloadFile(AlbumTags tags, int index, String type) async {
  String toDownload = "";
  await http.read(Uri.parse(baseUrl + tags.trackURL[index])).then((contents) {
    BeautifulSoup bs = BeautifulSoup(contents);

    var element = bs.find('', id: 'EchoTopic')!;

    for (var link in element.findAll('a')) {
      if (link.attributes['href'] != null) {
        if (link.attributes['href']!.endsWith(".$type")) {
          toDownload = link.attributes['href']!;
        }
      }
    }
    return false;
  });
  Uint8List bytes =
      (await NetworkAssetBundle(Uri.parse(toDownload)).load(toDownload))
          .buffer
          .asUint8List();
  final stream = Stream.fromIterable(bytes);
  final bytesSave = await stream.toList();
  var fileName = tags.tracks[index] + ".$type";
  debugPrint(await localPath);
  if (pathToSaveIn != "") {
    fileName = pathToSaveIn + getSeperator() + tags.tracks[index] + ".$type";
  } else if (pathToSaveIn == "" && Platform.isIOS) {
    fileName = await localPath +
        getSeperator() +
        tags.albumName.replaceAll(" ", "_") +
        getSeperator() +
        tags.tracks[index] +
        ".$type";
  }

  final file = File(fileName).create(recursive: true).then(
    (file) {
      file.writeAsBytes(bytesSave);
    },
  );
  //download(stream, pathToSaveIn + "\\" + tags.tracks[index] + ".$type");
  return true;
}

Future<bool> downloadFileFromAlbum(
    AlbumTags tags, int index, String type) async {
  String toDownload = "";
  await http.read(Uri.parse(baseUrl + tags.trackURL[index])).then((contents) {
    BeautifulSoup bs = BeautifulSoup(contents);

    var element = bs.find('', id: 'EchoTopic')!;

    for (var link in element.findAll('a')) {
      if (link.attributes['href'] != null) {
        if (link.attributes['href']!.endsWith(".$type")) {
          toDownload = link.attributes['href']!;
        }
      }
    }
    return false;
  });
  Uint8List bytes =
      (await NetworkAssetBundle(Uri.parse(toDownload)).load(toDownload))
          .buffer
          .asUint8List();
  final stream = Stream.fromIterable(bytes);
  final bytesSave = await stream.toList();
  var fileName = tags.albumName.replaceAll(" ", "_") +
      getSeperator() +
      tags.tracks[index] +
      ".$type";
  debugPrint(await localPath);
  if (pathToSaveIn != "") {
    fileName = pathToSaveIn +
        getSeperator() +
        tags.albumName.replaceAll(" ", "_") +
        getSeperator() +
        tags.tracks[index] +
        ".$type";
  } else if (pathToSaveIn == "" && Platform.isIOS) {
    fileName = await localPath +
        getSeperator() +
        tags.albumName.replaceAll(" ", "_") +
        getSeperator() +
        tags.tracks[index] +
        ".$type";
  }

  final file = File(fileName).create(recursive: true).then(
    (file) {
      file.writeAsBytes(bytesSave);
    },
  );
  //download(stream, pathToSaveIn + "\\" + tags.tracks[index] + ".$type");
  return true;
}
