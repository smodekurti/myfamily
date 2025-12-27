import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_vote_model.freezed.dart';
part 'meal_vote_model.g.dart';

@freezed
class MealVoteSessionModel with _$MealVoteSessionModel {
  const factory MealVoteSessionModel({
    required String id,
    required String familyId,
    required DateTime mealDate,
    required String mealType,
    required List<MealVoteOption> options,
    @Default({}) Map<String, int> votes, // userId -> optionIndex
    @Default('active') String status, // 'active', 'completed'
    int? winnerOptionIndex,
    DateTime? createdAt,
  }) = _MealVoteSessionModel;

  factory MealVoteSessionModel.fromJson(Map<String, dynamic> json) =>
      _$MealVoteSessionModelFromJson(json);
}

@freezed
class MealVoteOption with _$MealVoteOption {
  const factory MealVoteOption({
    required String title,
    required String description,
  }) = _MealVoteOption;

  factory MealVoteOption.fromJson(Map<String, dynamic> json) =>
      _$MealVoteOptionFromJson(json);
}
