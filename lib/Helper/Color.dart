import 'package:flutter/material.dart';

extension colors on ColorScheme {
  static MaterialColor primary_app = const MaterialColor(
    0xff00BBD4,
    <int, Color>{
      50: primary1,
      100: primary1,
      200: primary1,
      300: primary1,
      400: primary1,
      500: primary1,
      600: primary1,
      700: primary1,
      800: primary1,
      900: primary1,
    },
  );

  static const String lightFontColor = "#FFFFFF";

  static const String darkFontColor = "#212121";

  static const Color primary1 = Color(0xff00BBD4);

  String get webFontColor =>
      brightness == Brightness.dark ? lightFontColor : darkFontColor;

  Color get primary => brightness == Brightness.dark
      ? const Color(0xff00BBD4)
      : const Color(0xff00BBD4);
  Color get secondary => brightness == Brightness.dark
      ? const Color(0xffF0F0F0)
      : const Color(0xffF0F0F0);
// now all same
  Color get fontColor => brightness == Brightness.dark
      ? const Color(0xffFFFFFF)
      : const Color(0xff212121);

  Color get pink => brightness == Brightness.dark
      ? const Color(0xffd4001d)
      : const Color(0xffd4001d);

  Color get red => brightness == Brightness.dark ? Colors.red : Colors.red;

  Color get lightfontColor => brightness == Brightness.dark
      ? const Color(0xffFFFFFF)
      : const Color(0xff484848);
  Color get lightfontColor2 => brightness == Brightness.dark
      ? const Color(0xffFFFFFF)
      : const Color(0xff5C5C5C);

  //
  Color get lightWhite => brightness == Brightness.dark
      ? const Color(0xff1E2829)
      : const Color(0xffF6F6F6);

  //
  Color get white => brightness == Brightness.dark
      ? const Color(0xff303E40)
      : const Color(0xffFFFFFF);

  //
  Color get darkColor => brightness == Brightness.dark
      ? const Color(0xff1E3039)
      : const Color(0xff1E2829);
  //
  Color get darkColor2 => brightness == Brightness.dark
      ? const Color(0xff1E3039)
      : const Color(0xff303E40);

  Color get simmerBase =>
      brightness == Brightness.dark ? darkColor2 : Colors.grey[300]!;

  Color get simmerHigh =>
      brightness == Brightness.dark ? darkColor : Colors.grey[100]!;
}
