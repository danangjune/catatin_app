class User {
  final int id;
  final String name;
  final String email;
  final Map<String, dynamic> monthlyStats; // Monthly statistics

  User({
    required this.id,
    required this.name,
    required this.email,
    this.monthlyStats = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      monthlyStats: json['monthly_stats'] ?? {},
    );
  }
}
