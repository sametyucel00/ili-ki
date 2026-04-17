import 'package:iliski_kocu_ai/core/services/local_cache_service.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';

class HistoryRepository {
  HistoryRepository({
    required LocalCacheService cache,
  }) : _cache = cache;

  final LocalCacheService _cache;

  Future<List<AnalysisRecord>> getHistory({bool favoritesOnly = false}) async {
    final cached = await _cache.readCachedAnalyses();
    final records = <AnalysisRecord>[];
    for (final item in cached) {
      try {
        records.add(AnalysisRecord.fromMap(item));
      } catch (_) {
        // Skip old or malformed local records so history never opens blank.
      }
    }
    if (!favoritesOnly) {
      return records;
    }
    return records.where((item) => item.isFavorite).toList();
  }
}
