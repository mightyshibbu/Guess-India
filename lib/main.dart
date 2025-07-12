import 'package:flutter/material.dart';
import 'package:party_charades/screens/loading_screen.dart';
import 'package:party_charades/screens/home_screen.dart';
import 'package:party_charades/screens/deck_detail_screen.dart';
import 'package:party_charades/screens/game_screen.dart';
import 'package:party_charades/screens/results_screen.dart';
import 'package:party_charades/screens/settings_screen.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const PartyCharadesApp());
}

class PartyCharadesApp extends StatelessWidget {
  const PartyCharadesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Party Charades',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: LoadingScreen.routeName,
      routes: {
        LoadingScreen.routeName: (context) => const LoadingScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        DeckDetailScreen.routeName: (context) => const DeckDetailScreen(),
        GameScreen.routeName: (context) => const GameScreen(),
        ResultsScreen.routeName: (context) => const ResultsScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
