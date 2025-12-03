import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../responsive/responsive_helper.dart';

/// A reusable widget for displaying user avatars with signed URL support
/// Handles private storage buckets by automatically generating signed URLs
class AvatarWidget extends ConsumerStatefulWidget {
  /// The avatar path or URL (storage path like 'avatars/user-id.jpg' or full URL)
  final String? avatarPath;
  
  /// The radius of the avatar
  final double radius;
  
  /// The display name (used for fallback initial)
  final String? displayName;
  
  /// Background color for the avatar (when no image)
  final Color? backgroundColor;
  
  /// Text color for the initial (when no image)
  final Color? textColor;
  
  /// Whether to show a border
  final bool showBorder;
  
  /// Border color
  final Color? borderColor;
  
  /// Border width
  final double? borderWidth;
  
  /// Callback when image fails to load
  final ImageErrorListener? onImageError;

  const AvatarWidget({
    super.key,
    required this.avatarPath,
    this.radius = 20,
    this.displayName,
    this.backgroundColor,
    this.textColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth,
    this.onImageError,
  });

  @override
  ConsumerState<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends ConsumerState<AvatarWidget> {
  String? _signedUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _loadAvatarUrl();
    }
  }

  Future<void> _loadAvatarUrl() async {
    if (widget.avatarPath == null || widget.avatarPath!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _signedUrl = null;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final avatarService = ref.read(avatarUrlServiceProvider);
      final url = await avatarService.getAvatarUrl(widget.avatarPath);
      
      // Debug logging
      print('AvatarWidget: Input path: ${widget.avatarPath}');
      print('AvatarWidget: Generated URL: $url');
      
      if (mounted) {
        setState(() {
          _signedUrl = url;
          _isLoading = false;
          _hasError = url == null;
        });
      }
    } catch (e, stackTrace) {
      print('AvatarWidget: Error loading avatar: $e');
      print('AvatarWidget: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _signedUrl = null;
        });
      }
    }
  }

  /// Validate if the URL is a proper HTTP/HTTPS URL
  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? 
        Theme.of(context).colorScheme.primary;
    final textColor = widget.textColor ?? 
        Theme.of(context).colorScheme.onPrimary;
    final borderColor = widget.borderColor ?? 
        Theme.of(context).scaffoldBackgroundColor;
    final borderWidth = widget.borderWidth ?? ResponsiveHelper.w(2);

    Widget avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: backgroundColor,
      backgroundImage: _signedUrl != null && !_hasError && _isValidUrl(_signedUrl!)
          ? NetworkImage(_signedUrl!)
          : null,
      onBackgroundImageError: widget.onImageError ?? (exception, stackTrace) {
        print('AvatarWidget: Image load error: $exception');
        if (mounted) {
          setState(() {
            _hasError = true;
            _signedUrl = null;
          });
        }
      },
      child: _signedUrl == null || _hasError || _isLoading
          ? _isLoading
              ? SizedBox(
                  width: widget.radius,
                  height: widget.radius,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : _buildInitial(textColor)
          : null,
    );

    if (widget.showBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitial(Color textColor) {
    final initial = widget.displayName != null && widget.displayName!.isNotEmpty
        ? widget.displayName!.substring(0, 1).toUpperCase()
        : '?';
    
    return Text(
      initial,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: ResponsiveHelper.sp(widget.radius * 0.6),
      ),
    );
  }
}

