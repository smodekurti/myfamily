import 'package:flutter/material.dart';
import '../../../../core/extensions/user_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/family_model.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/modern_header.dart';
import '../../../../common/widgets/modern_card.dart';

class FamilySettingsPage extends ConsumerStatefulWidget {
  const FamilySettingsPage({super.key});

  @override
  ConsumerState<FamilySettingsPage> createState() => _FamilySettingsPageState();
}

class _FamilySettingsPageState extends ConsumerState<FamilySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeData(FamilyModel? family) {
    if (family != null) {
      _nameController.text = family.name;
      _addressController.text = family.address ?? '';
    }
  }

  Future<void> _saveFamily() async {
    if (!_formKey.currentState!.validate()) return;

    final currentFamily = ref.read(currentFamilyProvider);
    if (currentFamily == null) return;

    setState(() => _isLoading = true);

    try {
      final familyRepo = ref.read(familyRepositoryProvider);
      await familyRepo.updateFamily(
        familyId: currentFamily.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      // Invalidate family provider to refresh
      ref.invalidate(familyProvider(currentFamily.id));
      ref.invalidate(currentFamilyProvider);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Family settings updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update family: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _regenerateInviteCode(bool isAdult) async {
    final currentFamily = ref.read(currentFamilyProvider);
    if (currentFamily == null) return;

    try {
      final familyRepo = ref.read(familyRepositoryProvider);
      if (isAdult) {
        await familyRepo.generateInviteCodeForFamily(currentFamily.id);
      } else {
        await familyRepo.generateChildInviteCodeForFamily(currentFamily.id);
      }

      // Invalidate to refresh
      ref.invalidate(familyProvider(currentFamily.id));
      ref.invalidate(currentFamilyProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isAdult ? "Adult" : "Child"} invite code regenerated!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate code: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final currentFamily = ref.read(currentFamilyProvider);
    if (currentFamily == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $memberName from this family?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final familyRepo = ref.read(familyRepositoryProvider);
      await familyRepo.removeFamilyMember(
        familyId: currentFamily.id,
        uid: memberId,
      );

      // Invalidate to refresh
      ref.invalidate(familyMembersProvider(currentFamily.id));
      ref.invalidate(familyProvider(currentFamily.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$memberName has been removed from the family'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveFamily() async {
    final currentFamily = ref.read(currentFamilyProvider);
    final currentUser = ref.read(currentUserProvider);
    if (currentFamily == null || currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: const Text(
          'Are you sure you want to leave this family? You will need an invite code to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final familyRepo = ref.read(familyRepositoryProvider);
      await familyRepo.leaveFamily(
        familyId: currentFamily.id,
        userId: currentUser.id,
      );

      // Clear current family and navigate to family selection
      ref.read(currentFamilyIdProvider.notifier).state = null;
      ref.invalidate(currentFamilyProvider);

      if (!mounted) return;
      context.go(AppConstants.routeFamilySelection);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave family: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFamily() async {
    final currentFamily = ref.read(currentFamilyProvider);
    if (currentFamily == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: const Text(
          'Are you sure you want to delete this family? This action cannot be undone. All family data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final familyRepo = ref.read(familyRepositoryProvider);
      await familyRepo.deleteFamily(currentFamily.id);

      // Clear current family and navigate to family selection
      ref.read(currentFamilyIdProvider.notifier).state = null;
      ref.invalidate(currentFamilyProvider);

      if (!mounted) return;
      context.go(AppConstants.routeFamilySelection);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete family: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final currentUser = ref.read(currentUserProvider);
    final isCreator = currentFamily?.createdBy == currentUser?.id;

    // Initialize form data when family loads
    if (currentFamily != null && !_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _nameController.text.isEmpty) {
          _initializeData(currentFamily);
        }
      });
    }

    final familyMembers = currentFamily != null
        ? ref.watch(familyMembersProvider(currentFamily.id))
        : const AsyncValue.data(<FamilyMemberModel>[]);

    return BackgroundWidget(
      child: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'Family Settings',
              leading: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              actions: [
                _isEditing
                    ? TextButton(
                        onPressed: _isLoading ? null : _saveFamily,
                        child: _isLoading
                            ? SizedBox(
                                width: ResponsiveHelper.w(20),
                                height: ResponsiveHelper.h(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : const Text('Save'),
                      )
                    : TextButton(
                        onPressed: () => setState(() => _isEditing = true),
                        child: const Text('Edit'),
                      ),
                Padding(
                  padding: ResponsiveHelper.padding(right: 8),
                  child: GestureDetector(
                    onTap: () => context.push(AppConstants.routeProfile),
                    child: AvatarWidget(
                      avatarPath: currentUser?.avatarUrl,
                      radius: ResponsiveHelper.r(16),
                      displayName:
                          currentUser?.userMetadata?['full_name'] as String? ??
                          'User',
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      textColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.padding(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    currentFamily == null
                        ? const Center(child: CircularProgressIndicator())
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Family Info Card
                                ModernCard(
                                  padding: ResponsiveHelper.padding(all: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Family Information',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(16)),

                                      // Family Name
                                      TextFormField(
                                        controller: _nameController,
                                        enabled: _isEditing,
                                        decoration: InputDecoration(
                                          labelText: 'Family Name',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                ResponsiveHelper.borderRadius(
                                                  12,
                                                ),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.family_restroom,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Family name is required';
                                          }
                                          if (value.trim().length <
                                              AppConstants
                                                  .minDisplayNameLength) {
                                            return 'Family name must be at least ${AppConstants.minDisplayNameLength} characters';
                                          }
                                          if (value.trim().length >
                                              AppConstants
                                                  .maxFamilyNameLength) {
                                            return 'Family name must be less than ${AppConstants.maxFamilyNameLength} characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(16)),

                                      // Address
                                      TextFormField(
                                        controller: _addressController,
                                        enabled: _isEditing,
                                        decoration: InputDecoration(
                                          labelText: 'Address (Optional)',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                ResponsiveHelper.borderRadius(
                                                  12,
                                                ),
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                          ),
                                        ),
                                        maxLines: 2,
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(8)),

                                      // Created info
                                      Text(
                                        'Created ${currentFamily.createdAt != null ? DateFormat(AppConstants.dateFormat).format(currentFamily.createdAt!) : "recently"}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: ResponsiveHelper.h(16)),

                                // Invite Codes Card
                                ModernCard(
                                  padding: ResponsiveHelper.padding(all: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Invite Codes',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(16)),

                                      // Adult Invite Code
                                      _buildInviteCodeSection(
                                        context,
                                        label: 'Adult Invite Code',
                                        code: currentFamily.inviteCode,
                                        onCopy: () async {
                                          if (currentFamily.inviteCode !=
                                              null) {
                                            await Clipboard.setData(
                                              ClipboardData(
                                                text: currentFamily.inviteCode!,
                                              ),
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Adult invite code copied!',
                                                  ),
                                                  duration: AppConstants
                                                      .snackBarDuration,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        onRegenerate: () =>
                                            _regenerateInviteCode(true),
                                        canRegenerate: isCreator,
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(12)),

                                      // Child Invite Code
                                      _buildInviteCodeSection(
                                        context,
                                        label: 'Child Invite Code',
                                        code: currentFamily.childInviteCode,
                                        onCopy: () async {
                                          if (currentFamily.childInviteCode !=
                                              null) {
                                            await Clipboard.setData(
                                              ClipboardData(
                                                text: currentFamily
                                                    .childInviteCode!,
                                              ),
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Child invite code copied!',
                                                  ),
                                                  duration: AppConstants
                                                      .snackBarDuration,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        onRegenerate: () =>
                                            _regenerateInviteCode(false),
                                        canRegenerate: isCreator,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: ResponsiveHelper.h(16)),

                                // Family Members Card
                                ModernCard(
                                  padding: ResponsiveHelper.padding(all: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Family Members',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(16)),

                                      familyMembers.when(
                                        data: (members) {
                                          if (members.isEmpty) {
                                            return Center(
                                              child: Padding(
                                                padding:
                                                    ResponsiveHelper.padding(
                                                      vertical: 24,
                                                    ),
                                                child: Text(
                                                  'No members found',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.6),
                                                      ),
                                                ),
                                              ),
                                            );
                                          }

                                          return Column(
                                            children: members.map((member) {
                                              final isCurrentUser =
                                                  member.uid == currentUser?.id;
                                              final canRemove =
                                                  isCreator && !isCurrentUser;

                                              return ListTile(
                                                leading: AvatarWidget(
                                                  avatarPath: member.photoURL,
                                                  radius: ResponsiveHelper.r(
                                                    20,
                                                  ),
                                                  displayName:
                                                      member.displayName,
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  textColor: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                ),
                                                title: Text(member.displayName),
                                                subtitle: Text(
                                                  '${member.role} • ${member.points} points',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                                trailing: canRemove
                                                    ? IconButton(
                                                        icon: Icon(
                                                          Icons
                                                              .remove_circle_outline,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.error,
                                                        ),
                                                        onPressed: () =>
                                                            _removeMember(
                                                              member.uid,
                                                              member
                                                                  .displayName,
                                                            ),
                                                      )
                                                    : isCurrentUser
                                                    ? Chip(
                                                        label: const Text(
                                                          'You',
                                                        ),
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                      )
                                                    : null,
                                              );
                                            }).toList(),
                                          );
                                        },
                                        loading: () => const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        error: (error, stack) => Center(
                                          child: Padding(
                                            padding: ResponsiveHelper.padding(
                                              vertical: 24,
                                            ),
                                            child: Text(
                                              'Error loading members: $error',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.error,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: ResponsiveHelper.h(16)),

                                // Danger Zone
                                ModernCard(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer.withOpacity(0.3),
                                  padding: ResponsiveHelper.padding(all: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Danger Zone',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(16)),

                                      // Leave Family
                                      ListTile(
                                        leading: Icon(
                                          Icons.exit_to_app,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                        title: const Text('Leave Family'),
                                        subtitle: const Text(
                                          'You will need an invite code to rejoin',
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.chevron_right,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                          onPressed: _leaveFamily,
                                        ),
                                      ),

                                      // Delete Family (only for creator)
                                      if (isCreator) ...[
                                        const Divider(),
                                        ListTile(
                                          leading: Icon(
                                            Icons.delete_forever,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                          title: const Text('Delete Family'),
                                          subtitle: const Text(
                                            'Permanently delete this family and all its data',
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              Icons.chevron_right,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                            onPressed: _deleteFamily,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: ResponsiveHelper.h(80),
                                ), // Space for bottom nav
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeSection(
    BuildContext context, {
    required String label,
    required String? code,
    required VoidCallback onCopy,
    required VoidCallback onRegenerate,
    required bool canRegenerate,
  }) {
    return Container(
      padding: ResponsiveHelper.padding(all: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: ResponsiveHelper.borderRadius(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: ResponsiveHelper.w(1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(4)),
                Text(
                  code ?? 'Not generated',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (code != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: onCopy,
              tooltip: 'Copy code',
            ),
          if (canRegenerate)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRegenerate,
              tooltip: 'Regenerate code',
            ),
        ],
      ),
    );
  }
}
