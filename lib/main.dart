import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PartyCharadesApp());
}

class PartyCharadesApp extends StatelessWidget {
  const PartyCharadesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Party Charades',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
