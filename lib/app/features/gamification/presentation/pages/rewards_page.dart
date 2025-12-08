import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_theme.dart';
import 'views/available_rewards_view.dart';
import 'views/redemption_history_view.dart';
import '../../../../core/services/role_permission_service.dart';
import '../../../../common/responsive/responsive_helper.dart';

class RewardsPage extends ConsumerStatefulWidget {
  const RewardsPage({super.key});

  @override
  ConsumerState<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends ConsumerState<RewardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isParent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          // Show point balance
          Consumer(
            builder: (context, ref, child) {
              final currentFamily = ref.watch(currentFamilyProvider);
              final currentUser = ref.watch(currentUserProvider);

              if (currentFamily == null || currentUser == null)
                return const SizedBox.shrink();

              final memberAsync = ref.watch(
                familyMemberProvider((currentFamily.id, currentUser.id)),
              );

              return memberAsync.when(
                data: (member) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: AppTheme.primaryColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${member?.points ?? 0}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AvailableRewardsView(), RedemptionHistoryView()],
      ),
      floatingActionButton: _isParent
          ? Padding(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.h(16)),
              child: FloatingActionButton(
                onPressed: () {
                  context.push('/rewards/create');
                },
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }
}
