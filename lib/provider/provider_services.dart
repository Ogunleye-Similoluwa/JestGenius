import 'dart:async';
import 'dart:collection';
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
  ThemeMode _themeMode = ThemeMode.system;
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

  Queue<JokeModel> ttsQueue = Queue<JokeModel>();
  bool isPlaying = false;

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
    Map<String, String> headers;

    print('Fetching joke for category: ${category.name}'); // Debug log

    if (category == JokeCategory.dad) {
      endpoint = 'https://icanhazdadjoke.com/';
      headers = {'Accept': 'application/json'};
    } else if (category == JokeCategory.chuckNorris) {
      endpoint = 'https://api.chucknorris.io/jokes/random';
      headers = {'Content-Type': 'application/json'};
    } else {
      // Default to JokeAPI for other categories
      String categoryParam = category == JokeCategory.all ? 'Any' : category.name;
      endpoint = 'https://v2.jokeapi.dev/joke/$categoryParam?safe-mode';
      headers = {'Content-Type': 'application/json'};
    }

    print('Using endpoint: $endpoint'); // Debug log
    print('Using headers: $headers'); // Debug log
    
    return http.get(Uri.parse(endpoint), headers: headers);
  }

  Future<void> fetchJoke({JokeCategory category = JokeCategory.all}) async {
    if (await _checkConnectivity()) {
      isLoading = true;
      notifyListeners();

      try {
        print('Starting joke fetch for category: ${category.name}'); // Debug log
        final response = await _getJokeFromApi(category);
        print('Response status: ${response.statusCode}'); // Debug log
        print('Response body: ${response.body}'); // Debug log

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Parsed data: $data'); // Debug log

          if (data is Map<String, dynamic>) {
            // Handle JokeAPI.dev response
            if (data.containsKey('type')) {
              if (data['type'] == 'single') {
                currentJoke = JokeModel(
                  id: data['id'].toString(),
                  value: data['joke'],
                  categories: [data['category']],
                  createdAt: DateTime.now(),
                );
                print('Created single joke: ${currentJoke?.value}'); // Debug log
              } else if (data['type'] == 'twopart') {
                currentJoke = JokeModel(
                  id: data['id'].toString(),
                  value: '${data['setup']} - ${data['delivery']}',
                  setup: data['setup'],
                  punchline: data['delivery'],
                  categories: [data['category']],
                  createdAt: DateTime.now(),
                );
                print('Created twopart joke: ${currentJoke?.value}'); // Debug log
              }
            }
            // Handle icanhazdadjoke response
            else if (data.containsKey('joke')) {
              currentJoke = JokeModel(
                id: data['id'].toString(),
                value: data['joke'],
                categories: ['dad'],
                createdAt: DateTime.now(),
              );
              print('Created dad joke: ${currentJoke?.value}'); // Debug log
            }
            // Handle Chuck Norris API response
            else if (data.containsKey('value')) {
              currentJoke = JokeModel(
                id: data['id'].toString(),
                value: data['value'],
                categories: ['chuck norris'],
                createdAt: DateTime.now(),
                iconUrl: data['icon_url'],
              );
              print('Created Chuck Norris joke: ${currentJoke?.value}'); // Debug log
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
        } else {
          print('Error: Non-200 status code: ${response.statusCode}'); // Debug log
        }
      } catch (e, stackTrace) {
        print('Error fetching joke: $e'); // Debug log
        print('Stack trace: $stackTrace'); // Debug log
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
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
    }
    _saveThemeMode();
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _themeMode.index);
  }

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    }
  }

  Future<void> speakJoke([JokeModel? jokeToSpeak]) async {
    final joke = jokeToSpeak ?? currentJoke;
    if (joke != null) {
      if (joke.setup != null) {
        await flutterTts.speak(joke.setup!);
        await Future.delayed(Duration(seconds: 2));
        await flutterTts.speak(joke.punchline!);
      } else {
        await flutterTts.speak(joke.value);
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

  Future<void> cacheJokes() async {
    final prefs = await SharedPreferences.getInstance();
    final jokes = await fetchBatchJokes();
    await prefs.setString('cached_jokes', json.encode(jokes));
  }

  Future<List<JokeModel>> fetchBatchJokes() async {
    List<JokeModel> jokes = [];
    for (int i = 0; i < 10; i++) {
      try {
        final response = await _getJokeFromApi(JokeCategory.all);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final joke = JokeModel.fromJson(data);
          jokes.add(joke);
        }
      } catch (e) {
        print('Error fetching batch joke: $e');
      }
    }
    return jokes;
  }

  Future<JokeModel?> getOfflineJoke() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_jokes');
    if (cached != null) {
      final jokes = json.decode(cached) as List;
      final random = Random().nextInt(jokes.length);
      return JokeModel.fromJson(jokes[random]);
    }
    return null;
  }

  Future<void> queueJokeForTTS(JokeModel joke) async {
    ttsQueue.add(joke);
    if (!isPlaying) {
      playNextInQueue();
    }
  }

  Future<void> playNextInQueue() async {
    if (ttsQueue.isEmpty) {
      isPlaying = false;
      return;
    }

    isPlaying = true;
    final joke = ttsQueue.removeFirst();
    await speakJoke(joke);
    playNextInQueue();
  }

  void setCurrentJoke(JokeModel joke) {
    currentJoke = joke;
    notifyListeners();
  }
}