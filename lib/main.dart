import 'dart:developer';

import 'package:chatie/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_notification_channel/flutter_notification_channel.dart';
import 'package:flutter_notification_channel/notification_importance.dart';
import 'firebase_options.dart';

// global object for accessing screen size
 late Size mq;


void main() {

  WidgetsFlutterBinding.ensureInitialized();

  // for entering full screen

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // orientation portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value) {
    _initailizeFirebase();
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chatie',
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black, size: 20),
        titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 20,
            fontFamily: 'Times New Roman'),
        backgroundColor: Colors.white,
        centerTitle: true,
      )),
      home: const SplashScreen(),
    );
  }
}

_initailizeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,);

  var result = await FlutterNotificationChannel().registerNotificationChannel(
    description: 'for showing message notifications',
    id: 'chats',
    importance: NotificationImportance.IMPORTANCE_HIGH,
    name: 'Chats',
  );
  log(result);
}
