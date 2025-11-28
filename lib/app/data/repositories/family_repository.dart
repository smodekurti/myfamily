import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/family_model.dart';
import 'points_history_repository.dart';

class FamilyRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();
  final PointsHistoryRepository _pointsHistoryRepo = PointsHistoryRepository();

  /// Create a new family
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

      // Create family in Supabase
      await _supabase.from('families').insert(family.toJson());

      // Update user profile with age and birthdate if provided
      if (creatorAge != null || creatorBirthdate != null) {
        final updates = <String, dynamic>{
          'updated_at': now.toIso8601String(),
        };
        
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

      _logger.i('Created family: $familyId with invite code: $inviteCode');
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

  /// Join a family by invite code
  Future<FamilyModel?> joinFamilyByCode({
    required String inviteCode,
    required String userId,
  }) async {
    try {
      // Determine role based on invite code prefix
      String role = 'member'; // Default role
      if (inviteCode.startsWith('A')) {
        role = 'parent'; // Adult invite code
      } else if (inviteCode.startsWith('C')) {
        role = 'child'; // Child invite code
      }

      // Try to find family by adult invite code first
      var response = await _supabase
          .from('families')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();

      // If not found, try child invite code
      response ??= await _supabase
            .from('families')
            .select()
            .eq('child_invite_code', inviteCode)
            .maybeSingle();

      if (response == null) {
        throw Exception('Invalid invite code');
      }

      final family = FamilyModel.fromJson(response);

      // Check if user is already a member
      if (family.members.contains(userId)) {
        return family;
      }

      // Add user to family members with appropriate role
      await addFamilyMember(
        familyId: family.id,
        uid: userId,
        role: role,
        displayName: '', // Will be updated from user profile
      );

      // Update family members list (handled by database trigger or manually)
      final updatedMembers = [...family.members, userId];
      await _supabase.from('families').update({
        'members': updatedMembers,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', family.id);

      _logger.i('User $userId joined family: ${family.id}');
      return family;
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
      final response = await _supabase
          .from('families')
          .select()
          .contains('members', [userId])
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FamilyModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Get user families error: $e');
      return [];
    }
  }

  /// Stream families for user
  Stream<List<FamilyModel>> streamUserFamilies(String userId) {
    return _supabase
        .from('families')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((family) => (family['members'] as List).contains(userId))
            .map((json) => FamilyModel.fromJson(json))
            .toList());
  }

  /// Update family
  Future<void> updateFamily({
    required String familyId,
    String? name,
    String? address,
    String? themePreference,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;
      if (themePreference != null) updates['theme_preference'] = themePreference;

      await _supabase.from('families').update(updates).eq('id', familyId);
      
      _logger.i('Updated family: $familyId');
    } catch (e) {
      _logger.e('Update family error: $e');
      rethrow;
    }
  }

  /// Delete family
  Future<void> deleteFamily(String familyId) async {
    try {
      await _supabase.from('families').delete().eq('id', familyId);
      _logger.i('Deleted family: $familyId');
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
        final updatedMembers = family.members.where((id) => id != userId).toList();
        await _supabase.from('families').update({
          'members': updatedMembers,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', familyId);
      }

      _logger.i('User $userId left family: $familyId');
    } catch (e) {
      _logger.e('Leave family error: $e');
      rethrow;
    }
  }

  /// Add family member
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

      _logger.i('Added member $uid to family: $familyId');
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
      
      return FamilyMemberModel.fromJson(response);
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
    return _supabase
        .from('family_members')
        .stream(primaryKey: ['id'])
        .map((data) {
          final filtered = data.where((item) => 
            item['family_id'] == familyId && item['user_id'] == uid
          );
          if (filtered.isEmpty) return null;
          return FamilyMemberModel.fromJson(filtered.first);
        });
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
      final members = await Future.wait((response as List).map((json) async {
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
            notificationTokens: (json['notification_tokens'] as List<dynamic>?)?.cast<String>() ?? [],
            joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : null,
            updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
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
            notificationTokens: (json['notification_tokens'] as List<dynamic>?)?.cast<String>() ?? [],
            joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : null,
            updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
          );
        }
      }));
      
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
          final members = await Future.wait(data.map((json) async {
            try {
              final userId = json['user_id'] as String;
              final userResponse = await _supabase
                  .from('users')
                  .select('display_name, avatar_url')
                  .eq('id', userId)
                  .maybeSingle();
              
              final avatarUrl = userResponse?['avatar_url'] as String?;
              _logger.d('Fetched user data for $userId: displayName=${userResponse?['display_name']}, avatar_url=$avatarUrl');
              
              return FamilyMemberModel(
                uid: userId,
                displayName: userResponse?['display_name'] as String? ?? 'User',
                photoURL: avatarUrl,
                role: json['role'] as String? ?? 'member',
                points: json['points'] as int? ?? 0,
                notificationTokens: (json['notification_tokens'] as List<dynamic>?)?.cast<String>() ?? [],
                joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : null,
                updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
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
                joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : null,
                updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
              );
            }
          }));
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

      await _supabase
          .from('family_members')
          .update(updates)
          .eq('family_id', familyId)
          .eq('user_id', uid);

      _logger.i('Updated family member $uid in family: $familyId');
    } catch (e) {
      _logger.e('Update family member error: $e');
      rethrow;
    }
  }

  /// Award points to a family member
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
        // If points column doesn't exist, log warning and use 0
        _logger.w('Points column may not exist yet. Please run add_family_members_points_column.sql migration. Error: $e');
        currentPoints = 0;
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

        _logger.i('Awarded $points points to user $userId in family $familyId (new total: $newPoints)');
        
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
        _logger.e('Failed to update points. Please run add_family_members_points_column.sql migration. Error: $e');
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
        // If points column doesn't exist, log warning and use 0
        _logger.w('Points column may not exist yet. Please run add_family_members_points_column.sql migration. Error: $e');
        currentPoints = 0;
      }

      final newPoints = (currentPoints - points).clamp(0, double.infinity).toInt(); // Don't go below 0

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

        _logger.i('Removed $points points from user $userId in family $familyId (new total: $newPoints)');
        
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
        _logger.e('Failed to update points. Please run add_family_members_points_column.sql migration. Error: $e');
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

      _logger.i('Removed member $uid from family: $familyId');
    } catch (e) {
      _logger.e('Remove family member error: $e');
      rethrow;
    }
  }

  /// Check if invite code exists (adult or child)
  Future<bool> inviteCodeExists(String inviteCode) async {
    try {
      // Check adult invite code
      var response = await _supabase
          .from('families')
          .select('id')
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (response != null) return true;

      // Check child invite code
      response = await _supabase
          .from('families')
          .select('id')
          .eq('child_invite_code', inviteCode)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _logger.e('Check invite code error: $e');
      return false;
    }
  }

  /// Generate invite code for existing family that doesn't have one
  Future<String?> generateInviteCodeForFamily(String familyId) async {
    try {
      // Check if family already has invite code
      final family = await getFamily(familyId);
      if (family?.inviteCode != null && family!.inviteCode!.isNotEmpty) {
        return family.inviteCode;
      }

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

      _logger.i('Generated adult invite code for family $familyId: $inviteCode');
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

      _logger.i('Generated child invite code for family $familyId: $inviteCode');
      return inviteCode;
    } catch (e) {
      _logger.e('Generate child invite code error: $e');
      return null;
    }
  }
}
