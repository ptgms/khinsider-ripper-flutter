import 'dart:io';
import 'dart:typed_data';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/services.dart';
import 'package:khinrip/config.dart';
import 'package:khinrip/structs.dart';
import 'package:http/http.dart' as http;

Future<bool> downloadFile(AlbumTags tags, int index, String type) async {
  String toDownload = "";
  await http
      .read(Uri.parse(baseUrl +
          tags.trackURL[index]))
      .then((contents) {
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
  if (pathToSaveIn != "") {
    fileName = pathToSaveIn + "\\" + tags.tracks[index] + ".$type";
  }

  final file = File(fileName);
  file.writeAsBytes(bytesSave);
  //download(stream, pathToSaveIn + "\\" + tags.tracks[index] + ".$type");
  return true;
}

bool downloadAlbum(AlbumTags tags, String type) {
  return true;
}
