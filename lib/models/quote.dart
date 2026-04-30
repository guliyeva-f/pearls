class Quote {
  final String id;
  final String text;
  final List<String> tags;
  final bool isFavourite;
  final DateTime? date;

  Quote({
    required this.id,
    required this.text,
    required this.tags,
    this.isFavourite = false,
    this.date,
  });

  Quote copyWith({
    String? text,
    List<String>? tags,
    bool? isFavourite,
    DateTime? date,
  }) {
    return Quote(
      id: id,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      isFavourite: isFavourite ?? this.isFavourite,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'tags': tags.join(','),
      'isFavourite': isFavourite,
      'date': date?.toIso8601String(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as String,
      text: map['text'] as String,
      tags: (map['tags'] as String).isEmpty
          ? []
          : (map['tags'] as String).split(','),
      isFavourite: map['isFavourite'] as bool? ?? false,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String)
          : null,
    );
  }
}