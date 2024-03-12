import 'dart:io';

import 'package:attheblocks/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'common/app_bindings.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyBTqGI1KESKIuSh3GTa4RPvlkEKo6dSzWY',
            appId: '1:205362677542:android:fc64e58a24ec71cf1523e7',
            messagingSenderId: '205362677542',
            projectId: 'rt-impact-dms-staging'));
  } else {
    Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        initialBinding: AppBindings(),
        debugShowCheckedModeBanner: false,
        initialRoute: SplashScreen.splashRoute,
        title: 'Flutter Demo',
        getPages: routes,
        theme: ThemeData(
            //colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
            useMaterial3: true,
            fontFamily: 'Nunito-Regular'),
        home: const SplashScreen());
  }
}
