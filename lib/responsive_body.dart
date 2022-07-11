import 'package:flutter/material.dart';
import 'package:flutter_things/demesions.dart';
import 'package:flutter_things/desktop_body.dart';
import 'package:flutter_things/mobile_body.dart';

class ResposiveLayout extends StatelessWidget {
  const ResposiveLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > mobileWidth) {
          return const DesktopBody();
        } else {
          return const MobileBody();
        }
      },
    );
  }
}
