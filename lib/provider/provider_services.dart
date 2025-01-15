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
  // FlutterTts flutterTts = FlutterTts();
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

  final FlutterTts flutterTts = FlutterTts();
  String _selectedVoice = 'en-US';
  double _pitch = 1.0;
  double _volume = 1.0;
  
  final List<Color> themeColors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.green,
    Colors.pink,
  ];
  int _selectedColorSchemeIndex = 0;
  ColorScheme get currentColorScheme => ColorScheme.fromSeed(
    seedColor: themeColors[_selectedColorSchemeIndex],
  );

  String get selectedVoice => _selectedVoice;
  double get pitch => _pitch;
  double get volume => _volume;
  int get selectedColorSchemeIndex => _selectedColorSchemeIndex;

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
    final endpoint = categoryApis[category] ?? categoryApis[JokeCategory.all]!;
    final headers = endpoint.contains('icanhazdadjoke') 
      ? {'Accept': 'application/json'} 
      : {'Content-Type': 'application/json'};
    
    return http.get(Uri.parse(endpoint), headers: headers);
  }

  Future<void> fetchJoke({JokeCategory category = JokeCategory.all}) async {
    if (await _checkConnectivity()) {
      isLoading = true;
      notifyListeners();

      try {
        final response = await _getJokeFromApi(category);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data is Map<String, dynamic>) {
            if (data.containsKey('joke')) {
              currentJoke = JokeModel(
                id: data['id'].toString(),
                value: data['joke'],
                categories: [],
                createdAt: DateTime.now(),
              );
            } else if (data.containsKey('setup')) {
              currentJoke = JokeModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                value: '${data['setup']} ${data['punchline']}',
                setup: data['setup'],
                punchline: data['punchline'],
                categories: [],
                createdAt: DateTime.now(),
              );
            } else if (data.containsKey('value')) {
              currentJoke = JokeModel(
                id: data['id'].toString(),
                value: data['value'],
                categories: List<String>.from(data['categories'] ?? []),
                createdAt: data['created_at'] != null 
                    ? DateTime.parse(data['created_at']) 
                    : DateTime.now(),
                iconUrl: data['icon_url'],
              );
            } else if (data.containsKey('type')) {
              currentJoke = JokeModel(
                id: data['id'].toString(),
                value: data['type'] == 'single' 
                    ? data['joke'] 
                    : '${data['setup']} ${data['delivery']}',
                setup: data['type'] == 'twopart' ? data['setup'] : null,
                punchline: data['type'] == 'twopart' ? data['delivery'] : null,
                categories: [data['category']],
                createdAt: DateTime.now(),
              );
            }
          }

          if (currentJoke != null) {
            jokeHistory.insert(0, currentJoke!);
            if (jokeHistory.length > 50) jokeHistory.removeLast();
            stats.jokesRead++;
            _saveStats();
            _saveHistory();
            if (showConfetti) confettiController.play();
          }
        }
      } catch (e) {
        print('Error fetching joke: $e');
        currentJoke = JokeModel(
          id: DateTime.now().toString(),
          value: 'Failed to fetch joke. Please try again.',
          categories: [],
          createdAt: DateTime.now(),
        );
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

  Future<void> speakJoke() async {
    if (currentJoke != null) {
      if (currentJoke!.setup != null) {
        await flutterTts.speak(currentJoke!.setup!);
        await Future.delayed(Duration(seconds: 2));
        await flutterTts.speak(currentJoke!.punchline!);
      } else {
        await flutterTts.speak(currentJoke!.value);
      }
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

  Future<void> initTts() async {
    await flutterTts.setLanguage(_selectedVoice);
    await flutterTts.setPitch(_pitch);
    await flutterTts.setVolume(_volume);
    
    final voices = await flutterTts.getVoices;
    print('Available voices: $voices');
  }

  Future<void> setVoice(String voice) async {
    _selectedVoice = voice;
    await flutterTts.setLanguage(voice);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await flutterTts.setPitch(pitch);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await flutterTts.setVolume(volume);
    notifyListeners();
  }

  void setColorScheme(int index) {
    _selectedColorSchemeIndex = index;
    notifyListeners();
  }

  final Map<JokeCategory, String> categoryApis = {
    JokeCategory.programming: 'https://v2.jokeapi.dev/joke/Programming?safe-mode',
    JokeCategory.pun: 'https://v2.jokeapi.dev/joke/Pun?safe-mode',
    JokeCategory.dad: 'https://icanhazdadjoke.com/',
    JokeCategory.knockKnock: 'https://official-joke-api.appspot.com/jokes/knock-knock/random',
    JokeCategory.chuckNorris: 'https://api.chucknorris.io/jokes/random',
    JokeCategory.oneLiners: 'https://v2.jokeapi.dev/joke/Miscellaneous,Dark?safe-mode&type=single',
    JokeCategory.all: 'https://v2.jokeapi.dev/joke/Any?safe-mode',
  };
}