import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khinrip/config.dart';
import 'package:http/http.dart' as http;

String getSeperator() {
  if (Platform.isWindows) {
    return "\\";
  } else {
    return "/";
  }
}

Future<String> getDirectDownloadLink(String url, String type) async {
  var contents = await http.read(Uri.parse(url));
  BeautifulSoup bs = BeautifulSoup(contents);

  var element = bs.find('', id: 'pageContent')!;
  String toDownload = "";

  for (var link in element.findAll('a')) {
    debugPrint("iterating");
    if (link.attributes['href'] != null) {
      if (link.attributes['href']!.endsWith(".$type")) {
        toDownload = link.attributes['href']!;
      }
    }
  }
  return toDownload;
}

Future<Uint8List> downloadFile(String url) async {
  var dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
    ),
  );

  var response = await dio.get(
    url,
    options: Options(
      responseType: ResponseType.bytes,
    ),
  );

  return response.data;
}

Future<bool> saveFile(Uint8List bytes, String fileName, String albumName) async {
  final stream = Stream.fromIterable(bytes);
  final bytesSave = await stream.toList();
  debugPrint(await localPath);
  if (pathToSaveIn != "") {
    fileName = "$pathToSaveIn${getSeperator()}${generateValidFolderName(albumName)}${getSeperator()}$fileName";
  } else if (pathToSaveIn == "" && Platform.isIOS) {
    fileName = "${await localPath}${getSeperator()}${generateValidFolderName(albumName)}${getSeperator()}$fileName";
  } else if (pathToSaveIn == "" && Platform.isAndroid) {
    fileName = "/storage/emulated/0/Download${getSeperator()}KhinsiderRipper${getSeperator()}${generateValidFolderName(albumName)}${getSeperator()}$fileName";
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

String generateValidFolderName(String path) {
  // Remove illegal characters from path
  return path
      .replaceAll(":", "")
      .replaceAll("?", "")
      .replaceAll("/", "")
      .replaceAll("\\", "")
      .replaceAll("*", "")
      .replaceAll("\"", "")
      .replaceAll("<", "")
      .replaceAll(">", "")
      .replaceAll("|", "")
      .replaceAll(" ", "_");
}
