import 'package:flutter/material.dart';
import '../responsive/responsive_helper.dart';

/// Reusable background widget for all screens
/// Following user preference for consistent background implementation
class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool showGradient;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.showGradient = false,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        gradient: showGradient ? LinearGradient(
          begin: gradientBegin ?? Alignment.topCenter,
          end: gradientEnd ?? Alignment.bottomCenter,
          colors: gradientColors ?? [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.surface,
          ],
        ) : null,
      ),
      child: padding != null 
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );
  }
}

/// Gradient background variant
class GradientBackgroundWidget extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;
  final EdgeInsetsGeometry? padding;

  const GradientBackgroundWidget({
    super.key,
    required this.child,
    required this.colors,
    this.begin,
    this.end,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: padding != null 
          ? Padding(
              padding: padding!,
              child: child,
            )
          : child,
    );
  }
}

/// Card background widget
class CardBackgroundWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;

  const CardBackgroundWidget({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: margin,
      padding: padding ?? ResponsiveHelper.padding(all: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: ResponsiveHelper.borderRadius(borderRadius ?? 12),
        boxShadow: boxShadow ?? ResponsiveHelper.boxShadow(),
      ),
      child: child,
    );
  }
}