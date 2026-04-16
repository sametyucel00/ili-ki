import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iliski_kocu_ai/core/services/providers.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';

final analysisActionProvider =
    AsyncNotifierProvider<AnalysisActionController, AnalysisRecord?>(AnalysisActionController.new);

class AnalysisActionController extends AsyncNotifier<AnalysisRecord?> {
  @override
  Future<AnalysisRecord?> build() async => null;

  Future<void> analyzeMessage({
    required String inputText,
    String? context,
    String? relationshipType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(analysisRepositoryProvider).createMessageAnalysis(
            message: inputText,
            context: context,
            relationshipType: relationshipType,
          ),
    );
  }

  Future<void> generateReplies({
    required String inputText,
    String? context,
    required String tone,
    required String responseLength,
    required bool emojiPreference,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(analysisRepositoryProvider).createReplyGeneration(
            message: inputText,
            context: context,
            tone: tone,
            responseLength: responseLength,
            emojiPreference: emojiPreference,
          ),
    );
  }

  Future<void> createStrategy({
    required String inputText,
    String? relationshipType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(analysisRepositoryProvider).createSituationStrategy(
            situation: inputText,
            relationshipType: relationshipType,
          ),
    );
  }
}
