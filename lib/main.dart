import 'package:advanced_joke_generator/provider/provider_services.dart';
import 'package:advanced_joke_generator/view/joke_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';


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
          final colorScheme = jokeProvider.currentColorScheme;
          
          return MaterialApp(
            title: 'Ultimate Joke Generator',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: colorScheme.copyWith(brightness: Brightness.light),
              textTheme: GoogleFonts.poppinsTextTheme(),
              cardTheme: CardTheme(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: colorScheme.copyWith(brightness: Brightness.dark),
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
              cardTheme: CardTheme(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
