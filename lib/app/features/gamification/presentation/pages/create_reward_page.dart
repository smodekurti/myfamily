import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/role_permission_service.dart';

class CreateRewardPage extends ConsumerStatefulWidget {
  const CreateRewardPage({super.key});

  @override
  ConsumerState<CreateRewardPage> createState() => _CreateRewardPageState();
}

class _CreateRewardPageState extends ConsumerState<CreateRewardPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  String _selectedIcon = 'star';
  bool _isLoading = false;

  final List<String> _icons = [
    'star',
    'icecream',
    'videogame_asset',
    'shopping_bag',
    'movie',
    'phone_iphone',
    'directions_car',
    'card_giftcard',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _createReward() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentFamily = ref.read(currentFamilyProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentFamily == null || currentUser == null) {
        throw Exception('Family or User not found');
      }

      await ref
          .read(rewardRepositoryProvider)
          .createReward(
            familyId: currentFamily.id,
            createdBy: currentUser.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            cost: int.parse(_costController.text),
            icon: _selectedIcon,
          );

      // Force refresh the list (fallback if realtime is not enabled)
      ref.invalidate(familyRewardsProvider(currentFamily.id));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      appBar: AppBar(title: const Text('Create Reward')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Ice Cream, Movie Night',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Details about the reward',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost (Points)',
                  hintText: 'e.g., 500',
                  suffixText: 'pts',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter cost';
                  if (int.tryParse(value) == null) return 'Must be a number';
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              Text(
                'Select Icon',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _getIconData(icon),
                        color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        size: 32.sp,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 32.h),
              FilledButton(
                onPressed: _isLoading ? null : _createReward,
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Reward'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'icecream':
        return Icons.icecream;
      case 'videogame_asset':
        return Icons.videogame_asset;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'phone_iphone':
        return Icons.phone_iphone;
      case 'directions_car':
        return Icons.directions_car;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.stars;
    }
  }
}
