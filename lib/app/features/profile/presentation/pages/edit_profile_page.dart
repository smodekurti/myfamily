import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../common/widgets/avatar_widget.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _displayNameController.text = user.userMetadata?['display_name'] as String? ?? 
                                     user.userMetadata?['name'] as String? ?? '';
      _currentImageUrl = user.userMetadata?['avatar_url'] as String? ?? 
                        user.userMetadata?['picture'] as String?;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConstants.profilePictureSize.toDouble(),
        maxHeight: AppConstants.profilePictureSize.toDouble(),
        imageQuality: (AppConstants.imageCompressionQuality * 100).toInt(),
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_currentImageUrl != null || _selectedImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _currentImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      setState(() => _isUploadingImage = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Create unique file path
      // Path structure: avatars/{userId}/{timestamp}.jpg
      // This matches the RLS policy which expects userId in the folder structure
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/${user.id}/$fileName';

      // Upload to Supabase Storage
      final storage = Supabase.instance.client.storage.from('user-content');
      
      // Check if bucket exists, if not show helpful error
      try {
        await storage.upload(filePath, imageFile, fileOptions: const FileOptions(upsert: true));
      } catch (e) {
        final errorString = e.toString();
        if (errorString.contains('Bucket not found')) {
          throw Exception(
            'Storage bucket not found. Please run the setup_storage_buckets_private.sql migration in your Supabase SQL Editor.'
          );
        } else if (errorString.contains('row-level security') || errorString.contains('RLS') || errorString.contains('403')) {
          throw Exception(
            'Permission denied. Please ensure the storage bucket RLS policies are set up correctly. Run setup_storage_buckets_private.sql in your Supabase SQL Editor.'
          );
        }
        rethrow;
      }

      // For private buckets, we store the path (not the signed URL)
      // The signed URL will be generated on-demand when displaying the avatar
      // Return the storage path so it can be stored in the database
      return filePath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _currentImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        photoUrl = await _uploadImage(_selectedImage!);
        if (photoUrl == null) {
          // Upload failed, don't continue
          setState(() => _isLoading = false);
          return;
        }
      } else if (_currentImageUrl == null) {
        // User removed the image
        photoUrl = null;
      }

      // Update user profile
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        photoURL: photoUrl,
      );

      // Clear avatar URL cache for the old and new URLs
      final avatarService = ref.read(avatarUrlServiceProvider);
      if (_currentImageUrl != null) {
        avatarService.clearCache(_currentImageUrl);
      }
      if (photoUrl != null) {
        avatarService.clearCache(photoUrl);
      }

      // Refresh current user and family members to update avatars
      ref.invalidate(currentUserProvider);
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily != null) {
        ref.invalidate(familyMembersProvider(currentFamily.id));
        
        // Invalidate user profile provider for current user to refresh avatar everywhere
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          ref.invalidate(userProfileProvider(currentUser.id));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // App bar is provided by MainShell
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.padding(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: ResponsiveHelper.h(32)),

                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: _selectedImage != null
                              ? CircleAvatar(
                                  radius: ResponsiveHelper.r(60),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  backgroundImage: FileImage(_selectedImage!),
                                  child: null,
                                )
                              : AvatarWidget(
                                  avatarPath: _currentImageUrl,
                                  radius: ResponsiveHelper.r(60),
                                  displayName: _displayNameController.text.trim().isNotEmpty
                                      ? _displayNameController.text.trim()
                                      : null,
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  textColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: ResponsiveHelper.padding(all: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  width: ResponsiveHelper.w(2),
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: ResponsiveHelper.iconSize(20),
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.h(8)),

                  Text(
                    'Tap to change profile picture',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),

                  SizedBox(height: ResponsiveHelper.h(32)),

                  // Display Name Field
                  Card(
                    child: Padding(
                      padding: ResponsiveHelper.padding(all: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Display Name',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: ResponsiveHelper.h(8)),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your display name',
                              border: OutlineInputBorder(
                                borderRadius: ResponsiveHelper.borderRadius(8),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a display name';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.h(32)),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: ResponsiveHelper.padding(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: ResponsiveHelper.borderRadius(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: ResponsiveHelper.h(20),
                              width: ResponsiveHelper.w(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.h(40)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

