import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:edu_platform_app/core/constants/app_colors.dart';
import 'package:edu_platform_app/data/models/auth_models.dart';
import 'package:edu_platform_app/data/services/auth_service.dart';
import 'package:edu_platform_app/data/services/token_service.dart';
import 'package:edu_platform_app/data/services/settings_service.dart';
import 'package:edu_platform_app/data/services/theme_service.dart';

import '../auth/complete_profile_screen.dart';
import '../teacher/complete_teacher_profile_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback? onDeleteAccount;

  const SettingsScreen({
    super.key,
    required this.onLogout,
    this.onDeleteAccount,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  String _version = '';
  bool _deleteAccountEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final versionResponse = await _settingsService.getVersion();
    final deleteAccountResponse =
        await _settingsService.getDeleteAccountEnabled();

    if (mounted) {
      setState(() {
        _version = (versionResponse.succeeded && versionResponse.data != null)
            ? versionResponse.data!
            : '1.0.0';
        _deleteAccountEnabled =
            deleteAccountResponse.succeeded &&
                (deleteAccountResponse.data ?? false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: isDark
          ? const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF130808),
                  Color(0xFF0D0505),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            )
          : null,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Hero Header ───
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: _buildHeroHeader(isDark),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // ─── Account Section ───
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 100),
                    child: _buildSectionLabel('الحساب', isDark),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 150),
                    child: _buildGlassCard(
                      isDark: isDark,
                      children: [
                        _buildTile(
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF4ECDC4),
                          title: 'تعديل الملف الشخصي',
                          subtitle: 'تحديث معلوماتك الشخصية',
                          isDark: isDark,
                          onTap: () async {
                            final tokenService = TokenService();
                            final role = await tokenService.getRole();
                            if (role == 'Student' && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CompleteProfileScreen(
                                      isFirstLogin: false),
                                ),
                              );
                            } else if (role == 'Teacher' && context.mounted) {
                              final teacherId =
                                  await tokenService.getTeacherId();
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CompleteTeacherProfileScreen(
                                            teacherId: teacherId),
                                  ),
                                );
                              }
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تعديل الملف الشخصي متاح للطلاب والمعلمين فقط حالياً',
                                    style: GoogleFonts.outfit(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          },
                        ),
                        _buildDivider(isDark),
                        _buildTile(
                          icon: Icons.lock_rounded,
                          iconColor: const Color(0xFFFF6B6B),
                          title: 'تغيير كلمة المرور',
                          subtitle: 'تحديث بيانات الأمان',
                          isDark: isDark,
                          onTap: () => _showChangePasswordSheet(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Preferences Section ───
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionLabel('التفضيلات', isDark),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 250),
                    child: _buildGlassCard(
                      isDark: isDark,
                      children: [
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeService.themeModeNotifier,
                          builder: (context, mode, child) {
                            final isDarkMode = mode == ThemeMode.dark;
                            return _buildToggleTile(
                              icon: isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              iconColor: const Color(0xFFFFD93D),
                              title: 'الوضع الداكن',
                              subtitle: isDarkMode ? 'مفعّل' : 'غير مفعّل',
                              isDark: isDark,
                              value: isDarkMode,
                              onChanged: (val) {
                                ThemeService.switchTheme(
                                    val ? ThemeMode.dark : ThemeMode.light);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Support Section ───
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 300),
                    child: _buildSectionLabel('الدعم', isDark),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 350),
                    child: _buildGlassCard(
                      isDark: isDark,
                      children: [
                        _buildTile(
                          icon: Icons.info_rounded,
                          iconColor: const Color(0xFF74B9FF),
                          title: 'حول التطبيق',
                          subtitle: 'الإصدار $_version',
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── Logout Button ───
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 400),
                    child: _buildLogoutButton(isDark),
                  ),

                  if (_deleteAccountEnabled) ...[
                    const SizedBox(height: 14),
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 450),
                      child: _buildDeleteAccountButton(isDark),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Header ───
  Widget _buildHeroHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.18),
                  const Color(0xFF1A0808),
                  const Color(0xFF0D0505),
                ],
              )
            : AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: isDark
            ? Border.all(color: AppColors.primary.withOpacity(0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: isDark ? AppColors.primary : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإعدادات',
                  style: GoogleFonts.tajawal(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة تفضيلات التطبيق',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withOpacity(isDark ? 0.45 : 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Text(
              'v$_version',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Label ───
  Widget _buildSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ─── Glass Card Container ───
  Widget _buildGlassCard({required bool isDark, required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  // ─── Tile ───
  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final effectiveColor = isDestructive ? AppColors.error : iconColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: effectiveColor.withOpacity(0.08),
        highlightColor: effectiveColor.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      effectiveColor.withOpacity(isDark ? 0.22 : 0.14),
                      effectiveColor.withOpacity(isDark ? 0.1 : 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: effectiveColor.withOpacity(isDark ? 0.2 : 0.12),
                  ),
                ),
                child: Icon(icon, size: 22, color: effectiveColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDestructive
                            ? AppColors.error
                            : (isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Toggle Tile ───
  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withOpacity(isDark ? 0.22 : 0.14),
                      iconColor.withOpacity(isDark ? 0.1 : 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withOpacity(isDark ? 0.2 : 0.12),
                  ),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Custom styled switch
              GestureDetector(
                onTap: () => onChanged(!value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 52,
                  height: 28,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: value
                        ? AppColors.primaryGradient
                        : LinearGradient(colors: [
                            isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            isDark ? Colors.grey[800]! : Colors.grey[400]!,
                          ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    alignment:
                        value ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              (isDark ? Colors.white : Colors.black).withOpacity(0.06),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ─── Logout Button ───
  Widget _buildLogoutButton(bool isDark) {
    return GestureDetector(
      onTap: widget.onLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.error.withOpacity(isDark ? 0.25 : 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete Account Button ───
  Widget _buildDeleteAccountButton(bool isDark) {
    return GestureDetector(
      onTap: widget.onDeleteAccount,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withOpacity(isDark ? 0.15 : 0.08),
              AppColors.error.withOpacity(isDark ? 0.08 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'حذف الحساب',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Change Password Bottom Sheet ───
  void _showChangePasswordSheet(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        bool isLoading = false;
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141010) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 40,
                      offset: const Offset(0, -8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Sheet header ──
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تغيير كلمة المرور',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'حافظ على أمان حسابك',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () => Navigator.pop(sheetContext),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Form ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            _buildPasswordField(
                              label: 'كلمة المرور الحالية',
                              hint: 'أدخل كلمة المرور الحالية',
                              icon: Icons.lock_outline_rounded,
                              obscureText: obscureCurrent,
                              isDark: isDark,
                              controller: currentPasswordController,
                              onToggleObscure: () =>
                                  setSheetState(() => obscureCurrent = !obscureCurrent),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'الرجاء إدخال كلمة المرور الحالية';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildSheetDivider(isDark),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              label: 'كلمة المرور الجديدة',
                              hint: 'أدخل كلمة المرور الجديدة',
                              icon: Icons.lock_reset_rounded,
                              obscureText: obscureNew,
                              isDark: isDark,
                              controller: newPasswordController,
                              onToggleObscure: () =>
                                  setSheetState(() => obscureNew = !obscureNew),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'الرجاء إدخال كلمة المرور الجديدة';
                                }
                                if (v.length < 6) {
                                  return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              label: 'تأكيد كلمة المرور',
                              hint: 'أعد إدخال كلمة المرور الجديدة',
                              icon: Icons.check_circle_outline_rounded,
                              obscureText: obscureConfirm,
                              isDark: isDark,
                              controller: confirmPasswordController,
                              onToggleObscure: () =>
                                  setSheetState(() => obscureConfirm = !obscureConfirm),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'الرجاء تأكيد كلمة المرور';
                                }
                                if (v != newPasswordController.text) {
                                  return 'كلمات المرور غير متطابقة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // ── Buttons ──
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () => Navigator.pop(sheetContext),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'إلغاء',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textSecondary
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () async {
                                            if (formKey.currentState!.validate()) {
                                              setSheetState(() => isLoading = true);
                                              try {
                                                final tokenService = TokenService();
                                                final userId =
                                                    await tokenService.getUserGuid();
                                                if (userId == null) {
                                                  setSheetState(() => isLoading = false);
                                                  if (sheetContext.mounted) {
                                                    _showResultSnackbar(sheetContext,
                                                        'خطأ في الحصول على معرف المستخدم',
                                                        success: false);
                                                  }
                                                  return;
                                                }
                                                final authService = AuthService();
                                                final response =
                                                    await authService.changePassword(
                                                  ChangePasswordRequest(
                                                    id: userId,
                                                    currentPassword:
                                                        currentPasswordController.text,
                                                    newPassword:
                                                        newPasswordController.text,
                                                    confirmPassword:
                                                        confirmPasswordController.text,
                                                  ),
                                                );
                                                setSheetState(() => isLoading = false);
                                                if (sheetContext.mounted) {
                                                  Navigator.pop(sheetContext);
                                                  _showResultSnackbar(sheetContext,
                                                      response.message,
                                                      success: response.succeeded);
                                                }
                                              } catch (e) {
                                                setSheetState(() => isLoading = false);
                                                if (sheetContext.mounted) {
                                                  _showResultSnackbar(sheetContext,
                                                      'حدث خطأ: $e',
                                                      success: false);
                                                }
                                              }
                                            }
                                          },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      decoration: BoxDecoration(
                                        gradient: isLoading
                                            ? LinearGradient(colors: [
                                                AppColors.primary.withOpacity(0.5),
                                                AppColors.primaryDark.withOpacity(0.5),
                                              ])
                                            : AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: isLoading
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: AppColors.primary.withOpacity(0.4),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: isLoading
                                              ? const SizedBox(
                                                  key: ValueKey('loading'),
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Row(
                                                  key: const ValueKey('text'),
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.lock_reset_rounded,
                                                        color: Colors.white, size: 18),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'تغيير كلمة المرور',
                                                      style: GoogleFonts.tajawal(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height: MediaQuery.of(sheetContext).padding.bottom + 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showResultSnackbar(BuildContext ctx, String message, {required bool success}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSheetDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  (isDark ? Colors.white : Colors.black).withOpacity(0.07),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 12),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? Colors.white : Colors.black).withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    required bool isDark,
    IconData icon = Icons.lock_outline_rounded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          cursorColor: AppColors.primary,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.textMuted.withOpacity(0.45)
                  : AppColors.textMutedLight.withOpacity(0.5),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon,
                  size: 20, color: AppColors.primary.withOpacity(0.6)),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 48, minHeight: 48),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
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
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  key: ValueKey(obscureText),
                  color: isDark
                      ? AppColors.textMuted.withOpacity(0.5)
                      : AppColors.textMutedLight.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
