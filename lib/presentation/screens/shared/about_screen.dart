import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:edu_platform_app/core/constants/app_colors.dart';
import 'package:edu_platform_app/data/services/settings_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  final _settingsService = SettingsService();
  bool _isLoading = true;
  String _aboutText = '';
  String _errorMessage = '';
  String _version = '1.0.0';

  late AnimationController _logoRotationController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    // Continuous smooth spin — one full rotation every 6 seconds
    _logoRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _loadAboutUs();
  }

  @override
  void dispose() {
    _logoRotationController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadAboutUs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _settingsService.getAboutUs();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.succeeded && response.data != null) {
          _aboutText = response.data!;
        } else {
          _errorMessage = response.message;
          _aboutText = '';
        }
      });
    }

    final versionResponse = await _settingsService.getVersion();
    if (mounted) {
      setState(() {
        if (versionResponse.succeeded && versionResponse.data != null) {
          _version = versionResponse.data!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated background ──────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                final t = _bgController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? const [
                              Color(0xFF0A0000),
                              Color(0xFF1A0000),
                              Color(0xFF0A0000)
                            ]
                          : const [
                              Colors.white,
                              Color(0xFFFFF5F5),
                              Colors.white
                            ],
                      stops: [
                        0.0,
                        0.5 + 0.12 * math.sin(t * 2 * math.pi),
                        1.0
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Top red orb ──────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(isDark ? 0.22 : 0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(isDark ? 0.15 : 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Main scrollable content ──────────────────────
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
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
                            size: 17,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'حول التطبيق',
                            style: GoogleFonts.tajawal(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40, height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'جاري التحميل...',
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          child: Column(
                            children: [
                              // ── Hero section ──────────────
                              FadeInDown(
                                duration: const Duration(milliseconds: 700),
                                child: Column(
                                  children: [
                                    // Logo with glow rings
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Outer glow
                                        AnimatedBuilder(
                                          animation: _bgController,
                                          builder: (_, __) => Container(
                                            width: 160,
                                            height: 160,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(colors: [
                                                AppColors.primary.withOpacity(
                                                    0.15 +
                                                        0.08 *
                                                            math.sin(
                                                                _bgController
                                                                        .value *
                                                                    2 *
                                                                    math.pi)),
                                                Colors.transparent,
                                              ]),
                                            ),
                                          ),
                                        ),
                                        // Inner container
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark
                                                ? Colors.white.withOpacity(0.06)
                                                : Colors.white.withOpacity(
                                                    0.9),
                                            border: Border.all(
                                              color: AppColors.primary
                                                  .withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.2),
                                                blurRadius: 28,
                                                spreadRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: RotationTransition(
                                            turns: _logoRotationController,
                                            child: Image.asset(
                                              'assets/images/logo_icon.png',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // App name
                                    ShaderMask(
                                      shaderCallback: (r) =>
                                          LinearGradient(colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.6),
                                      ]).createShader(r),
                                      child: Text(
                                        'منصة بوصلة',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bosla Platform',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                        letterSpacing: 2.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Version badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(30),
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withOpacity(0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_rounded,
                                              size: 14,
                                              color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'الإصدار $_version',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── About card ────────────────
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 200),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1A0D10)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withOpacity(isDark ? 0.12 : 0.08),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                            isDark ? 0.08 : 0.05),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Card header
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 18, 20, 16),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppColors.primary
                                                  .withOpacity(
                                                      isDark ? 0.1 : 0.07),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.primary
                                                    .withOpacity(0.12),
                                                border: Border.all(
                                                  color: AppColors.primary
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.info_outline_rounded,
                                                color: AppColors.primary,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'عن المنصة',
                                              style: GoogleFonts.tajawal(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const Spacer(),
                                            // Decorative dots
                                            Row(
                                              children: List.generate(
                                                  3,
                                                  (i) => Container(
                                                        width: 6,
                                                        height: 6,
                                                        margin:
                                                            const EdgeInsets
                                                                .only(left: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(
                                                                  0.3 -
                                                                      i * 0.08),
                                                        ),
                                                      )),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Card body
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (_errorMessage.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                margin: const EdgeInsets.only(
                                                    bottom: 16),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12),
                                                  border: Border.all(
                                                    color: AppColors.error
                                                        .withOpacity(0.25),
                                                  ),
                                                ),
                                                child: Row(children: [
                                                  const Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: AppColors.error,
                                                      size: 18),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _errorMessage,
                                                      style: GoogleFonts.outfit(
                                                          fontSize: 13,
                                                          color:
                                                              AppColors.error),
                                                    ),
                                                  ),
                                                ]),
                                              ),

                                            if (_aboutText.isNotEmpty)
                                              Text(
                                                _aboutText,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  height: 2.0,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.black54,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),

                                            if (_aboutText.isEmpty &&
                                                _errorMessage.isEmpty)
                                              Text(
                                                'وجهتك الأولى نحو التفوق والتميز',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  height: 2.0,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.black54,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Stats row ─────────────────
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 350),
                                child: Row(
                                  children: [
                                    _statCard(
                                        isDark,
                                        Icons.school_rounded,
                                        'تعليم',
                                        'متميز'),
                                    const SizedBox(width: 12),
                                    _statCard(
                                        isDark,
                                        Icons.verified_user_rounded,
                                        'موثوق',
                                        '100%'),
                                    const SizedBox(width: 12),
                                    _statCard(
                                        isDark,
                                        Icons.star_rounded,
                                        'جودة',
                                        'عالية'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── Footer ────────────────────
                              FadeInUp(
                                duration: const Duration(milliseconds: 700),
                                delay: const Duration(milliseconds: 450),
                                child: Column(
                                  children: [
                                    Text(
                                      '© ${DateTime.now().year} منصة بوصلة · جميع الحقوق محفوظة',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Powered by Eng / Abdullah Al-Najjer',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary
                                            .withOpacity(0.45),
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      bool isDark, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A0D10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                AppColors.primary.withOpacity(isDark ? 0.1 : 0.08),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
