import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/family_model.dart';
import 'points_history_repository.dart';
import '../../core/services/role_permission_service.dart';

/// Repository for managing Family data.
///
/// This repository handles:
/// - Family creation and updates.
/// - Member management (joining, leaving, assigning roles).
/// - Invitation code generation and validation.
/// - Points and rewards transactions within the family.
class FamilyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();
  final PointsHistoryRepository _pointsHistoryRepo = PointsHistoryRepository();

  /// Create a new family group.
  ///
  /// [name] - Family name.
  /// [createdBy] - UID of the creator (who becomes 'parent').
  /// [address] - Optional physical address.
  /// [creatorAge] & [creatorBirthdate] - Optional updates for the creator's profile.
  Future<FamilyModel> createFamily({
    required String name,
    required String createdBy,
    String? address,
    int? creatorAge,
    DateTime? creatorBirthdate,
  }) async {
    try {
      final familyId = _uuid.v4();
      final now = DateTime.now();

      // Generate adult invite code
      final inviteCode = _generateInviteCode('ADULT');

      // Generate parent-specific invite code
      final parentInviteCode = _generateInviteCode('PARENT');

      final family = FamilyModel(
        id: familyId,
        name: name,
        createdBy: createdBy,
        members: [createdBy],
        address: address,
        inviteCode: inviteCode,
        createdAt: now,
        updatedAt: now,
      );

      // Store parent invite code separately (not in model yet)
      final familyData = family.toJson();
      familyData['parent_invite_code'] = parentInviteCode;

      // Create family in Supabase with parent invite code
      await _supabase.from('families').insert(familyData);

      // Update user profile with age and birthdate if provided
      if (creatorAge != null || creatorBirthdate != null) {
        final updates = <String, dynamic>{'updated_at': now.toIso8601String()};

        if (creatorAge != null) {
          updates['age'] = creatorAge;
        }

        if (creatorBirthdate != null) {
          updates['birthdate'] = creatorBirthdate.toIso8601String();
        }

        await _supabase.from('users').update(updates).eq('id', createdBy);
      }

      // Add creator as family member with parent role
      await addFamilyMember(
        familyId: familyId,
        uid: createdBy,
        role: 'parent',
        displayName: '', // Will be updated from user profile
      );

      return family;
    } catch (e) {
      _logger.e('Create family error: $e');
      rethrow;
    }
  }

  /// Generate a unique invite code
  String _generateInviteCode(String role) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();

    // Add role prefix
    switch (role.toUpperCase()) {
      case 'ADULT':
        code.write('A');
        break;
      case 'PARENT':
        code.write('P'); // Parent-specific invite code
        break;
      case 'CHILD':
        code.write('C');
        break;
      default:
        code.write('A'); // Default to adult
    }

    // Generate 5 more characters
    for (int i = 0; i < 5; i++) {
      code.write(chars[(random + i) % chars.length]);
    }

    return code.toString();
  }

  /// Join a family using an [inviteCode].
  ///
  /// [userId] - UID of the joining user.
  /// [selectedRole] - Optional role if required (e.g. when parent slots are full).
  ///
  /// Returns a Map with:
  /// - `family`: [FamilyModel] instance.
  /// - `needsRoleSelection`: `true` if role ambiguity exists.
  Future<Map<String, dynamic>> joinFamilyByCode({
    required String inviteCode,
    required String userId,
    String?
    selectedRole, // Optional: role selected by user when parent slots are full
  }) async {
    try {
      String? roleToAssign;
      bool needsRoleSelection = false;

      // Determine role based on invite code prefix
      if (inviteCode.startsWith('P')) {
        // Parent-specific invite code - will check parent count after finding family
        roleToAssign =
            selectedRole ?? 'parent'; // Default to parent, will validate below
      } else if (inviteCode.startsWith('A')) {
        // Adult invite code - check parent count
        // Will determine role after finding family
      } else if (inviteCode.startsWith('C')) {
        // Child invite code - always assign child role
        roleToAssign = 'child';
      }

      // Try to find family using the secure RPC function
      // This bypasses RLS policies that prevent non-members from searching families
      final response = await _supabase.rpc(
        'find_family_by_invite_code',
        params: {'invite_code_param': inviteCode},
      );

      if ((response as List).isEmpty) {
        throw Exception('Invalid invite code');
      }

      final familyData = response.first;

      final family = FamilyModel.fromJson(familyData);

      // Check if user is already a member
      if (family.members.contains(userId)) {
        return {'family': family, 'needsRoleSelection': false};
      }

      // For adult invite codes, determine role based on parent count
      if (inviteCode.startsWith('A')) {
        final roleService = RolePermissionService();
        final parentCount = await roleService.getParentCount(family.id);

        if (parentCount < 2) {
          roleToAssign = 'parent';
        } else {
          // Parent slots are full, need role selection
          if (selectedRole == null) {
            needsRoleSelection = true;
            return {'family': family, 'needsRoleSelection': true};
          } else {
            roleToAssign = selectedRole;
          }
        }
      }

      // For parent invite codes, check again with family ID
      if (inviteCode.startsWith('P')) {
        final roleService = RolePermissionService();
        final canAddParent = await roleService.canAddParent(family.id);

        if (!canAddParent) {
          if (selectedRole == null) {
            needsRoleSelection = true;
            return {'family': family, 'needsRoleSelection': true};
          } else {
            // If selectedRole is 'parent' but we can't add a parent, force selection again (or error, but UI should prevent this)
            if (selectedRole == 'parent') {
              needsRoleSelection = true;
              return {'family': family, 'needsRoleSelection': true};
            }
            roleToAssign = selectedRole;
          }
        } else {
          roleToAssign = selectedRole ?? 'parent';
        }
      }

      // Default to member if no role determined
      roleToAssign ??= 'member';

      // Add user to family members with appropriate role
      await addFamilyMember(
        familyId: family.id,
        uid: userId,
        role: roleToAssign,
        displayName: '', // Will be updated from user profile
      );

      // Update family members list (handled by database trigger or manually)
      final updatedMembers = [...family.members, userId];
      await _supabase
          .from('families')
          .update({
            'members': updatedMembers,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', family.id);

      // Return updated family
      final updatedFamily = await getFamily(family.id);
      return {'family': updatedFamily ?? family, 'needsRoleSelection': false};
    } catch (e) {
      _logger.e('Join family error: $e');
      rethrow;
    }
  }

  /// Get family by ID
  Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final response = await _supabase
          .from('families')
          .select()
          .eq('id', familyId)
          .maybeSingle();

      if (response == null) return null;

      return FamilyModel.fromJson(response);
    } catch (e) {
      _logger.e('Get family error: $e');
      return null;
    }
  }

  /// Stream family data
  Stream<FamilyModel?> streamFamily(String familyId) {
    return _supabase
        .from('families')
        .stream(primaryKey: ['id'])
        .eq('id', familyId)
        .map((data) {
          if (data.isEmpty) return null;
          return FamilyModel.fromJson(data.first);
        });
  }

  /// Get families for user
  Future<List<FamilyModel>> getUserFamilies(String userId) async {
    try {
      // Query via family_members table (source of truth) instead of members array
      // This ensures RLS policies work correctly
      final memberResponse = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId);

      if (memberResponse.isEmpty) {
        return [];
      }

      final familyIds = (memberResponse as List)
          .map((json) => json['family_id'] as String)
          .toList();

      // Now fetch the families
      // Build OR query for multiple family IDs
      PostgrestFilterBuilder query = _supabase.from('families').select();

      // Add OR conditions for each family ID
      if (familyIds.isNotEmpty) {
        final orConditions = familyIds.map((id) => 'id.eq.$id').join(',');
        query = query.or(orConditions);
      }

      final response = await query.order('created_at', ascending: false);

      final familiesList = response as List;

      return familiesList.map((json) => FamilyModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      _logger.e(
        'Get user families error: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Stream families for user
  Stream<List<FamilyModel>> streamUserFamilies(String userId) {
    try {
      // Stream family_members first to get family IDs the user belongs to
      return _supabase
          .from('family_members')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .asyncMap((memberData) async {
            try {
              _logger.d(
                'Stream user families: received ${memberData.length} family_members for user $userId',
              );

              if (memberData.isEmpty) {
                _logger.d('No family_members found for user $userId');
                return <FamilyModel>[];
              }

              final familyIds = memberData
                  .map((json) {
                    try {
                      return json['family_id'] as String;
                    } catch (e) {
                      _logger.w(
                        'Failed to parse family_id from member data: $json',
                        error: e,
                      );
                      return null;
                    }
                  })
                  .whereType<String>()
                  .toSet()
                  .toList();

              if (familyIds.isEmpty) {
                _logger.w('No valid family IDs extracted from member data');
                return <FamilyModel>[];
              }

              _logger.d('Fetching ${familyIds.length} families: $familyIds');

              // Now fetch the families
              // Build OR query for multiple family IDs
              PostgrestFilterBuilder query = _supabase
                  .from('families')
                  .select();

              // Add OR conditions for each family ID
              if (familyIds.isNotEmpty) {
                final orConditions = familyIds
                    .map((id) => 'id.eq.$id')
                    .join(',');
                query = query.or(orConditions);
              }

              final response = await query.order(
                'created_at',
                ascending: false,
              );

              final familiesList = response as List;
              final families = familiesList
                  .map((json) {
                    try {
                      return FamilyModel.fromJson(json);
                    } catch (e, stackTrace) {
                      _logger.e(
                        'Failed to parse family from JSON: $json',
                        error: e,
                        stackTrace: stackTrace,
                      );
                      return null;
                    }
                  })
                  .whereType<FamilyModel>()
                  .toList();

              _logger.d(
                'Successfully fetched ${families.length} families for user $userId',
              );
              return families;
            } catch (e, stackTrace) {
              _logger.e(
                'Error in streamUserFamilies asyncMap for user $userId: $e',
                error: e,
                stackTrace: stackTrace,
              );
              // Return empty list on error to prevent stream from breaking
              // Fallback to non-streaming method will be handled by provider
              return <FamilyModel>[];
            }
          })
          .handleError((error, stackTrace) {
            _logger.e(
              'Stream error in streamUserFamilies for user $userId: $error',
              error: error,
              stackTrace: stackTrace,
            );
            // Return empty list to prevent stream from breaking
            return <FamilyModel>[];
          });
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to create stream for user families: $e',
        error: e,
        stackTrace: stackTrace,
      );
      // Return a stream that emits empty list and completes
      return Stream.value(<FamilyModel>[]);
    }
  }

  /// Update family
  Future<void> updateFamily({
    required String familyId,
    String? name,
    String? address,
    String? themePreference,
    String? geminiApiKey,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (themePreference != null)
        updates['theme_preference'] = themePreference;
      if (geminiApiKey != null) updates['gemini_api_key'] = geminiApiKey;

      await _supabase.from('families').update(updates).eq('id', familyId);
    } catch (e) {
      _logger.e('Update family error: $e');
      rethrow;
    }
  }

  /// Delete family
  Future<void> deleteFamily(String familyId) async {
    try {
      await _supabase.from('families').delete().eq('id', familyId);
    } catch (e) {
      _logger.e('Delete family error: $e');
      rethrow;
    }
  }

  /// Leave family
  Future<void> leaveFamily({
    required String familyId,
    required String userId,
  }) async {
    try {
      // Remove from family_members table
      await _supabase
          .from('family_members')
          .delete()
          .eq('family_id', familyId)
          .eq('user_id', userId);

      // Update family members array (if you're storing it redundantly)
      final family = await getFamily(familyId);
      if (family != null) {
        final updatedMembers = family.members
            .where((id) => id != userId)
            .toList();
        await _supabase
            .from('families')
            .update({
              'members': updatedMembers,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', familyId);
      }
    } catch (e) {
      _logger.e('Leave family error: $e');
      rethrow;
    }
  }

  /// Add a user to a family with a specific role.
  ///
  /// Inserts a record into the `family_members` table.
  Future<void> addFamilyMember({
    required String familyId,
    required String uid,
    required String role,
    required String displayName,
  }) async {
    try {
      final member = {
        'family_id': familyId,
        'user_id': uid,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('family_members').insert(member);
    } catch (e) {
      _logger.e('Add family member error: $e');
      rethrow;
    }
  }

  /// Get family member
  Future<FamilyMemberModel?> getFamilyMember({
    required String familyId,
    required String uid,
  }) async {
    try {
      final response = await _supabase
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('user_id', uid)
          .maybeSingle();

      if (response == null) return null;

      // Fetch user data to get displayName and photoURL
      final userResponse = await _supabase
          .from('users')
          .select('display_name, avatar_url')
          .eq('id', uid)
          .maybeSingle();

      // Construct FamilyMemberModel manually (database uses user_id, not uid)
      return FamilyMemberModel(
        uid: uid,
        displayName: userResponse?['display_name'] as String? ?? 'User',
        photoURL: userResponse?['avatar_url'] as String?,
        role: response['role'] as String? ?? 'member',
        points: response['points'] as int? ?? 0,
        notificationTokens:
            (response['notification_tokens'] as List<dynamic>?)
                ?.cast<String>() ??
            [],
        joinedAt: response['joined_at'] != null
            ? DateTime.parse(response['joined_at'] as String)
            : null,
        updatedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'] as String)
            : null,
      );
    } catch (e) {
      _logger.e('Get family member error: $e');
      return null;
    }
  }

  /// Stream family member
  Stream<FamilyMemberModel?> streamFamilyMember({
    required String familyId,
    required String uid,
  }) {
    return _supabase.from('family_members').stream(primaryKey: ['id']).asyncMap(
      (data) async {
        final filtered = data.where(
          (item) => item['family_id'] == familyId && item['user_id'] == uid,
        );
        if (filtered.isEmpty) return null;

        final json = filtered.first;

        // Fetch user data to get displayName and photoURL
        final userResponse = await _supabase
            .from('users')
            .select('display_name, avatar_url')
            .eq('id', uid)
            .maybeSingle();

        // Construct FamilyMemberModel manually (database uses user_id, not uid)
        return FamilyMemberModel(
          uid: uid,
          displayName: userResponse?['display_name'] as String? ?? 'User',
          photoURL: userResponse?['avatar_url'] as String?,
          role: json['role'] as String? ?? 'member',
          points: json['points'] as int? ?? 0,
          notificationTokens:
              (json['notification_tokens'] as List<dynamic>?)?.cast<String>() ??
              [],
          joinedAt: json['joined_at'] != null
              ? DateTime.parse(json['joined_at'] as String)
              : null,
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
        );
      },
    );
  }

  /// Get all family members
  Future<List<FamilyMemberModel>> getFamilyMembers(String familyId) async {
    try {
      // Fetch family members first
      final response = await _supabase
          .from('family_members')
          .select()
          .eq('family_id', familyId);
      // Note: Order by points requires the column to exist. Run add_family_members_points_column.sql migration first.
      // .order('points', ascending: false)

      // Fetch user data for all members in parallel
      final members = await Future.wait(
        (response as List).map((json) async {
          try {
            final userId = json['user_id'] as String;
            final userResponse = await _supabase
                .from('users')
                .select('display_name, avatar_url')
                .eq('id', userId)
                .maybeSingle();

            return FamilyMemberModel(
              uid: userId,
              displayName: userResponse?['display_name'] as String? ?? 'User',
              photoURL: userResponse?['avatar_url'] as String?,
              role: json['role'] as String? ?? 'member',
              points: json['points'] as int? ?? 0,
              notificationTokens:
                  (json['notification_tokens'] as List<dynamic>?)
                      ?.cast<String>() ??
                  [],
              joinedAt: json['joined_at'] != null
                  ? DateTime.parse(json['joined_at'] as String)
                  : null,
              updatedAt: json['updated_at'] != null
                  ? DateTime.parse(json['updated_at'] as String)
                  : null,
            );
          } catch (e) {
            _logger.e('Error fetching user data for ${json['user_id']}: $e');
            // Return member with minimal data if user fetch fails
            return FamilyMemberModel(
              uid: json['user_id'] as String,
              displayName: 'User',
              photoURL: null,
              role: json['role'] as String? ?? 'member',
              points: json['points'] as int? ?? 0,
              notificationTokens:
                  (json['notification_tokens'] as List<dynamic>?)
                      ?.cast<String>() ??
                  [],
              joinedAt: json['joined_at'] != null
                  ? DateTime.parse(json['joined_at'] as String)
                  : null,
              updatedAt: json['updated_at'] != null
                  ? DateTime.parse(json['updated_at'] as String)
                  : null,
            );
          }
        }),
      );

      // Sort by points (descending)
      members.sort((a, b) => b.points.compareTo(a.points));
      return members;
    } catch (e) {
      _logger.e('Get family members error: $e');
      return [];
    }
  }

  /// Stream all family members
  Stream<List<FamilyMemberModel>> streamFamilyMembers(String familyId) {
    return _supabase
        .from('family_members')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        // Note: Order by points requires the column to exist. Run add_family_members_points_column.sql migration first.
        // .order('points', ascending: false)
        .asyncMap((data) async {
          // Fetch user data for all members in parallel
          final members = await Future.wait(
            data.map((json) async {
              try {
                final userId = json['user_id'] as String;
                final userResponse = await _supabase
                    .from('users')
                    .select('display_name, avatar_url')
                    .eq('id', userId)
                    .maybeSingle();

                final avatarUrl = userResponse?['avatar_url'] as String?;

                return FamilyMemberModel(
                  uid: userId,
                  displayName:
                      userResponse?['display_name'] as String? ?? 'User',
                  photoURL: avatarUrl,
                  role: json['role'] as String? ?? 'member',
                  points: json['points'] as int? ?? 0,
                  notificationTokens:
                      (json['notification_tokens'] as List<dynamic>?)
                          ?.cast<String>() ??
                      [],
                  joinedAt: json['joined_at'] != null
                      ? DateTime.parse(json['joined_at'] as String)
                      : null,
                  updatedAt: json['updated_at'] != null
                      ? DateTime.parse(json['updated_at'] as String)
                      : null,
                );
              } catch (e) {
                _logger.e('Error fetching user data for member: $e');
                return FamilyMemberModel(
                  uid: json['user_id'] as String,
                  displayName: 'User',
                  photoURL: null,
                  role: json['role'] as String? ?? 'member',
                  points: json['points'] as int? ?? 0,
                  notificationTokens: [],
                  joinedAt: json['joined_at'] != null
                      ? DateTime.parse(json['joined_at'] as String)
                      : null,
                  updatedAt: json['updated_at'] != null
                      ? DateTime.parse(json['updated_at'] as String)
                      : null,
                );
              }
            }),
          );
          // Sort by points (descending) in memory
          members.sort((a, b) => b.points.compareTo(a.points));
          return members;
        });
  }

  /// Update family member
  Future<void> updateFamilyMember({
    required String familyId,
    required String uid,
    String? displayName,
    String? role,
    String? photoURL,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (role != null) updates['role'] = role;
      if (photoURL != null) updates['photo_url'] = photoURL;

      if (role == 'parent') {
        // Check if user is already a parent (idempotency)
        final member = await getFamilyMember(familyId: familyId, uid: uid);
        if (member != null && member.role != 'parent') {
          // Check if we can add another parent
          final roleService = RolePermissionService();
          final canAdd = await roleService.canAddParent(familyId);
          if (!canAdd) {
            throw Exception('Family already has maximum number of parents (2)');
          }
        }
      }

      await _supabase
          .from('family_members')
          .update(updates)
          .eq('family_id', familyId)
          .eq('user_id', uid);
    } catch (e) {
      _logger.e('Update family member error: $e');
      rethrow;
    }
  }

  /// Awards points to a family member for a task or reason.
  ///
  /// Updates the member's point balance and logs the transaction history.
  Future<void> awardPointsToMember({
    required String familyId,
    required String userId,
    required int points,
    String? reason,
    String? taskId,
    String? taskTitle,
  }) async {
    try {
      // Get current points - handle case where column might not exist yet
      int currentPoints = 0;
      try {
        final memberResponse = await _supabase
            .from('family_members')
            .select('points')
            .eq('family_id', familyId)
            .eq('user_id', userId)
            .single();

        currentPoints = (memberResponse['points'] as int?) ?? 0;
      } catch (e) {
        // If points column doesn't exist, log warning and use 0        currentPoints = 0;
      }

      final newPoints = currentPoints + points;

      // Update points - handle case where column might not exist yet
      try {
        await _supabase
            .from('family_members')
            .update({
              'points': newPoints,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('family_id', familyId)
            .eq('user_id', userId);

        // Log points transaction
        await _pointsHistoryRepo.logPointsTransaction(
          familyId: familyId,
          userId: userId,
          points: points,
          reason: reason ?? 'task_completed',
          taskId: taskId,
          taskTitle: taskTitle,
        );
      } catch (e) {
        _logger.e(
          'Failed to update points. Please run add_family_members_points_column.sql migration. Error: $e',
        );
        // Don't rethrow - allow the app to continue functioning
        // Points will be awarded once the migration is run
      }
    } catch (e) {
      _logger.e('Award points error: $e');
      // Don't rethrow - allow the app to continue functioning
    }
  }

  /// Remove points from a family member (when task is uncompleted)
  Future<void> removePointsFromMember({
    required String familyId,
    required String userId,
    required int points,
    String? reason,
    String? taskId,
    String? taskTitle,
  }) async {
    try {
      // Get current points - handle case where column might not exist yet
      int currentPoints = 0;
      try {
        final memberResponse = await _supabase
            .from('family_members')
            .select('points')
            .eq('family_id', familyId)
            .eq('user_id', userId)
            .single();

        currentPoints = (memberResponse['points'] as int?) ?? 0;
      } catch (e) {
        // If points column doesn't exist, log warning and use 0        currentPoints = 0;
      }

      final newPoints = (currentPoints - points)
          .clamp(0, double.infinity)
          .toInt(); // Don't go below 0

      // Update points - handle case where column might not exist yet
      try {
        await _supabase
            .from('family_members')
            .update({
              'points': newPoints,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('family_id', familyId)
            .eq('user_id', userId);

        // Log points transaction (negative points)
        await _pointsHistoryRepo.logPointsTransaction(
          familyId: familyId,
          userId: userId,
          points: -points, // Negative for removal
          reason: reason ?? 'task_uncompleted',
          taskId: taskId,
          taskTitle: taskTitle,
        );
      } catch (e) {
        _logger.e(
          'Failed to update points. Please run add_family_members_points_column.sql migration. Error: $e',
        );
        // Don't rethrow - allow the app to continue functioning
        // Points will be updated once the migration is run
      }
    } catch (e) {
      _logger.e('Remove points error: $e');
      // Don't rethrow - allow the app to continue functioning
    }
  }

  /// Remove family member
  Future<void> removeFamilyMember({
    required String familyId,
    required String uid,
  }) async {
    try {
      await _supabase
          .from('family_members')
          .delete()
          .eq('family_id', familyId)
          .eq('user_id', uid);
    } catch (e) {
      _logger.e('Remove family member error: $e');
      rethrow;
    }
  }

  /// Check if invite code exists (adult or child)
  Future<bool> inviteCodeExists(String inviteCode) async {
    try {
      // Check if code exists globally using secure RPC
      final response = await _supabase.rpc(
        'find_family_by_invite_code',
        params: {'invite_code_param': inviteCode},
      );

      return (response as List).isNotEmpty;
    } catch (e) {
      _logger.e('Check invite code error: $e');
      return false;
    }
  }

  /// Generate invite code for existing family that doesn't have one
  Future<String?> generateInviteCodeForFamily(String familyId) async {
    try {
      // Generate new adult invite code
      String inviteCode;
      bool exists = true;

      // Ensure unique invite code
      do {
        inviteCode = _generateInviteCode('ADULT');
        exists = await inviteCodeExists(inviteCode);
      } while (exists);

      // Update family with new invite code
      await _supabase
          .from('families')
          .update({
            'invite_code': inviteCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', familyId);

      return inviteCode;
    } catch (e) {
      _logger.e('Generate invite code error: $e');
      return null;
    }
  }

  /// Generate child-specific invite code for family
  Future<String?> generateChildInviteCodeForFamily(String familyId) async {
    try {
      // Generate new child invite code
      String inviteCode;
      bool exists = true;

      // Ensure unique invite code
      do {
        inviteCode = _generateInviteCode('CHILD');
        exists = await inviteCodeExists(inviteCode);
      } while (exists);

      // Update family with child invite code
      await _supabase
          .from('families')
          .update({
            'child_invite_code': inviteCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', familyId);

      return inviteCode;
    } catch (e) {
      _logger.e('Generate child invite code error: $e');
      return null;
    }
  }

  /// Generate parent-specific invite code for family
  /// This code allows users to join as a parent (if slots available)
  Future<String?> generateParentInviteCodeForFamily(String familyId) async {
    try {
      // Check if family already has parent invite code
      final family = await getFamily(familyId);
      if (family != null) {
        final response = await _supabase
            .from('families')
            .select('parent_invite_code')
            .eq('id', familyId)
            .maybeSingle();

        if (response != null && response['parent_invite_code'] != null) {
          return response['parent_invite_code'] as String;
        }
      }

      // Generate new parent invite code
      String inviteCode;
      bool exists = true;

      // Ensure unique invite code
      do {
        inviteCode = _generateInviteCode('PARENT');
        exists = await inviteCodeExists(inviteCode);
      } while (exists);

      // Update family with parent invite code
      await _supabase
          .from('families')
          .update({
            'parent_invite_code': inviteCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', familyId);

      return inviteCode;
    } catch (e) {
      _logger.e('Generate parent invite code error: $e');
      return null;
    }
  }
}
