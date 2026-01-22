import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/screens/splash_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:panaderia_nicol_pos/screens/core/custom_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    center: true,
    minimumSize: Size(1024, 700),
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp(
        scrollBehavior: AppScrollBehavior(),
        debugShowCheckedModeBanner: false,
        title: 'Panaderia Nicol',
        routes: {
          "login": (_) => SplashScreen(),
        },
        initialRoute: "login",
      ),
    );
  }
}