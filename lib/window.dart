import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:window_manager/window_manager.dart';

import 'config.dart';
import 'main.dart';

class MainWindow extends StatefulWidget {
  const MainWindow(
      {Key? key, this.display, this.appBar, required this.actions, required this.actionsWindow, required this.title, required this.body})
      : super(key: key);

  final String title;
  final PreferredSizeWidget? display;
  final PreferredSizeWidget? appBar;
  final List<Widget> actionsWindow;
  final List<Widget> actions;

  final Widget body;

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.display,
        body: VirtualWindowFrame(
            //width: widthOfBorder,
            //color: Theme.of(context).backgroundColor,
            child: Column(children: [
          if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows))
            SizedBox(
                child: Container(
                    color: Theme.of(context).cardColor,
                    child: Row(
                        children: widget.actionsWindow +
                            [if (windowBorder) Row(children: widget.actions), const SizedBox(child: WindowButtons())]))),
          if ((Platform.isMacOS || Platform.isLinux || Platform.isWindows) && !windowBorder && widget.appBar != null) widget.appBar!,
          Expanded(child: widget.body)
        ])));
  }
}
