import 'dart:io';

import 'package:flutter/material.dart';
import 'package:khinrip/search_page.dart';
import 'package:khinrip/settings_page.dart';
import 'package:khinrip/structs.dart';
import 'package:window_size/window_size.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorite_view.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(512, 384));
  }
  final prefs = await SharedPreferences.getInstance();

  var favNames = prefs.getStringList("favs_name");
  var favLink = prefs.getStringList("favs_link");

  pathToSaveIn = prefs.getString("location") ?? "";

  if (favNames != null && favLink != null) {
    for (var i = 0; i < favNames.length; i++) {
      favorites.add(AlbumStruct(favNames[i], favLink[i]));
    }
  }
  runApp(const MyApp());
}

var dark = true;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khinsider Ripper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(useMaterial3: true),
      darkTheme: ThemeData.dark().copyWith(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Khinsider Ripper'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var bodyToPush = const FavoriteWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: () async {
                final _ = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchWidget()));
                setState(() {
                  bodyToPush = const FavoriteWidget();
                });
              },
              icon: const Icon(Icons.search),
            ),
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isIOS)
              IconButton(
                onPressed: (() {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()));
                }),
                icon: const Icon(Icons.settings_rounded),
              )
            /*=> Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SearchWidget())),
            icon: const Icon(Icons.search),
          ),*/
            //const CupertinoSearchTextField(placeholder: 'Search for OSTs',),
          ],
        ),
        body: bodyToPush);

    /*return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times :)',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );*/
  }
}
