import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';

class HistoryRepository {
  HistoryRepository({
    required LocalCacheService cache,
  }) : _cache = cache;

  final LocalCacheService _cache;

  Future<List<AnalysisRecord>> getHistory({bool favoritesOnly = false}) async {
    final cached = await _cache.readCachedAnalyses();
    final records = cached.map(AnalysisRecord.fromMap).toList();
    if (!favoritesOnly) {
      return records;
    }
    return records.where((item) => item.isFavorite).toList();
  }
}
