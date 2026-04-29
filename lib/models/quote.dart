class Quote {
  final String id;
  final String text;
  final List<String> tags;
  final bool isFavourite;

  Quote({
    required this.id,
    required this.text,
    required this.tags,
    this.isFavourite = false,
  });

  Quote copyWith({
    String? text,
    List<String>? tags,
    bool? isFavourite,
  }) {
    return Quote(
      id: id,
      text: text ?? this.text,
      tags: tags ?? this.tags,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'tags': tags.join(','),
      'isFavourite': isFavourite,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      text: map['text'],
      tags: map['tags'].isEmpty ? [] : map['tags'].split(','),
      isFavourite: map['isFavourite'] ?? false,
    );
  }
}