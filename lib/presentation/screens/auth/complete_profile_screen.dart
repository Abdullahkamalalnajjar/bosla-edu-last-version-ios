import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edu_platform_app/core/constants/app_colors.dart';
import 'package:edu_platform_app/data/services/student_service.dart';
import 'package:edu_platform_app/data/services/token_service.dart';
import 'package:edu_platform_app/data/services/location_service.dart';
import 'package:edu_platform_app/data/models/api_response.dart';
import 'package:edu_platform_app/presentation/widgets/app_background.dart';
import 'package:edu_platform_app/presentation/screens/auth/login_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final bool isFirstLogin;
  final int? userId;
  const CompleteProfileScreen({
    super.key,
    this.isFirstLogin = false,
    this.userId,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _studentService = StudentService();
  final _locationService = LocationService();
  final _tokenService = TokenService();
  final _imagePicker = ImagePicker();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _cityController = TextEditingController();

  String? _selectedGovernorate;
  List<String> _governorates = [];
  bool _isLoading = false;
  int? _currentStudentId;
  File? _profileImage;
  String? _currentPhotoUrl;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _initData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentPhoneController.dispose();
    _parentPhoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _fetchGovernorates();
    if (!widget.isFirstLogin) {
      await _fetchProfileData();
    }
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _studentService.getProfile();
      if (response.succeeded && response.data != null) {
        final data = response.data!;
        if (!mounted) return;

        if (data.containsKey('studentId')) {
          _currentStudentId = data['studentId'];
        } else if (data.containsKey('id')) {
          _currentStudentId = data['id'];
        } else if (data.containsKey('userId')) {
          _currentStudentId = data['userId'];
        }

        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _studentPhoneController.text = data['studentPhoneNumber'] ?? '';
          _parentPhoneController.text = data['parentPhoneNumber'] ?? '';
          _cityController.text = data['city'] ?? '';
          _currentPhotoUrl = data['studentProfileImageUrl'];

          final gov = data['governorate'];
          if (gov != null) {
            _selectedGovernorate = gov;
            if (!_governorates.contains(gov)) {
              _governorates.add(gov);
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGovernorates() async {
    final response = await _locationService.getGovernorates();
    if (response.succeeded && response.data != null) {
      if (!mounted) return;
      setState(() {
        _governorates = response.data!;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'اختر مصدر الصورة',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'المعرض',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                      isDark: isDark,
                    ),
                    _buildImageSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'الكاميرا',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );

      if (source != null) {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() {
            _profileImage = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('فشل اختيار الصورة');
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGovernorate == null) {
      _showErrorSnackBar('الرجاء اختيار المحافظة');
      return;
    }

    setState(() => _isLoading = true);

    final userId = widget.userId ?? await _tokenService.getUserId();
    final int studentIdVal = _currentStudentId ?? userId ?? 0;
    final String? userGuid = await _tokenService.getUserGuid();

    print(
      'Submitting Profile. Int ID: $studentIdVal, GUID: $userGuid (IsFirstLogin: ${widget.isFirstLogin})',
    );

    ApiResponse<bool> response;

    if (widget.isFirstLogin) {
      response = await _studentService.createProfile(
        studentId: studentIdVal,
        gradeYear: 0,
        studentPhoneNumber: _studentPhoneController.text,
        parentPhoneNumber: _parentPhoneController.text,
        governorate: _selectedGovernorate!,
        city: _cityController.text,
      );
    } else {
      response = await _studentService.updateProfile(
        studentId: userGuid ?? studentIdVal.toString(),
        gradeYear: 0,
        studentPhoneNumber: _studentPhoneController.text,
        parentPhoneNumber: _parentPhoneController.text,
        governorate: _selectedGovernorate!,
        city: _cityController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        profileImagePath: _profileImage?.path,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.succeeded) {
      if (widget.isFirstLogin) {
        if (userId != null) {
          await _tokenService.setProfileCompleted(userId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم استكمال البيانات بنجاح، يرجى تسجيل الدخول مرة أخرى',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تم تعديل الملف الشخصي بنجاح',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      _showErrorSnackBar(response.message);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AppBackground(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── Hero Header with Avatar ───
                SliverToBoxAdapter(
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: _buildHeroHeader(isDark, screenWidth),
                  ),
                ),

                // ─── Form Content ───
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ─── Personal Info ───
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 200),
                            child: _buildGlassSection(
                              isDark: isDark,
                              icon: Icons.person_rounded,
                              title: 'المعلومات الشخصية',
                              children: [
                                _buildModernTextField(
                                  controller: _firstNameController,
                                  label: 'الاسم الأول',
                                  icon: Icons.badge_outlined,
                                  isDark: isDark,
                                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller: _lastNameController,
                                  label: 'الاسم الأخير',
                                  icon: Icons.badge_outlined,
                                  isDark: isDark,
                                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ─── Contact Info ───
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 300),
                            child: _buildGlassSection(
                              isDark: isDark,
                              icon: Icons.phone_rounded,
                              title: 'معلومات الاتصال',
                              children: [
                                _buildModernTextField(
                                  controller: _studentPhoneController,
                                  label: 'رقم هاتفك',
                                  icon: Icons.phone_android_rounded,
                                  isDark: isDark,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller: _parentPhoneController,
                                  label: 'رقم ولي الأمر',
                                  icon: Icons.family_restroom_rounded,
                                  isDark: isDark,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ─── Location Section ───
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 400),
                            child: _buildGlassSection(
                              isDark: isDark,
                              icon: Icons.location_on_rounded,
                              title: 'الموقع',
                              children: [
                                _buildGovernorateDropdown(isDark),
                                const SizedBox(height: 16),
                                _buildModernTextField(
                                  controller: _cityController,
                                  label: 'المدينة',
                                  icon: Icons.location_city_rounded,
                                  isDark: isDark,
                                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ─── Floating Save Button ───
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: FadeInUp(
                duration: const Duration(milliseconds: 700),
                delay: const Duration(milliseconds: 500),
                child: _buildSaveButton(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Header ───
  Widget _buildHeroHeader(bool isDark, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF2A0A0A),
                  const Color(0xFF1A0505),
                  Colors.transparent,
                ]
              : [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.primary.withOpacity(0.03),
                  Colors.transparent,
                ],
        ),
      ),
      child: Column(
        children: [
          // ─── Top Bar ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.isFirstLogin)
                  _buildBackButton(isDark)
                else
                  const SizedBox(width: 44),
                Text(
                  widget.isFirstLogin ? 'استكمال البيانات' : 'تعديل الملف الشخصي',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Avatar ───
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated glow ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          startAngle: _shimmerController.value * 6.28,
                          colors: [
                            AppColors.primary.withOpacity(0.6),
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.0),
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    // Inner white/dark ring
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                      ),
                    ),
                    // Image container
                    Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 24,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 124,
                                height: 124,
                              )
                            : _currentPhotoUrl != null &&
                                    _currentPhotoUrl!.isNotEmpty
                                ? Image.network(
                                    _currentPhotoUrl!,
                                    fit: BoxFit.cover,
                                    width: 124,
                                    height: 124,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildAvatarPlaceholder(isDark);
                                    },
                                  )
                                : _buildAvatarPlaceholder(isDark),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ─── Title Text ───
          Text(
            widget.isFirstLogin ? 'مرحباً بك! 👋' : 'تعديل بياناتك',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isFirstLogin
                ? 'يرجى استكمال بياناتك الدراسية للبدء'
                : 'قم بتحديث معلوماتك الشخصية',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondary.withOpacity(0.7)
                  : AppColors.textSecondaryLight.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(bool isDark) {
    return Container(
      width: 124,
      height: 124,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF141414)]
              : [Colors.grey[100]!, Colors.grey[200]!],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 52,
        color: isDark
            ? AppColors.textMuted.withOpacity(0.5)
            : AppColors.textMutedLight.withOpacity(0.5),
      ),
    );
  }

  // ─── Glass Section Card ───
  Widget _buildGlassSection({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.primary.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(isDark ? 0.2 : 0.12),
                          AppColors.primary.withOpacity(isDark ? 0.1 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Gradient divider
              Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.4),
                      AppColors.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // ─── Modern Text Field ───
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isDark
                    ? AppColors.textMuted
                    : AppColors.textMutedLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        // Input field
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          cursorColor: AppColors.primary,
          style: GoogleFonts.inter(
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: GoogleFonts.inter(
              color: isDark
                  ? AppColors.textMuted.withOpacity(0.5)
                  : AppColors.textMutedLight.withOpacity(0.5),
              fontSize: 14,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            prefixIcon: Container(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Governorate Dropdown ───
  Widget _buildGovernorateDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Row(
            children: [
              Icon(
                Icons.map_outlined,
                size: 14,
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              ),
              const SizedBox(width: 6),
              Text(
                'المحافظة',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGovernorate,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'اختر المحافظة',
                      style: GoogleFonts.inter(
                        color: isDark
                            ? AppColors.textMuted.withOpacity(0.5)
                            : AppColors.textMutedLight.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              isExpanded: true,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              icon: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                ),
              ),
              items: _governorates.map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      g,
                      style: GoogleFonts.inter(
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedGovernorate = v),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Save Button ───
  Widget _buildSaveButton(bool isDark) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSubmit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.primaryDark.withOpacity(0.5),
                  ],
                )
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(_isLoading ? 0.1 : 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            if (!_isLoading)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    key: const ValueKey('content'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.isFirstLogin ? 'حفظ ومتابعة' : 'حفظ التعديلات',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
