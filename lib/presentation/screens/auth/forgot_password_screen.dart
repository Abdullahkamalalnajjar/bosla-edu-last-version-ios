import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:edu_platform_app/core/constants/app_colors.dart';
import 'package:edu_platform_app/data/models/auth_models.dart';
import 'package:edu_platform_app/data/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _email = '';

  Timer? _resendTimer;
  int _resendCountdown = 0;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));

    _cardController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _bgController.dispose();
    _cardController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _cardController.forward(from: 0);
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    _email = _emailController.text.trim();
    final response = await _authService.sendOtp(_email);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response.succeeded) {
      _startResendTimer();
      _goToStep(1);
      _showSnack(response.message, true);
    } else {
      _showSnack(response.message, false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showSnack('الرجاء إدخال رمز التحقق كاملاً', false);
      return;
    }
    setState(() => _isLoading = true);
    final response = await _authService.verifyOtp(VerifyOtpRequest(email: _email, otp: otp));
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response.succeeded) {
      _goToStep(2);
      _showSnack(response.message, true);
    } else {
      _showSnack(response.message, false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack('كلمات المرور غير متطابقة', false);
      return;
    }
    setState(() => _isLoading = true);
    final response = await _authService.resetPassword(
      ResetPasswordRequest(email: _email, newPassword: _newPasswordController.text),
    );
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response.succeeded) {
      _showSnack(response.message, true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnack(response.message, false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;
    setState(() => _isLoading = true);
    final response = await _authService.sendOtp(_email);
    setState(() => _isLoading = false);
    if (!mounted) return;
    if (response.succeeded) {
      _startResendTimer();
      _showSnack('تم إعادة إرسال رمز التحقق', true);
    } else {
      _showSnack(response.message, false);
    }
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.outfit())),
      ]),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated Background ──
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
                          ? const [Color(0xFF0A0000), Color(0xFF1A0000), Color(0xFF0A0000)]
                          : const [Colors.white, Color(0xFFFFF5F5), Colors.white],
                      stops: [0.0, 0.5 + 0.15 * math.sin(t * 2 * math.pi), 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Decorative orbs ──
          Positioned(
            top: -100, left: -80,
            child: _orb(300, isDark ? 0.25 : 0.12),
          ),
          Positioned(
            bottom: -80, right: -80,
            child: _orb(280, isDark ? 0.18 : 0.09),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                // AppBar row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_currentStep > 0) {
                            _goToStep(_currentStep - 1);
                          } else {
                            Navigator.pop(context);
                          }
                        },
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
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'استعادة كلمة المرور',
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

                const SizedBox(height: 24),

                // Step pills
                _buildStepPills(isDark),

                const SizedBox(height: 28),

                // Card content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: _buildCard(isDark, size),
                      ),
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

  Widget _orb(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            AppColors.primary.withOpacity(opacity),
            Colors.transparent,
          ]),
        ),
      );

  // ── Step Pills ──────────────────────────────────────
  Widget _buildStepPills(bool isDark) {
    final steps = [
      (Icons.email_outlined, 'البريد'),
      (Icons.pin_outlined, 'التحقق'),
      (Icons.lock_reset_rounded, 'كلمة المرور'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // connector line
            final stepIdx = i ~/ 2;
            final done = _currentStep > stepIdx;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: done
                      ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)])
                      : null,
                  color: done ? null : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final isActive = _currentStep >= stepIdx;
          final isCurrent = _currentStep == stepIdx;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: EdgeInsets.symmetric(
              horizontal: isCurrent ? 14 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
                    )
                  : null,
              color: isActive ? null : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
              boxShadow: isCurrent
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(steps[stepIdx].$1, size: 16, color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.black38)),
                if (isCurrent) ...[
                  const SizedBox(width: 6),
                  Text(
                    steps[stepIdx].$2,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Card Switcher ────────────────────────────────────
  Widget _buildCard(bool isDark, Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A0D10) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.primary.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.10 : 0.07),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: _currentStep == 0
            ? _emailStep(isDark)
            : _currentStep == 1
                ? _otpStep(isDark)
                : _passwordStep(isDark),
      ),
    );
  }

  // ── Step 0: Email ───────────────────────────────────
  Widget _emailStep(bool isDark) {
    return Column(
      children: [
        _iconCircle(Icons.mark_email_read_rounded, AppColors.primary, isDark),
        const SizedBox(height: 20),
        Text('أدخل بريدك الإلكتروني',
            style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text('سنرسل لك رمز تحقق لاستعادة كلمة المرور',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white38 : Colors.black45)),
        const SizedBox(height: 28),
        _emailField(isDark),
        const SizedBox(height: 24),
        _gradientButton(label: 'إرسال رمز التحقق', icon: Icons.send_rounded,
            onTap: _isLoading ? null : _handleSendOtp, isDark: isDark),
      ],
    );
  }

  // ── Step 1: OTP ─────────────────────────────────────
  Widget _otpStep(bool isDark) {
    return Column(
      children: [
        _iconCircle(Icons.verified_rounded, const Color(0xFF7C6FE0), isDark),
        const SizedBox(height: 20),
        Text('أدخل رمز التحقق',
            style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text('تم إرسال الرمز المكون من 6 أرقام إلى',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white38 : Colors.black45)),
        const SizedBox(height: 4),
        Text(_email,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 28),
        _otpBoxes(isDark),
        const SizedBox(height: 28),
        _gradientButton(
            label: 'تحقق من الرمز',
            icon: Icons.verified_outlined,
            onTap: _isLoading ? null : _handleVerifyOtp,
            isDark: isDark,
            color: const Color(0xFF7C6FE0)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('لم تستلم الرمز؟ ',
                style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38)),
            GestureDetector(
              onTap: _resendCountdown > 0 ? null : _handleResendOtp,
              child: Text(
                _resendCountdown > 0 ? 'إعادة الإرسال ($_resendCountdown)' : 'إعادة الإرسال',
                style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _resendCountdown > 0 ? (isDark ? Colors.white24 : Colors.black26) : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: New Password ─────────────────────────────
  Widget _passwordStep(bool isDark) {
    return Column(
      children: [
        _iconCircle(Icons.lock_reset_rounded, AppColors.success, isDark),
        const SizedBox(height: 20),
        Text('كلمة المرور الجديدة',
            style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text('أدخل كلمة مرور قوية لحسابك',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white38 : Colors.black45)),
        const SizedBox(height: 28),
        _passwordField(isDark, _newPasswordController, 'كلمة المرور الجديدة', _obscureNew, () {
          setState(() => _obscureNew = !_obscureNew);
        }, (v) {
          if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور';
          if (v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
          return null;
        }),
        const SizedBox(height: 14),
        _passwordField(isDark, _confirmPasswordController, 'تأكيد كلمة المرور', _obscureConfirm, () {
          setState(() => _obscureConfirm = !_obscureConfirm);
        }, (v) {
          if (v == null || v.isEmpty) return 'الرجاء تأكيد كلمة المرور';
          if (v != _newPasswordController.text) return 'كلمات المرور غير متطابقة';
          return null;
        }),
        const SizedBox(height: 28),
        _gradientButton(
            label: 'تغيير كلمة المرور',
            icon: Icons.check_circle_outline,
            onTap: _isLoading ? null : _handleResetPassword,
            isDark: isDark,
            color: AppColors.success),
      ],
    );
  }

  // ── Shared Widgets ───────────────────────────────────
  Widget _iconCircle(IconData icon, Color color, bool isDark) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Icon(icon, size: 36, color: color),
    );
  }

  Widget _emailField(bool isDark) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
      decoration: _inputDecoration(isDark, 'البريد الإلكتروني', Icons.email_outlined),
      validator: (v) {
        if (v == null || v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
        if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
        return null;
      },
    );
  }

  Widget _otpBoxes(bool isDark) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) => SizedBox(
          width: 44,
          child: TextFormField(
            controller: _otpControllers[i],
            focusNode: _otpFocusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.outfit(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < 5) {
                _otpFocusNodes[i + 1].requestFocus();
              } else if (v.isEmpty && i > 0) {
                _otpFocusNodes[i - 1].requestFocus();
              }
              if (i == 5 && v.isNotEmpty) {
                final otp = _otpControllers.map((c) => c.text).join();
                if (otp.length == 6) _handleVerifyOtp();
              }
            },
          ),
        )),
      ),
    );
  }

  Widget _passwordField(
    bool isDark,
    TextEditingController controller,
    String hint,
    bool obscure,
    VoidCallback toggle,
    String? Function(String?)? validator,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
      decoration: _inputDecoration(isDark, hint, Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: isDark ? Colors.white38 : Colors.black38,
            size: 20,
          ),
        ),
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(bool isDark, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white30 : Colors.black38),
      prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white38 : Colors.black38),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? LinearGradient(colors: [c, c.withOpacity(0.75)])
              : null,
          color: onTap == null ? (isDark ? Colors.white12 : Colors.black12) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: onTap != null
              ? [BoxShadow(color: c.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 7))]
              : null,
        ),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: GoogleFonts.tajawal(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                  const SizedBox(width: 8),
                  Icon(icon, size: 20, color: Colors.white),
                ],
              ),
      ),
    );
  }
}
