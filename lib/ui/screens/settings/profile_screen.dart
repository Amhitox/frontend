import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/models/user.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late UserProvider _userProvider;
  late AuthProvider _authProvider;
  bool _isLoading = false;
  bool _isSaving = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _workEmailController = TextEditingController();
  final _langController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
    _loadUserData();
  }
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = _authProvider.user;
      if (user != null) {
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _emailController.text = user.email ?? '';
        _workEmailController.text = user.workEmail ?? '';
        _langController.text = user.lang ?? 'en';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    _slideController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _workEmailController.dispose();
    _langController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withValues(alpha: 0.1),
              theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(isTablet, isLargeScreen, theme),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isLargeScreen
                              ? 24
                              : isTablet
                              ? 20
                              : 16,
                    ),
                    child: Column(
                      children: [
                        _buildProfileCard(isTablet, isLargeScreen, theme),
                        SizedBox(height: isTablet ? 20 : 16),
                        _buildPersonalInfoSection(
                          isTablet,
                          isLargeScreen,
                          theme,
                        ),
                        SizedBox(height: isTablet ? 48 : 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildHeader(bool isTablet, bool isLargeScreen, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(
        isLargeScreen
            ? 24
            : isTablet
            ? 20
            : 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.goNamed('settings'),
            child: Container(
              width: isTablet ? 44 : 40,
              height: isTablet ? 44 : 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
                size: isTablet ? 22 : 20,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize:
                    isLargeScreen
                        ? 24
                        : isTablet
                        ? 22
                        : 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isSaving ? null : () => _saveProfile(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 18 : 16,
                vertical: isTablet ? 10 : 8,
              ),
              decoration: BoxDecoration(
                color:
                    _isSaving
                        ? theme.colorScheme.outline.withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                border: Border.all(
                  color:
                      _isSaving
                          ? theme.colorScheme.outline.withValues(alpha: 0.3)
                          : theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child:
                  _isSaving
                      ? SizedBox(
                        width: isTablet ? 20 : 16,
                        height: isTablet ? 20 : 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      )
                      : Text(
                        'Save',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProfileCard(bool isTablet, bool isLargeScreen, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.1),
            theme.colorScheme.surface.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _changeProfileImage(theme, isTablet),
            child: Container(
              width: isTablet ? 120 : 100,
              height: isTablet ? 120 : 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    theme.colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onSurface,
                size: isTablet ? 60 : 50,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            '${_firstNameController.text} ${_lastNameController.text}',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize:
                  isLargeScreen
                      ? 26
                      : isTablet
                      ? 24
                      : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            _emailController.text,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPersonalInfoSection(
    bool isTablet,
    bool isLargeScreen,
    ThemeData theme,
  ) {
    return _buildSection(
      'Personal Information',
      Icons.person_outline,
      [
        _buildFormField(
          'First Name',
          _firstNameController,
          isTablet: isTablet,
          theme: theme,
        ),
        _buildFormField(
          'Last Name',
          _lastNameController,
          isTablet: isTablet,
          theme: theme,
        ),
        _buildFormField(
          'Email',
          _emailController,
          isTablet: isTablet,
          theme: theme,
        ),
        _buildFormField(
          'Work Email',
          _workEmailController,
          isTablet: isTablet,
          theme: theme,
        ),
        _buildFormField(
          'Language',
          _langController,
          isTablet: isTablet,
          theme: theme,
        ),
      ],
      isTablet: isTablet,
      isLargeScreen: isLargeScreen,
      theme: theme,
    );
  }
  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> items, {
    required bool isTablet,
    required bool isLargeScreen,
    required ThemeData theme,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: isTablet ? 10 : 8,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: isTablet ? 20 : 18,
                ),
                SizedBox(width: isTablet ? 10 : 8),
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    fontSize:
                        isLargeScreen
                            ? 18
                            : isTablet
                            ? 16
                            : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }
  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    required bool isTablet,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: isTablet ? 15 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 15 : 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter $label',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 14 : 12,
                  vertical: isTablet ? 10 : 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _changeProfileImage(ThemeData theme, bool isTablet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(top: isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 20),
                _buildPhotoOption(
                  'Take Photo',
                  Icons.camera_alt,
                  () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                  theme,
                  isTablet,
                ),
                _buildPhotoOption(
                  'Choose from Gallery',
                  Icons.photo_library,
                  () {
                    Navigator.pop(context);
                    _chooseFromGallery();
                  },
                  theme,
                  isTablet,
                ),
                _buildPhotoOption(
                  'Remove Photo',
                  Icons.delete,
                  () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                  theme,
                  isTablet,
                ),
                SizedBox(height: isTablet ? 24 : 20),
              ],
            ),
          ),
    );
  }
  Widget _buildPhotoOption(
    String title,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              size: isTablet ? 22 : 20,
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Camera opened for photo capture'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  void _chooseFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gallery opened for photo selection'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  void _removePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile photo removed'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  bool _validateForm() {
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('First name is required'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Last name is required'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email is required'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    if (_workEmailController.text.trim().isNotEmpty &&
        !emailRegex.hasMatch(_workEmailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid work email address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }
  Future<void> _saveProfile() async {
    if (!_validateForm()) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final currentUser = _authProvider.user;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }
      final updatedUser = User(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        workEmail:
            _workEmailController.text.trim().isEmpty
                ? null
                : _workEmailController.text.trim(),
        lang:
            _langController.text.trim().isEmpty
                ? 'en'
                : _langController.text.trim(),
        uid: currentUser.uid,
        id: currentUser.id,
        status: currentUser.status,
        subscriptionTier: currentUser.subscriptionTier,
      );
      final response = await _userProvider.updateUser(
        currentUser.id,
        updatedUser,
      );
      if (response != null) {
        await _userProvider.updateUserData(updatedUser);
        _authProvider.updateUserInMemory(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.goNamed('settings');
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
