import 'package:flutter/material.dart';
import '../responsive/responsive_helper.dart';

class ModernHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBack;

  const ModernHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: ResponsiveHelper.padding(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: ResponsiveHelper.w(16)),
              ] else if (showBackButton) ...[
                IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: ResponsiveHelper.iconSize(20),
                    color: theme.colorScheme.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    padding: ResponsiveHelper.padding(all: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.w(16)),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }
}
