import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../jokes_model/model.dart';
import '../jokes_model/jokes_category.dart';



class JokeProvider extends ChangeNotifier {
  JokeModel? currentJoke;
  List<JokeModel> favoriteJokes = [];
  List<JokeModel> jokeHistory = [];
  bool isLoading = false;
  FlutterTts flutterTts = FlutterTts();
  ThemeMode _themeMode = ThemeMode.light;
  JokeStats stats = JokeStats();
  late ConfettiController confettiController;
  Timer? jokeTimer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  ThemeMode get themeMode => _themeMode;
  bool showConfetti = true;
   bool dailyNotificationEnabled = false;
  TimeOfDay notificationTime = TimeOfDay(hour: 9, minute: 0);
   bool autoPlayEnabled = false;
   Duration autoPlayInterval = Duration(minutes: 1);
   bool autoReadEnabled = false;
   double speechRate = 1.0;

  final List<String> apiEndpoints = [
    'https://api.chucknorris.io/jokes/random',
    'https://official-joke-api.appspot.com/random_joke',
    'https://v2.jokeapi.dev/joke/Any?safe-mode',
    'https://icanhazdadjoke.com/',
  ];

  JokeCategory _selectedCategory = JokeCategory.all;
  JokeCategory get selectedCategory => _selectedCategory;

  JokeProvider() {
    confettiController = ConfettiController(duration: Duration(seconds: 1));
    initNotifications();
    loadStats();
    loadFavorites();
    loadHistory();
  }

