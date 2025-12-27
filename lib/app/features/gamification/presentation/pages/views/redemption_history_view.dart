import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:myfamily/app/core/providers/providers.dart';
import 'package:myfamily/app/core/theme/app_theme.dart';
import 'package:myfamily/app/data/models/reward_redemption_model.dart';
import 'package:myfamily/app/core/services/role_permission_service.dart';

class RedemptionHistoryView extends ConsumerStatefulWidget {
  const RedemptionHistoryView({super.key});

  @override
  ConsumerState<RedemptionHistoryView> createState() =>
      _RedemptionHistoryViewState();
}

class _RedemptionHistoryViewState extends ConsumerState<RedemptionHistoryView> {
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
    final currentUser = ref.watch(currentUserProvider);

    if (currentFamily == null || currentUser == null) {
      return const SizedBox.shrink();
    }

    if (_isParent) {
      return _buildParentView(currentFamily.id);
    } else {
      return _buildChildView(currentFamily.id, currentUser.id);
    }
  }

  Widget _buildParentView(String familyId) {
    final redemptionsAsync = ref.watch(familyRedemptionsProvider(familyId));

    return redemptionsAsync.when(
      data: (redemptions) {
        final pending = redemptions
            .where((r) => r.status == 'pending')
            .toList();
        final history = redemptions
            .where((r) => r.status != 'pending')
            .toList();

        if (redemptions.isEmpty) {
          return const Center(child: Text('No redemption history'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(familyRedemptionsProvider(familyId));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              if (pending.isNotEmpty) ...[
                Text(
                  'Pending Approval',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                ...pending.map(
                  (r) => _RedemptionTile(redemption: r, isParent: true),
                ),
                SizedBox(height: 24.h),
              ],
              Text(
                'History',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              ...history.map(
                (r) => _RedemptionTile(redemption: r, isParent: true),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildChildView(String familyId, String userId) {
    final redemptionsAsync = ref.watch(
      userRedemptionsFamilyProvider((familyId, userId)),
    );

    return redemptionsAsync.when(
      data: (redemptions) {
        if (redemptions.isEmpty) {
          return const Center(
            child: Text('You haven\'t redeemed any rewards yet'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userRedemptionsFamilyProvider((familyId, userId)));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: redemptions.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              return _RedemptionTile(
                redemption: redemptions[index],
                isParent: false,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _RedemptionTile extends ConsumerWidget {
  final RewardRedemptionModel redemption;
  final bool isParent;

  const _RedemptionTile({required this.redemption, required this.isParent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getStatusColor(redemption.status);
    final icon = _getStatusIcon(redemption.status);

    // For pending items visible to parents, show action buttons
    final showActions = isParent && redemption.status == 'pending';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.stars,
            color: AppTheme.primaryColor,
          ), // Ideally reward icon
        ),
        title: Text(redemption.rewardTitle ?? 'Unknown Reward'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (redemption.userName != null)
              Text('Requested by ${redemption.userName}'),
            Text(
              '${redemption.costAtRedemption} pts • ${DateFormat.MMMd().format(redemption.redeemedAt ?? DateTime.now())}',
            ),
          ],
        ),
        trailing: showActions
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _updateStatus(context, ref, 'approved'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _updateStatus(context, ref, 'rejected'),
                  ),
                ],
              )
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14.sp, color: color),
                    SizedBox(width: 4.w),
                    Text(
                      redemption.status.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref
          .read(rewardRepositoryProvider)
          .updateRedemptionStatus(
            redemptionId: redemption.id,
            status: status,
            familyId: redemption.familyId,
          );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'fulfilled':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'approved':
        return Icons.check_circle;
      case 'fulfilled':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
