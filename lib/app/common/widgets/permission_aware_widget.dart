import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/role_permission_service.dart';
import '../../core/providers/providers.dart';

/// Widget that conditionally shows its child based on user permissions
class PermissionAwareWidget extends ConsumerWidget {
  final Widget child;
  final String action; // e.g., 'create_task', 'edit_task', 'delete_event'
  final String? familyId;
  final Widget? fallback; // Widget to show if permission is denied

  const PermissionAwareWidget({
    super.key,
    required this.child,
    required this.action,
    this.familyId,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentFamily = ref.watch(currentFamilyProvider);
    
    if (currentUser == null) {
      return fallback ?? const SizedBox.shrink();
    }
    
    final effectiveFamilyId = familyId ?? currentFamily?.id;
    if (effectiveFamilyId == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final roleService = RolePermissionService();
    final permissionFuture = roleService.canPerformAction(
      userId: currentUser.id,
      familyId: effectiveFamilyId,
      action: action,
    );

    return FutureBuilder<bool>(
      future: permissionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show nothing while checking (or show a loading indicator)
          return const SizedBox.shrink();
        }
        
        final hasPermission = snapshot.data ?? false;
        if (hasPermission) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Widget that conditionally enables/disables a widget based on permissions
class PermissionAwareEnabledWidget extends ConsumerWidget {
  final Widget child;
  final String action;
  final String? familyId;
  final bool Function(bool hasPermission)? builder;

  const PermissionAwareEnabledWidget({
    super.key,
    required this.child,
    required this.action,
    this.familyId,
    this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentFamily = ref.watch(currentFamilyProvider);
    
    if (currentUser == null) {
      return Opacity(
        opacity: 0.5,
        child: IgnorePointer(child: child),
      );
    }
    
    final effectiveFamilyId = familyId ?? currentFamily?.id;
    if (effectiveFamilyId == null) {
      return Opacity(
        opacity: 0.5,
        child: IgnorePointer(child: child),
      );
    }

    final roleService = RolePermissionService();
    final permissionFuture = roleService.canPerformAction(
      userId: currentUser.id,
      familyId: effectiveFamilyId,
      action: action,
    );

    return FutureBuilder<bool>(
      future: permissionFuture,
      builder: (context, snapshot) {
        final hasPermission = snapshot.data ?? false;
        
        if (builder != null) {
          return builder!(hasPermission) ? child : Opacity(
            opacity: 0.5,
            child: IgnorePointer(child: child),
          );
        }
        
        return hasPermission
            ? child
            : Opacity(
                opacity: 0.5,
                child: IgnorePointer(child: child),
              );
      },
    );
  }
}

/// Helper function to check permission synchronously (for use in callbacks)
Future<bool> checkPermission(
  WidgetRef ref,
  String action, {
  String? familyId,
  String? userId,
}) async {
  final currentUser = userId != null
      ? null
      : ref.read(currentUserProvider);
  final currentFamily = ref.read(currentFamilyProvider);
  
  if (currentUser == null && userId == null) {
    return false;
  }
  
  final effectiveUserId = userId ?? currentUser?.id;
  final effectiveFamilyId = familyId ?? currentFamily?.id;
  
  if (effectiveUserId == null || effectiveFamilyId == null) {
    return false;
  }

  final roleService = RolePermissionService();
  return await roleService.canPerformAction(
    userId: effectiveUserId,
    familyId: effectiveFamilyId,
    action: action,
  );
}

