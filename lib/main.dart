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
      create: (_) => JokeProvider()..loadThemeMode(),
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
              colorScheme: colorScheme.copyWith(
                brightness: Brightness.dark,
                background: Colors.grey[900],
                surface: Colors.grey[850],
                primary: colorScheme.primary.withOpacity(0.8),
                secondary: colorScheme.secondary.withOpacity(0.8),
                onBackground: Colors.white.withOpacity(0.87),
                onSurface: Colors.white.withOpacity(0.87),
              ),
              scaffoldBackgroundColor: Colors.black,
              cardTheme: CardTheme(
                elevation: 8,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey[900],
                elevation: 0,
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
