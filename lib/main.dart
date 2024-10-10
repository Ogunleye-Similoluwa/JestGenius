import 'package:advanced_joke_generator/provider/provider_services.dart';
import 'package:advanced_joke_generator/view/joke_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  runApp( JokeApp());
}

class JokeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JokeProvider(),
      child: Consumer<JokeProvider>(
        builder: (context, jokeProvider, _) {
          return MaterialApp(
            title: 'Ultimate Joke Generator',
            theme: ThemeData.light().copyWith(
              primaryColor: Colors.blue,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: Colors.blueGrey,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blueGrey,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: jokeProvider.themeMode,
            home: JokeHomePage(),
          );
        },
      ),
    );
  }
}
