class BlockScreenTheme {
  final String id;
  final String color; // Hex color string
  final String quote;

  BlockScreenTheme({
    required this.id,
    required this.color,
    required this.quote,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'color': color, 'quote': quote};
  }

  factory BlockScreenTheme.fromJson(Map<String, dynamic> json) {
    return BlockScreenTheme(
      id: json['id'],
      color: json['color'],
      quote: json['quote'],
    );
  }

  BlockScreenTheme copyWith({String? id, String? color, String? quote}) {
    return BlockScreenTheme(
      id: id ?? this.id,
      color: color ?? this.color,
      quote: quote ?? this.quote,
    );
  }
}
