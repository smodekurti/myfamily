import 'package:flutter/material.dart';
import '../../../../common/responsive/responsive_helper.dart';

/// Dialog for selecting a role when joining a family with adult invite code
/// and parent slots are already full
class RoleSelectionDialog extends StatelessWidget {
  final String familyName;
  final Function(String) onRoleSelected;

  const RoleSelectionDialog({
    super.key,
    required this.familyName,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(16),
      ),
      child: Padding(
        padding: ResponsiveHelper.padding(all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Choose Your Role',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: ResponsiveHelper.h(8)),
            
            // Description
            Text(
              'This family already has 2 parents. Please select your role:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            SizedBox(height: ResponsiveHelper.h(24)),
            
            // Role options
            _RoleOption(
              title: 'Caretaker',
              description: 'Can manage tasks and events, assign tasks to others',
              icon: Icons.people_outline,
              onTap: () => onRoleSelected('caretaker'),
            ),
            SizedBox(height: ResponsiveHelper.h(12)),
            
            _RoleOption(
              title: 'Guardian',
              description: 'Can view and assist with tasks, limited event access',
              icon: Icons.shield_outlined,
              onTap: () => onRoleSelected('guardian'),
            ),
            SizedBox(height: ResponsiveHelper.h(12)),
            
            _RoleOption(
              title: 'Member',
              description: 'Standard family member with basic access',
              icon: Icons.person_outline,
              onTap: () => onRoleSelected('member'),
            ),
            SizedBox(height: ResponsiveHelper.h(24)),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the role selection dialog
  static Future<String?> show(
    BuildContext context,
    String familyName,
  ) async {
    String? selectedRole;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoleSelectionDialog(
        familyName: familyName,
        onRoleSelected: (role) {
          selectedRole = role;
          Navigator.of(context).pop();
        },
      ),
    );
    
    return selectedRole;
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: ResponsiveHelper.borderRadius(12),
      child: Container(
        padding: ResponsiveHelper.padding(all: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: ResponsiveHelper.borderRadius(12),
        ),
        child: Row(
          children: [
            Container(
              padding: ResponsiveHelper.padding(all: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: ResponsiveHelper.borderRadius(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveHelper.iconSize(24),
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(4)),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

