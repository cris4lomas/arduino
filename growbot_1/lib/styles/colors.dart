import 'package:flutter/material.dart';

class MyColors{
  static const Color primary = Color.fromARGB(255, 39, 39, 39);
  static const Color secondary = Color.fromARGB(255, 60, 60, 60);
  static const Color darkText = Color.fromARGB(255, 10, 10, 10);
  static const Color lightText = Color.fromARGB(255, 255, 255, 255);
  static const Color txSecondary = Color.fromARGB(255, 36, 36, 36);
  static const Color lightBackground = Color(0Xfff0f0f0);
  static const Color icon1 = Color(0Xfff0f0f0);
  static const Color icon2 = Color.fromARGB(255, 98, 13, 13);
  static const Color ocean1 = Color(0xFF011C29);
  static const Color ocean2 = Color(0xFF0F695E);
  static const Color ocean3 = Color(0xFF1695A1);
  static const Color ocean4 = Color(0xFF04E6FF);
  static const Color red = Color(0Xffa82400);
  static const Color yellow = Color.fromARGB(255, 246, 227, 157);
  static const Color grey = Color.fromARGB(145, 120, 120, 120);
  static const Color lightGrey = Color.fromARGB(164, 158, 157, 157);
  static const Color gold = Color.fromARGB(255, 212, 175, 56);
  static const Color darkGold = Color.fromARGB(161, 103, 88, 1);


}

class MyGreenStateColor extends MaterialStateColor {
  const MyGreenStateColor() : super(_defaultColor);

  static const int _defaultColor = 0xcafefeed;
  //static const int _pressedColor = 0xdeadbeef;

  @override
  Color resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.pressed)) {
      return const Color.fromARGB(222, 23, 82, 17);
    }
    return const Color.fromARGB(201, 14, 182, 64);
  }
}