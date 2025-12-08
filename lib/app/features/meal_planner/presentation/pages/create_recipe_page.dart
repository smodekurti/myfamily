import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/recipe_model.dart';

class CreateRecipePage extends ConsumerStatefulWidget {
  final RecipeModel? existingRecipe;
  const CreateRecipePage({super.key, this.existingRecipe});

  @override
  ConsumerState<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends ConsumerState<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _cookTimeController;
  late final TextEditingController _servingsController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _instructionsController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final recipe = widget.existingRecipe;
    _titleController = TextEditingController(text: recipe?.title ?? '');
    _descriptionController = TextEditingController(
      text: recipe?.description ?? '',
    );
    _prepTimeController = TextEditingController(
      text: recipe?.prepTimeMinutes?.toString() ?? '',
    );
    _cookTimeController = TextEditingController(
      text: recipe?.cookTimeMinutes?.toString() ?? '',
    );
    _servingsController = TextEditingController(
      text: recipe?.servings.toString() ?? '4',
    );

    // Format ingredients for text area
    final ingredientsText =
        recipe?.ingredients?.map((i) => i['name']).join('\n') ?? '';
    _ingredientsController = TextEditingController(text: ingredientsText);

    // Format instructions for text area
    final instructionsText = recipe?.instructions?.join('\n') ?? '';
    _instructionsController = TextEditingController(text: instructionsText);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final familyId = ref.read(currentFamilyIdProvider);
      if (familyId == null) throw Exception('No family selected');

      // Parse ingredients
      final ingredientsList = _ingredientsController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => {'name': line.trim(), 'quantity': '', 'unit': ''})
          .toList();

      final instructionsList = _instructionsController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (widget.existingRecipe != null) {
        // Update existing recipe
        final updatedRecipe = widget.existingRecipe!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          prepTimeMinutes: int.tryParse(_prepTimeController.text),
          cookTimeMinutes: int.tryParse(_cookTimeController.text),
          servings: int.tryParse(_servingsController.text) ?? 4,
          ingredients: ingredientsList,
          instructions: instructionsList,
        );

        await ref.read(recipeRepositoryProvider).updateRecipe(updatedRecipe);
      } else {
        // Create new recipe
        await ref
            .read(recipeRepositoryProvider)
            .createRecipe(
              familyId: familyId,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              prepTimeMinutes: int.tryParse(_prepTimeController.text),
              cookTimeMinutes: int.tryParse(_cookTimeController.text),
              servings: int.tryParse(_servingsController.text) ?? 4,
              ingredients: ingredientsList,
              instructions: instructionsList,
            );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRecipe != null
                  ? 'Recipe updated!'
                  : 'Recipe created!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving recipe: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Recipe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Recipe Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _prepTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Prep Time (min)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cookTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Cook Time (min)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _servingsController,
                        decoration: const InputDecoration(
                          labelText: 'Servings',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter one ingredient per line',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ingredientsController,
                  decoration: const InputDecoration(
                    hintText: 'e.g.\n2 Eggs\n1 cup Flour',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter one step per line',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    hintText: 'e.g.\nMix ingredients.\nBake at 350F.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _saveRecipe,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? 'Saving...' : 'Save Recipe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
