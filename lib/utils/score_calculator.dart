class ScoreCalculator {
  static const weights = {
    'income_ratio': 0.35,
    'saving_consistency': 0.25,
    'unexpected_expense': 0.15,
    'record_frequency': 0.15,
    'saving_percentage': 0.10,
  };

  static double calculateFinalScore(Map<String, double> scores) {
    return (scores['income_ratio']! * weights['income_ratio']!) +
        (scores['saving_consistency']! * weights['saving_consistency']!) +
        (scores['unexpected_expense']! * weights['unexpected_expense']!) +
        (scores['record_frequency']! * weights['record_frequency']!) +
        (scores['saving_percentage']! * weights['saving_percentage']!);
  }
}
