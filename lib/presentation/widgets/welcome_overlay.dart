import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edu_platform_app/core/constants/app_colors.dart';

/// Shows a full-screen animated welcome overlay for [duration] then calls [onComplete].
Future<void> showWelcomeOverlay(
  BuildContext context, {
  required String firstName,
  Duration duration = const Duration(milliseconds: 2600),
  required VoidCallback onComplete,
}) async {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _WelcomeOverlayWidget(
      firstName: firstName,
      onDone: () {
        entry.remove();
        onComplete();
      },
      duration: duration,
    ),
  );

  overlay.insert(entry);
}

class _WelcomeOverlayWidget extends StatefulWidget {
  final String firstName;
  final VoidCallback onDone;
  final Duration duration;

  const _WelcomeOverlayWidget({
    required this.firstName,
    required this.onDone,
    required this.duration,
  });

  @override
  State<_WelcomeOverlayWidget> createState() => _WelcomeOverlayWidgetState();
}

class _WelcomeOverlayWidgetState extends State<_WelcomeOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _exitCtrl;

  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _checkScale;
  late Animation<double> _textSlide;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _exitCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _scaleIn = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.3, 0.7, curve: Curves.elasticOut)),
    );
    _textSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _mainCtrl.forward();

    // Auto exit
    Future.delayed(widget.duration - const Duration(milliseconds: 500), () {
      if (mounted) {
        _exitCtrl.forward().then((_) {
          if (mounted) widget.onDone();
        });
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _orbCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_mainCtrl, _orbCtrl, _exitCtrl]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitFade.value,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0000),
                    Color(0xFF1A0505),
                    Color(0xFF0D0000),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Animated red orbs ──
                  _buildOrb(
                    size: 400,
                    top: -100,
                    left: -100,
                    opacity: 0.25,
                    phase: 0,
                  ),
                  _buildOrb(
                    size: 320,
                    bottom: -80,
                    right: -80,
                    opacity: 0.18,
                    phase: math.pi,
                  ),
                  _buildOrb(
                    size: 200,
                    top: size.height * 0.45,
                    right: -40,
                    opacity: 0.12,
                    phase: math.pi / 2,
                  ),

                  // ── Radial glow center ──
                  Opacity(
                    opacity: _fadeIn.value * 0.35,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Main content ──
                  Opacity(
                    opacity: _fadeIn.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Check circle
                        Transform.scale(
                          scale: _checkScale.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 80,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 56,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Welcome title
                        Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Text(
                            'مرحباً بك 👋',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.65),
                              letterSpacing: 1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Transform.scale(
                            scale: _scaleIn.value.clamp(0.8, 1.0),
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.primaryGradient.createShader(bounds),
                              child: Text(
                                widget.firstName,
                                style: GoogleFonts.tajawal(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              'تم تسجيل الدخول بنجاح ✓',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Animated loading dots
                        Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: _buildLoadingDots(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrb({
    required double size,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double opacity,
    required double phase,
  }) {
    final t = _orbCtrl.value;
    final pulse = 0.85 + 0.15 * math.sin(t * 2 * math.pi + phase);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.scale(
        scale: pulse,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(opacity),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final t = _orbCtrl.value;
        final offset = math.sin(t * 2 * math.pi - index * 0.8) * 6;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: index == 1 ? 10 : 8,
            height: index == 1 ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 1
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.4),
              boxShadow: index == 1
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