  Future<void> initNotifications() async {
    final initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final initializationSettingsIOS= const DarwinInitializationSettings(
    requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,

    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void scheduleJokeNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'joke_channel', 'Joke Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails IOSPlatformChannelSpecifics =
    DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      sound: 'default',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics,iOS: IOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.periodicallyShow(
      0,
      'Time for a laugh!',
      'Check out your daily joke',
      RepeatInterval.daily,
      platformChannelSpecifics,
    );
  }

  Future<http.Response> _getJokeFromApi(JokeCategory category) {
    String endpoint;
    
    switch (category) {
      case JokeCategory.programming:
        endpoint = 'https://v2.jokeapi.dev/joke/Programming?safe-mode';
        break;
      case JokeCategory.chuckNorris:
        endpoint = 'https://api.chucknorris.io/jokes/random';
        break;
      case JokeCategory.dad:
        endpoint = 'https://icanhazdadjoke.com/';
        break;
      case JokeCategory.oneLiners:
        endpoint = 'https://v2.jokeapi.dev/joke/Miscellaneous?safe-mode&type=single';
        break;
      case JokeCategory.pun:
        endpoint = 'https://v2.jokeapi.dev/joke/Pun?safe-mode';
        break;
      default:
        final random = Random();
        endpoint = apiEndpoints[random.nextInt(apiEndpoints.length)];
    }

    final headers = endpoint.contains('icanhazdadjoke') 
      ? {'Accept': 'application/json'} 
      : {'Content-Type': 'application/json'};
      
    return http.get(Uri.parse(endpoint), headers: headers);
  }

  Future<void> fetchJoke({JokeCategory category = JokeCategory.chuckNorris}) async {
    if (await _checkConnectivity()) {
      isLoading = true;
      notifyListeners();

      try {
        final response = await _getJokeFromApi(category);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          currentJoke = JokeModel.fromJson(data);
          jokeHistory.insert(0, currentJoke!);
          if (jokeHistory.length > 50) jokeHistory.removeLast();
          stats.jokesRead++;
          _saveStats();
          _saveHistory();
          confettiController.play();
        }
      } catch (e) {
        print('Error fetching joke: $e');
      }

      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }



  void toggleFavorite() {
    if (currentJoke != null) {
      currentJoke!.isFavorite = !currentJoke!.isFavorite;
      if (currentJoke!.isFavorite) {
        favoriteJokes.add(currentJoke!);
        stats.favorited++;
      } else {
        favoriteJokes.removeWhere((joke) => joke.id == currentJoke!.id);
        stats.favorited--;
      }
      _saveStats();
      _saveFavorites();
      notifyListeners();
    }
  }

  void shareJoke() {
    if (currentJoke != null) {
      Share.share(currentJoke!.value);
      stats.shared++;
      _saveStats();
    }
  }

  void startJokeTimer(Duration interval) {
    jokeTimer?.cancel();
    jokeTimer = Timer.periodic(interval, (timer) {
      fetchJoke();
    });
  }

  void stopJokeTimer() {
    jokeTimer?.cancel();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Future<void> fetchJoke() async {
  //   isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final response = await http.get(Uri.parse(apiEndpoints[0]));
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       currentJoke = JokeModel.fromJson(data);
  //     }
  //   } catch (e) {
  //     print('Error fetching joke: $e');
  //   }
  //
  //   isLoading = false;
  //   notifyListeners();
  // }
  //
  // void toggleFavorite() {
  //   if (currentJoke != null) {
  //     currentJoke!.isFavorite = !currentJoke!.isFavorite;
  //     if (currentJoke!.isFavorite) {
  //       favoriteJokes.add(currentJoke!);
  //     } else {
  //       favoriteJokes.removeWhere((joke) => joke.id == currentJoke!.id);
  //     }
  //     notifyListeners();
  //     _saveFavorites();
  //   }
  // }

  Future<void> speakJoke() async {
    if (currentJoke != null) {
      await flutterTts.speak(currentJoke!.value);
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = favoriteJokes.map((joke) => json.encode(joke.toJson())).toList();
    await prefs.setStringList('favorites', favoritesList);
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList('favorites') ?? [];
    favoriteJokes = favoritesList
        .map((jokeString) => JokeModel.fromJson(json.decode(jokeString)))
        .toList();
    notifyListeners();
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stats', json.encode(stats.toJson()));
  }

  Future<void> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('stats');
    if (statsJson != null) {
      stats = JokeStats.fromJson(json.decode(statsJson));
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = jokeHistory.map((joke) => json.encode(joke.toJson())).toList();
    await prefs.setStringList('history', historyList);
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList('history') ?? [];
    jokeHistory = historyList
        .map((jokeString) => JokeModel.fromJson(json.decode(jokeString)))
        .toList();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setShowConfetti(bool value) {
    showConfetti = value;
    notifyListeners();
  }

  void setDailyNotification(bool value) {
    dailyNotificationEnabled = value;
    notifyListeners();
  }

  void setNotificationTime(TimeOfDay time) {
    notificationTime = time;
    if (dailyNotificationEnabled) {
      cancelJokeNotification();
      scheduleJokeNotification();
    }
    notifyListeners();
  }

  void cancelJokeNotification() {
    flutterLocalNotificationsPlugin.cancel(0);
  }

  void setAutoPlay(bool value) {
    autoPlayEnabled = value;
    if (value) {
      startJokeTimer(autoPlayInterval);
    } else {
      stopJokeTimer();
    }
    notifyListeners();
  }

  void setAutoPlayInterval(Duration interval) {
    autoPlayInterval = interval;
    if (autoPlayEnabled) {
      startJokeTimer(interval);
    }
    notifyListeners();
  }

  void setAutoRead(bool value) {
    autoReadEnabled = value;
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    speechRate = rate;
    flutterTts.setSpeechRate(rate);
    notifyListeners();
  }

  void clearFavorites() {
    favoriteJokes.clear();
    _saveFavorites();
    notifyListeners();
  }

  void clearHistory() {
    jokeHistory.clear();
    _saveHistory();
    notifyListeners();
  }

  void resetStats() {
    stats = JokeStats();
    _saveStats();
    notifyListeners();
  }

  void setCategory(JokeCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }
}