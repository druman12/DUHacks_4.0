import 'package:classroom/signin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: const FirebaseOptions(
  apiKey:"AIzaSyAefpzsXowFCGP4UwJ0zF8x1wHP3_SDomQ",
  appId: "1:955268353153:android:4ccbef227699eb50899180",
  messagingSenderId: "955268353153",
  projectId: "classroom-949b3",
  storageBucket: "gs://classroom-949b3.appspot.com"
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SignInPage(),
    );
  }
}