enum JokeCategory { chuckNorris, programming, general, pun, knockKnock }

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