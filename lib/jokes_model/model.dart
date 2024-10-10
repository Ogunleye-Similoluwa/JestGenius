class JokeModel {
  final List<dynamic> categories;
  final DateTime? createdAt;
  final String? iconUrl;
  final String id;
  final DateTime? updatedAt;
  final String? url;
  final String value;
  final String? setup;
  final String? punchline;
  bool isFavorite;

  JokeModel({
    required this.categories,
    this.createdAt,
    this.iconUrl,
    required this.id,
    this.updatedAt,
    this.url,
    required this.value,
    this.setup,
    this.punchline,
    this.isFavorite = false,
  });

  factory JokeModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("value")) {
      // Chuck Norris API
      return JokeModel(
        categories: List<dynamic>.from(json["categories"] ?? []),
        createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : null,
        iconUrl: json["icon_url"],
        id: json["id"],
        updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
        url: json["url"],
        value: json["value"],
      );
    } else {
      // Official Joke API
      return JokeModel(
        categories: [],
        id: json["id"].toString(),
        setup: json["setup"],
        punchline: json["punchline"],
        value: "${json["setup"]} ${json["punchline"]}",
      );
    }
  }

  Map<String, dynamic> toJson() => {
    "categories": List<dynamic>.from(categories.map((x) => x)),
    "created_at": createdAt?.toIso8601String(),
    "icon_url": iconUrl,
    "id": id,
    "updated_at": updatedAt?.toIso8601String(),
    "url": url,
    "value": value,
    "setup": setup,
    "punchline": punchline,
    "is_favorite": isFavorite,
  };
}