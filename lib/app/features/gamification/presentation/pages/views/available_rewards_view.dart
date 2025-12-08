import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:myfamily/app/core/providers/providers.dart';
import 'package:myfamily/app/core/theme/app_theme.dart';
import 'package:myfamily/app/data/models/reward_model.dart';
import 'package:myfamily/app/core/services/role_permission_service.dart';

class AvailableRewardsView extends ConsumerStatefulWidget {
  const AvailableRewardsView({super.key});

  @override
  ConsumerState<AvailableRewardsView> createState() =>
      _AvailableRewardsViewState();
}

class _AvailableRewardsViewState extends ConsumerState<AvailableRewardsView> {
  bool _isParent = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  void _checkRole() async {
    final currentUser = ref.read(currentUserProvider);
    final currentFamily = ref.read(currentFamilyProvider);

    if (currentUser != null && currentFamily != null) {
      final role = await RolePermissionService().getUserRole(
        currentUser.id,
        currentFamily.id,
      );
      if (mounted) {
        setState(() {
          _isParent = role == 'parent' || role == 'admin';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);

    if (currentFamily == null) {
      return const Center(child: Text('No family selected'));
    }

    final rewardsAsync = ref.watch(familyRewardsProvider(currentFamily.id));

    return rewardsAsync.when(
      data: (rewards) {
        if (rewards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64.sp,
                  color: Colors.grey,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No rewards available yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isParent)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Tap + to create one',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16.r),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 0.8,
          ),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            final reward = rewards[index];
            return _RewardCard(
              reward: reward,
              isParent: _isParent,
              onRedeem: () => _redeemReward(reward),
              onEdit: () => _editReward(reward),
              onDelete: () => _deleteReward(reward),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _redeemReward(RewardModel reward) async {
    final currentFamily = ref.read(currentFamilyProvider);
    final currentUser = ref.read(currentUserProvider);

    if (currentFamily == null || currentUser == null) return;

    // Check points locally first
    try {
      final memberAsync = await ref.read(
        familyMemberProvider((currentFamily.id, currentUser.id)).future,
      );

      if (memberAsync == null) return;

      if (memberAsync.points < reward.cost) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Not enough points!')));
        }
        return;
      }

      // Confirm dialog
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Redeem ${reward.title}?'),
            content: Text('This will cost ${reward.cost} points.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Redeem'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          try {
            await ref
                .read(rewardRepositoryProvider)
                .redeemReward(
                  familyId: currentFamily.id,
                  userId: currentUser.id,
                  rewardId: reward.id,
                  cost: reward.cost,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Requested! Waiting for parent approval.'),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed: $e')));
            }
          }
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  void _editReward(RewardModel reward) {
    // Navigate to edit page
    // context.push('/rewards/edit/${reward.id}'); // Or modal bottom sheet
    // For MVP/first pass, maybe just show snackbar "Coming Soon" or implement basic dialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit coming soon')));
  }

  void _deleteReward(RewardModel reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(rewardRepositoryProvider)
            .deleteReward(reward.id, reward.familyId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _RewardCard extends StatelessWidget {
  final RewardModel reward;
  final bool isParent;
  final VoidCallback onRedeem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RewardCard({
    required this.reward,
    required this.isParent,
    required this.onRedeem,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: isParent ? onEdit : onRedeem,
        onLongPress: isParent ? onDelete : null,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconData(reward.icon),
                size: 48.sp,
                color: AppTheme.primaryColor,
              ),
              const Spacer(),
              Text(
                reward.title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${reward.cost} pts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
