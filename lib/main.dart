import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Panaderia Nicol',
        routes: {
          "login" : (_) => SplashScreen(),
        },
        initialRoute: "login",
      ),
    );
  }
}