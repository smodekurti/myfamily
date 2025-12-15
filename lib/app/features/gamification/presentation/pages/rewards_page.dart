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
import '../../../../core/services/gemini_service.dart';

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

              if (currentFamily == null || currentUser == null) {
                return const SizedBox.shrink();
              }

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
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                  _showAddOptions(context);
                },
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: AppTheme.primaryColor),
              ),
              title: const Text('Create Custom Reward'),
              onTap: () {
                Navigator.pop(context);
                context.push('/rewards/create');
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.purple),
              ),
              title: const Text('AI Reward Suggestions'),
              subtitle: const Text('Get creative ideas based on interests'),
              onTap: () {
                Navigator.pop(context);
                _showMagicRewardDialog(context);
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  void _showMagicRewardDialog(BuildContext context) {
    final ageController = TextEditingController();
    final interestsController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple),
                SizedBox(width: 8.w),
                const Text('Magic Suggestions'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the child\'s details to get personalized reward ideas.',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: interestsController,
                  decoration: const InputDecoration(
                    labelText: 'Interests (e.g. Lego, Outdoors)',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (isLoading) ...[
                  SizedBox(height: 20.h),
                  const CircularProgressIndicator(),
                  SizedBox(height: 8.h),
                  const Text('Generating ideas...'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (ageController.text.isEmpty) return;

                        setState(() => isLoading = true);

                        try {
                          final age = int.tryParse(ageController.text) ?? 5;
                          final interests = interestsController.text
                              .split(',')
                              .where((e) => e.trim().isNotEmpty)
                              .map((e) => e.trim())
                              .toList();

                          final suggestions = await ref
                              .read(geminiServiceProvider)
                              .generateRewardSuggestions(
                                age: age,
                                interests: interests,
                              );

                          if (!context.mounted) return;

                          Navigator.pop(context); // Close input dialog
                          _showSuggestionsResult(context, suggestions);
                        } catch (e) {
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to generate: $e')),
                            );
                          }
                        }
                      },
                child: const Text('Generate'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuggestionsResult(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggested Rewards'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return ListTile(
                title: Text(item['title'] ?? 'Unknown'),
                subtitle: Text(item['description'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item['cost'] ?? 0} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () => _addSuggestedReward(context, item),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSuggestedReward(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      final currentFamily = ref.read(currentFamilyProvider);

      if (currentUser == null || currentFamily == null) return;

      await ref
          .read(rewardRepositoryProvider)
          .createReward(
            familyId: currentFamily.id,
            createdBy: currentUser.id,
            title: item['title'],
            description: item['description'],
            cost: item['cost'] is int
                ? item['cost']
                : int.tryParse(item['cost'].toString()) ?? 100,
            icon: 'star',
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${item['title']}" to rewards!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding reward: $e')));
      }
    }
  }
}
