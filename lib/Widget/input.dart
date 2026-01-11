import 'package:flutter/material.dart';

class InputDecoratios {
  static InputDecoration inputDecoration({
    required String hintext,
    required String labeltext,
    required Icon icono}) {
    return InputDecoration(
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFc0733d))),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFc0733d), width: 2)),
        hintText: hintext,
        labelText: labeltext,
        prefixIcon: icono
    );
  }
}