import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/case_model.dart';

final casesRepositoryProvider = Provider((ref) => CasesRepository());

class CasesRepository {
  final _supabase = Supabase.instance.client;

  Stream<List<CaseModel>> watchCases() {
    return _supabase
        .from('cases')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((e) => CaseModel.fromJson(e)).toList());
  }

  Future<List<CaseModel>> getCases() async {
    try {
      final response = await _supabase
          .from('cases')
          .select('*, profiles:author_id(full_name)')
          .order('created_at', ascending: false);

      return (response as List).map((e) => CaseModel.fromJson(e)).toList();
    } catch (e) {
      // If table doesn't exist or other error, return empty for now to prevent crash
      // print('Error fetching cases: $e');
      return [];
    }
  }

  Future<void> createCase(
    String title,
    String body,
    List<String> images,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _supabase.from('cases').insert({
      'author_id': user.id,
      'title': title,
      'body': body,
      'images': images,
    });
  }

  Future<List<CaseComment>> getComments(String caseId) async {
    try {
      final response = await _supabase
          .from('case_comments')
          .select('*, profiles:author_id(full_name)')
          .eq('case_id', caseId)
          .order('created_at', ascending: true);

      return (response as List).map((e) => CaseComment.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addComment(String caseId, String body) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _supabase.from('case_comments').insert({
      'case_id': caseId,
      'author_id': user.id,
      'body': body,
    });
  }
}
