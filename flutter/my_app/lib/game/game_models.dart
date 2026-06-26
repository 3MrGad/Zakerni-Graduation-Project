class QuestionState {
  final int    questionNumber;
  final int    total;
  final int    score;
  final int    highScore;
  final String imagePath;
  final List<String> options;
  final String levelLabel;
  final String levelColor;
  final int    timeLimit;
  final String feedback;    // "correct" | actual name | ""
  final String hint;        // first letter or ""
  final String? levelMessage;

  QuestionState({
    required this.questionNumber,
    required this.total,
    required this.score,
    required this.highScore,
    required this.imagePath,
    required this.options,
    required this.levelLabel,
    required this.levelColor,
    required this.timeLimit,
    required this.feedback,
    required this.hint,
    this.levelMessage,
  });

  factory QuestionState.fromJson(Map<String, dynamic> j) => QuestionState(
    questionNumber: j['question'] as int,
    total:          j['total']    as int,
    score:          j['score']    as int,
    highScore:      j['high_score'] as int,
    imagePath:      j['image_path'] as String? ?? '',
    options:        List<String>.from(j['options'] as List),
    levelLabel:     j['level_label'] as String,
    levelColor:     j['level_color'] as String,
    timeLimit:      j['time_limit']  as int,
    feedback:       j['feedback']    as String? ?? '',
    hint:           j['hint']        as String? ?? '',
    levelMessage:   j['level_message'] as String?,
  );
}

class ResultState {
  final String username;
  final int    score;
  final int    total;
  final double accuracy;
  final String level;
  final int    highScore;
  final bool   newRecord;
  final double avgTime;
  final List<Map<String, dynamic>> hardest;
  final List<Map<String, dynamic>> easiest;
  final List<Map<String, dynamic>> confusionPairs;
  final List<Map<String, dynamic>> dailyHistory;
  final Map<String, dynamic>       summary;

  ResultState({
    required this.username,
    required this.score,
    required this.total,
    required this.accuracy,
    required this.level,
    required this.highScore,
    required this.newRecord,
    required this.avgTime,
    required this.hardest,
    required this.easiest,
    required this.confusionPairs,
    required this.dailyHistory,
    required this.summary,
  });

  factory ResultState.fromJson(Map<String, dynamic> j) => ResultState(
    username:       j['username']   as String,
    score:          j['score']      as int,
    total:          j['total']      as int,
    accuracy:       (j['accuracy']  as num).toDouble(),
    level:          j['level']      as String,
    highScore:      j['high_score'] as int,
    newRecord:      j['new_record'] as bool,
    avgTime:        (j['avg_time']  as num).toDouble(),
    hardest:        List<Map<String, dynamic>>.from(j['hardest'] as List),
    easiest:        List<Map<String, dynamic>>.from(j['easiest'] as List),
    confusionPairs: List<Map<String, dynamic>>.from(j['confusion_pairs'] as List),
    dailyHistory:   List<Map<String, dynamic>>.from(j['daily_history'] as List),
    summary:        j['summary']    as Map<String, dynamic>,
  );
}
