import 'package:cloud_firestore/cloud_firestore.dart';

enum AnalysisType { messageAnalysis, replyGeneration, situationStrategy }

class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.uid,
    required this.type,
    required this.inputText,
    required this.contextText,
    required this.relationshipType,
    required this.tone,
    required this.responseLength,
    required this.emojiPreference,
    required this.aiSummary,
    required this.aiIntent,
    required this.aiRiskFlags,
    required this.aiSuggestedAction,
    required this.aiReplyOptions,
    required this.rawModelOutput,
    required this.creditsUsed,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    required this.neutralityNote,
    required this.clarityLevel,
    required this.interestLevel,
    required this.avoidNow,
    required this.nextSteps,
    required this.likelyDynamics,
    required this.optionalMessage,
  });

  final String id;
  final String uid;
  final AnalysisType type;
  final String inputText;
  final String? contextText;
  final String? relationshipType;
  final String? tone;
  final String? responseLength;
  final bool? emojiPreference;
  final String aiSummary;
  final String? aiIntent;
  final List<String> aiRiskFlags;
  final String aiSuggestedAction;
  final List<String> aiReplyOptions;
  final Map<String, dynamic> rawModelOutput;
  final int creditsUsed;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? neutralityNote;
  final String? clarityLevel;
  final String? interestLevel;
  final List<String> avoidNow;
  final List<String> nextSteps;
  final List<String> likelyDynamics;
  final String? optionalMessage;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'type': type.name,
      'inputText': inputText,
      'contextText': contextText,
      'relationshipType': relationshipType,
      'tone': tone,
      'responseLength': responseLength,
      'emojiPreference': emojiPreference,
      'aiSummary': aiSummary,
      'aiIntent': aiIntent,
      'aiRiskFlags': aiRiskFlags,
      'aiSuggestedAction': aiSuggestedAction,
      'aiReplyOptions': aiReplyOptions,
      'rawModelOutput': rawModelOutput,
      'creditsUsed': creditsUsed,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'neutralityNote': neutralityNote,
      'clarityLevel': clarityLevel,
      'interestLevel': interestLevel,
      'avoidNow': avoidNow,
      'nextSteps': nextSteps,
      'likelyDynamics': likelyDynamics,
      'optionalMessage': optionalMessage,
    };
  }

  factory AnalysisRecord.fromMap(Map<String, dynamic> map) {
    DateTime ts(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return AnalysisRecord(
      id: map['id'] as String,
      uid: map['uid'] as String,
      type: AnalysisType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => AnalysisType.messageAnalysis,
      ),
      inputText: (map['inputText'] as String?) ?? '',
      contextText: map['contextText'] as String?,
      relationshipType: map['relationshipType'] as String?,
      tone: map['tone'] as String?,
      responseLength: map['responseLength'] as String?,
      emojiPreference: map['emojiPreference'] as bool?,
      aiSummary: (map['aiSummary'] as String?) ?? '',
      aiIntent: map['aiIntent'] as String?,
      aiRiskFlags: ((map['aiRiskFlags'] as List?) ?? const []).cast<String>(),
      aiSuggestedAction: (map['aiSuggestedAction'] as String?) ?? '',
      aiReplyOptions: ((map['aiReplyOptions'] as List?) ?? const []).cast<String>(),
      rawModelOutput: (map['rawModelOutput'] as Map?)?.cast<String, dynamic>() ?? const {},
      creditsUsed: (map['creditsUsed'] as num?)?.toInt() ?? 0,
      isFavorite: (map['isFavorite'] as bool?) ?? false,
      createdAt: ts(map['createdAt']),
      updatedAt: ts(map['updatedAt']),
      neutralityNote: map['neutralityNote'] as String?,
      clarityLevel: map['clarityLevel'] as String?,
      interestLevel: map['interestLevel'] as String?,
      avoidNow: ((map['avoidNow'] as List?) ?? const []).cast<String>(),
      nextSteps: ((map['nextSteps'] as List?) ?? const []).cast<String>(),
      likelyDynamics: ((map['likelyDynamics'] as List?) ?? const []).cast<String>(),
      optionalMessage: map['optionalMessage'] as String?,
    );
  }
}
