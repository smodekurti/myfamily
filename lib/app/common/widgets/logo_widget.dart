import 'package:flutter/material.dart';
import '../responsive/responsive_helper.dart';

class LogoWidget extends StatelessWidget {
  final double? size;
  final bool showText;
  final Color? color;
  final bool isAnimated;

  const LogoWidget({
    super.key,
    this.size,
    this.showText = true,
    this.color,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? ResponsiveHelper.w(120);
    final logoColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Icon
        _buildLogoIcon(context, logoSize, logoColor),
        
        if (showText) ...[
          SizedBox(height: ResponsiveHelper.h(16)),
          
          // App Name
          Text(
            'MyFamily',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: logoColor,
              letterSpacing: 1.2,
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.h(4)),
          
          // Tagline
          Text(
            'Connecting Families',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoIcon(BuildContext context, double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isAnimated
          ? _buildAnimatedLogo(context, size, color)
          : _buildStaticLogo(context, size, color),
    );
  }

  Widget _buildStaticLogo(BuildContext context, double size, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        
        // Family icon with custom styling
        Icon(
          Icons.family_restroom,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        
        // Heart accent
        Positioned(
          top: size * 0.15,
          right: size * 0.15,
          child: Container(
            width: size * 0.15,
            height: size * 0.15,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              size: size * 0.08,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo(BuildContext context, double size, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (ctx, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Transform.rotate(
            angle: value * 0.1,
            child: _buildStaticLogo(ctx, size, color),
          ),
        );
      },
    );
  }
}

/// Compact logo variant for app bars and smaller spaces
class CompactLogoWidget extends StatelessWidget {
  final double? size;
  final Color? color;

  const CompactLogoWidget({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? ResponsiveHelper.w(40);
    final logoColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            logoColor,
            logoColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(logoSize * 0.25),
      ),
      child: Icon(
        Icons.family_restroom,
        size: logoSize * 0.5,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}







