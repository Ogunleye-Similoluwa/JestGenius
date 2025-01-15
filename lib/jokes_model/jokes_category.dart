import 'package:flutter/material.dart';

enum JokeCategory {
  all('All Jokes', Icons.all_inclusive),
  programming('Programming', Icons.code),
  pun('Puns', Icons.sentiment_very_satisfied),
  dad('Dad Jokes', Icons.face_retouching_natural),
  knockKnock('Knock Knock', Icons.door_front_door),
  chuckNorris('Chuck Norris', Icons.sports_martial_arts),
  oneLiners('One Liners', Icons.short_text);

  final String label;
  final IconData icon;
  const JokeCategory(this.label, this.icon);
}

class JokeStats {
  int jokesRead;
  int favorited;
  int shared;

  JokeStats({this.jokesRead = 0, this.favorited = 0, this.shared = 0});

  Map<String, dynamic> toJson() => {
    'jokesRead': jokesRead,
    'favorited': favorited,
    'shared': shared,
  };

  factory JokeStats.fromJson(Map<String, dynamic> json) => JokeStats(
    jokesRead: json['jokesRead'] ?? 0,
    favorited: json['favorited'] ?? 0,
    shared: json['shared'] ?? 0,
  );
}