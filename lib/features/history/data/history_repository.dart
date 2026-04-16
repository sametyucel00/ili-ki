import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';

class HistoryRepository {
  HistoryRepository({
    required FirebaseFirestore firestore,
    required LocalCacheService cache,
  })  : _firestore = firestore,
        _cache = cache;

  final FirebaseFirestore _firestore;
  final LocalCacheService _cache;

  Future<List<AnalysisRecord>> getHistory({bool favoritesOnly = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      final cached = await _cache.readCachedAnalyses();
      return cached.map(AnalysisRecord.fromMap).toList();
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('analyses')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
    if (favoritesOnly) {
      query = query.where('isFavorite', isEqualTo: true);
    }
    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      final cached = await _cache.readCachedAnalyses();
      return cached.map(AnalysisRecord.fromMap).toList();
    }
    return snapshot.docs.map((doc) => AnalysisRecord.fromMap(doc.data())).toList();
  }
}
