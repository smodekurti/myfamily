import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../../data/repositories/family_repository.dart';

/// Service for managing role-based permissions and access control
class RolePermissionService {
  static final RolePermissionService _instance = RolePermissionService._internal();
  factory RolePermissionService() => _instance;
  RolePermissionService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final FamilyRepository _familyRepo = FamilyRepository();

  /// Get user's role in a family
  Future<String?> getUserRole(String userId, String familyId) async {
    try {
      final member = await _familyRepo.getFamilyMember(
        familyId: familyId,
        uid: userId,
      );
      return member?.role;
    } catch (e) {
      _logger.e('Error getting user role: $e');
      return null;
    }
  }

  /// Get default permissions for a role
  Future<Map<String, bool>> getRolePermissions(String role) async {
    try {
      final response = await _supabase
          .from('role_permissions')
          .select('permissions')
          .eq('role', role.toLowerCase())
          .maybeSingle();

      if (response == null) {
        _logger.w('No permissions found for role: $role, returning empty permissions');
        return {};
      }

      final permissions = response['permissions'] as Map<String, dynamic>;
      return permissions.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      _logger.e('Error getting role permissions: $e');
      return {};
    }
  }

  /// Get default restrictions for a role
  Future<Map<String, bool>> getRoleRestrictions(String role) async {
    try {
      final response = await _supabase
          .from('role_permissions')
          .select('restrictions')
          .eq('role', role.toLowerCase())
          .maybeSingle();

      if (response == null) {
        _logger.w('No restrictions found for role: $role, returning empty restrictions');
        return {};
      }

      final restrictions = response['restrictions'] as Map<String, dynamic>;
      return restrictions.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      _logger.e('Error getting role restrictions: $e');
      return {};
    }
  }

  /// Check if user can perform a specific action
  Future<bool> canPerformAction({
    required String userId,
    required String familyId,
    required String action, // e.g., 'create_task', 'delete_event', 'manage_family'
  }) async {
    try {
      final role = await getUserRole(userId, familyId);
      if (role == null) {
        _logger.w('User $userId has no role in family $familyId');
        return false;
      }

      // Map action to permission key
      final permissionKey = _actionToPermissionKey(action);
      if (permissionKey == null) {
        _logger.w('Unknown action: $action');
        return false;
      }

      // Get role permissions
      final permissions = await getRolePermissions(role);
      return permissions[permissionKey] ?? false;
    } catch (e) {
      _logger.e('Error checking permission: $e');
      return false;
    }
  }

  /// Check if user can view specific data
  Future<bool> canViewData({
    required String userId,
    required String familyId,
    required String dataType, // 'task', 'event', 'announcement', 'grocery_list'
    String? itemId,
  }) async {
    try {
      final role = await getUserRole(userId, familyId);
      if (role == null) return false;

      // Children now have full view access (permissions updated)
      // They can create and edit but not delete
      // No special view restrictions needed anymore

      // For other roles, check can_view_all_data permission
      final permissions = await getRolePermissions(role);
      return permissions['can_view_all_data'] ?? true;
    } catch (e) {
      _logger.e('Error checking view permission: $e');
      return false;
    }
  }

  /// Get parent count for a family
  Future<int> getParentCount(String familyId) async {
    try {
      final response = await _supabase
          .rpc('get_parent_count', params: {'family_uuid': familyId});
      return response as int? ?? 0;
    } catch (e) {
      // Fallback to manual count if RPC doesn't exist
      try {
        final members = await _familyRepo.getFamilyMembers(familyId);
        return members.where((m) => m.role == 'parent').length;
      } catch (e2) {
        _logger.e('Error getting parent count: $e2');
        return 0;
      }
    }
  }

  /// Check if family can accept another parent
  Future<bool> canAddParent(String familyId) async {
    final parentCount = await getParentCount(familyId);
    return parentCount < 2;
  }

  /// Map action string to permission key
  String? _actionToPermissionKey(String action) {
    final actionMap = {
      'create_task': 'can_create_tasks',
      'edit_task': 'can_edit_tasks',
      'delete_task': 'can_delete_tasks',
      'assign_task': 'can_assign_tasks',
      'create_event': 'can_create_events',
      'edit_event': 'can_edit_events',
      'delete_event': 'can_delete_events',
      'create_list': 'can_create_lists',
      'edit_list': 'can_edit_lists',
      'delete_list': 'can_delete_lists',
      'create_template': 'can_create_templates',
      'delete_template': 'can_delete_templates',
      'create_announcement': 'can_create_announcements',
      'manage_family': 'can_manage_family',
      'invite_members': 'can_invite_members',
      'change_roles': 'can_change_roles',
      'view_points': 'can_view_points',
      'delete_family': 'can_delete_family',
    };
    return actionMap[action];
  }
}

