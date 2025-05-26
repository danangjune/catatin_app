class Alert {
  final int? id;
  final String title;
  final String description;
  final String type; // 'deficit', 'transaction', 'category', 'income'
  final String severity; // 'high', 'medium', 'low'
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>?
  metadata; // For storing additional data like amounts

  Alert({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      severity: json['severity'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      metadata: json['metadata'],
    );
  }
}
