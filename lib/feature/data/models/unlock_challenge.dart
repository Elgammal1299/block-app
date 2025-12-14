enum ChallengeType {
  math,
  typing,
  timer,
}

class UnlockChallenge {
  final ChallengeType type;
  final String question;
  final String answer;
  final int timerSeconds;

  UnlockChallenge({
    required this.type,
    required this.question,
    required this.answer,
    this.timerSeconds = 30,
  });

  // Create from JSON
  factory UnlockChallenge.fromJson(Map<String, dynamic> json) {
    return UnlockChallenge(
      type: ChallengeType.values.firstWhere(
        (e) => e.toString() == 'ChallengeType.${json['type']}',
        orElse: () => ChallengeType.math,
      ),
      question: json['question'] as String,
      answer: json['answer'] as String,
      timerSeconds: json['timerSeconds'] as int? ?? 30,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'question': question,
      'answer': answer,
      'timerSeconds': timerSeconds,
    };
  }

  @override
  String toString() {
    return 'UnlockChallenge{type: $type, question: $question}';
  }
}
