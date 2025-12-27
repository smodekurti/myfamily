import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/meal_vote_model.dart';
import '../../../../core/services/gemini_service.dart';

class MealPlannerVotingDialog extends ConsumerStatefulWidget {
  final String mealType;
  final DateTime date;
  final List<String> dietaryTags;
  final List<String> cuisines;

  // In a real app, you'd pass the session ID or callback to save
  final Function(MealVoteSessionModel) onSessionCreated;

  const MealPlannerVotingDialog({
    super.key,
    required this.mealType,
    required this.date,
    this.dietaryTags = const [],
    this.cuisines = const [],
    required this.onSessionCreated,
  });

  @override
  ConsumerState<MealPlannerVotingDialog> createState() =>
      _MealPlannerVotingDialogState();
}

class _MealPlannerVotingDialogState
    extends ConsumerState<MealPlannerVotingDialog> {
  bool _isLoading = false;
  List<MealVoteOption>? _options;
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  Future<void> _generateOptions() async {
    setState(() => _isLoading = true);
    try {
      final gemini = ref.read(geminiServiceProvider);
      final rawOptions = await gemini.generateMealOptions(
        mealType: widget.mealType,
        dietaryTags: widget.dietaryTags,
        cuisines: widget.cuisines,
      );

      if (mounted) {
        setState(() {
          _options = rawOptions
              .map(
                (o) => MealVoteOption(
                  title: o['title'] ?? 'Option',
                  description: o['description'] ?? '',
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate options: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Vote for ${widget.mealType}'),
      content: _isLoading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chef is thinking up ideas...'),
              ],
            )
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Which meal sounds best?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_options != null)
                    ..._options!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = _selectedOptionIndex == index;

                      return Card(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedOptionIndex = index),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  option.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(option.description),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isLoading || _selectedOptionIndex == null
              ? null
              : () {
                  final session = MealVoteSessionModel(
                    id: DateTime.now().toIso8601String(), // Temporary ID logic
                    familyId: 'current_family', // Placeholder
                    mealDate: widget.date,
                    mealType: widget.mealType,
                    options: _options!,
                    status: 'active',
                    createdAt: DateTime.now(),
                    votes: {
                      'current_user': _selectedOptionIndex!,
                    }, // Auto-vote creator
                  );
                  widget.onSessionCreated(session);
                  Navigator.pop(context);
                },
          icon: const Icon(Icons.how_to_vote),
          label: const Text('Start Vote'),
        ),
      ],
    );
  }
}
