import 'package:flutter/material.dart';
import '../responsive/responsive_helper.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Border? border;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.elevation,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? ResponsiveHelper.padding(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: ResponsiveHelper.borderRadius(20),
        border:
            border ??
            Border.all(
              color: theme.colorScheme.outline.withOpacity(0.05),
              width: 1,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: ResponsiveHelper.borderRadius(20),
          child: Padding(
            padding: padding ?? ResponsiveHelper.padding(all: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}
