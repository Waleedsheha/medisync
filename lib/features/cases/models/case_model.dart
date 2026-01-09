class CaseModel {
  final String id;
  final String authorId;
  final String title;
  final String? body;
  final List<String> images;
  final DateTime createdAt;
  final String? authorName; // Joined from profiles if available

  CaseModel({
    required this.id,
    required this.authorId,
    required this.title,
    this.body,
    required this.images,
    required this.createdAt,
    this.authorName,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    final joinedName = profiles is Map ? profiles['full_name']?.toString() : null;
    return CaseModel(
      id: json['id'],
      authorId: json['author_id'],
      title: json['title'],
      body: json['body'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      createdAt: DateTime.parse(json['created_at']),
      authorName: joinedName ?? json['author_name']?.toString(),
    );
  }
}

class CaseComment {
  final String id;
  final String caseId;
  final String authorId;
  final String body;
  final DateTime createdAt;
  final String? authorName;

  CaseComment({
    required this.id,
    required this.caseId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.authorName,
  });

  factory CaseComment.fromJson(Map<String, dynamic> json) {
    return CaseComment(
      id: json['id'],
      caseId: json['case_id'],
      authorId: json['author_id'],
      body: json['body'],
      createdAt: DateTime.parse(json['created_at']),
      authorName: json['profiles']?['full_name'],
    );
  }
}
