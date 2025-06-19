class CheckInEntry {
  final int timestamp;
  final int rating;
  final String journalText;

  CheckInEntry({
    required this.timestamp,
    required this.rating,
    required this.journalText,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'rating': rating,
      'journalText': journalText,
    };
  }

  factory CheckInEntry.fromJson(Map<String, dynamic> json) {
    return CheckInEntry(
      timestamp: json['timestamp'] as int,
      rating: json['rating'] as int,
      journalText: json['journalText'] as String,
    );
  }
} 