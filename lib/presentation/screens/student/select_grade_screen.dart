import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:edu_platform_app/core/constants/app_colors.dart';
import 'package:edu_platform_app/presentation/screens/teacher/teacher_courses_screen.dart';

class SelectGradeScreen extends StatefulWidget {
  final int teacherId;
  final String teacherName;
  final Map<String, dynamic> teacherData;

  const SelectGradeScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.teacherData,
  });

  @override
  State<SelectGradeScreen> createState() => _SelectGradeScreenState();
}

class _SelectGradeScreenState extends State<SelectGradeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  List<Map<String, dynamic>> _stages = [];
  int? _hoveredIndex;

  // Grade icons for visual variety
  static const List<IconData> _gradeIcons = [
    Icons.menu_book_rounded,
    Icons.auto_stories_rounded,
    Icons.school_rounded,
    Icons.workspace_premium_rounded,
    Icons.military_tech_rounded,
    Icons.emoji_events_rounded,
    Icons.star_rounded,
    Icons.psychology_rounded,
  ];

  // Vibrant color palettes for each card
  static const List<List<Color>> _cardColors = [
    [Color(0xFF667EEA), Color(0xFF764BA2)], // Blue → Purple
    [Color(0xFFF093FB), Color(0xFFF5576C)], // Pink → Red
    [Color(0xFF4FACFE), Color(0xFF00F2FE)], // Blue → Cyan
    [Color(0xFF43E97B), Color(0xFF38F9D7)], // Green → Teal
    [Color(0xFFFFA726), Color(0xFFFF5252)], // Orange → Red
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)], // Purple → Pink
    [Color(0xFF13547A), Color(0xFF80D0C7)], // Deep Blue → Mint
    [Color(0xFFFF6B6B), Color(0xFFFFE66D)], // Red → Yellow
  ];

  // Arabic ordinal labels
  static const List<String> _ordinalLabels = [
    'المرحلة الأولى',
    'المرحلة الثانية',
    'المرحلة الثالثة',
    'المرحلة الرابعة',
    'المرحلة الخامسة',
    'المرحلة السادسة',
    'المرحلة السابعة',
    'المرحلة الثامنة',
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _extractStages();
  }

  void _extractStages() {
    final stagesList = widget.teacherData['teacherEducationStages'] as List?;
    if (stagesList != null) {
      _stages = List<Map<String, dynamic>>.from(stagesList);
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _onStageSelected(int stageId) {
    // Create a copy of teacherData and include the selected stage ID
    final updatedTeacherData = Map<String, dynamic>.from(widget.teacherData);
    updatedTeacherData['selectedStageId'] = stageId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherCoursesScreen(
          teacherId: widget.teacherId,
          teacherName: widget.teacherName,
          teacherData: updatedTeacherData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (isDark) _buildAnimatedBackground(),
          _buildDecorativeOrbs(size),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(child: _buildCustomAppBar()),
                // Header
                SliverToBoxAdapter(child: _buildHeader()),
                // Stages
                _getFilteredStages().isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : _buildStagesSliver(),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Teacher name chip (right side in RTL)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.primaryDark.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.45,
                  ),
                  child: Text(
                    widget.teacherName,
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Back button (left side in RTL)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredStages() {
    return _stages.where((s) => s['educationStageName'] != null).toList();
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stages = _getFilteredStages();

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large title
            Text(
              'اختر الصف',
              style: GoogleFonts.tajawal(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).textTheme.displaySmall?.color,
                height: 1.1,
              ),
            ),
            Text(
              'الدراسي',
              style: GoogleFonts.tajawal(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle with count
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'اختر المرحلة اللي عايز تشوف دوراتها',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : Colors.black.withOpacity(0.4),
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                // Count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stages.length} مراحل',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStagesSliver() {
    final stages = _getFilteredStages();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final stage = stages[index];
            return FadeInUp(
              duration: const Duration(milliseconds: 500),
              delay: Duration(milliseconds: 100 * index),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildStageCard(stage, index),
              ),
            );
          },
          childCount: stages.length,
        ),
      ),
    );
  }

  Widget _buildStageCard(Map<String, dynamic> stage, int index) {
    final stageName = stage['educationStageName'] ?? 'مرحلة غير معروفة';
    final colors = _cardColors[index % _cardColors.length];
    final icon = _gradeIcons[index % _gradeIcons.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHovered = _hoveredIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _hoveredIndex = index),
      onTapUp: (_) {
        setState(() => _hoveredIndex = null);
        _onStageSelected(stage['id']);
      },
      onTapCancel: () => setState(() => _hoveredIndex = null),
      child: AnimatedScale(
        scale: isHovered ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      colors[0].withOpacity(0.15),
                      colors[1].withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? colors[0].withOpacity(isHovered ? 0.4 : 0.2)
                  : colors[0].withOpacity(isHovered ? 0.3 : 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(isDark ? 0.12 : 0.08),
                blurRadius: isHovered ? 25 : 16,
                offset: const Offset(0, 8),
                spreadRadius: isHovered ? 2 : 0,
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative gradient blob top-left
                Positioned(
                  top: -30,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors[0].withOpacity(isDark ? 0.2 : 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Decorative gradient blob bottom-right
                Positioned(
                  bottom: -40,
                  right: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors[1].withOpacity(isDark ? 0.1 : 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Watermark icon
                Positioned(
                  bottom: -8,
                  left: -8,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Icon(
                      icon,
                      size: 70,
                      color: colors[0].withOpacity(isDark ? 0.06 : 0.04),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Icon container with gradient
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colors[0], colors[1]],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: colors[0].withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      // Text content
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stageName,
                              style: GoogleFonts.tajawal(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors[0].withOpacity(isDark ? 0.15 : 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'عرض الدورات المتاحة',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors[0].withOpacity(isDark ? 0.8 : 1.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : colors[0].withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: isDark
                              ? Colors.white.withOpacity(0.4)
                              : colors[0].withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primaryDark.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 40,
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد مراحل دراسية',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'هذا المعلم لم يضف مراحل دراسية بعد',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black26,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF0A0A0A),
                Color(0xFF1A0A0A),
                Color(0xFF0A0A0A),
              ],
              stops: [
                0.0,
                0.5 + 0.1 * math.sin(_backgroundController.value * 2 * math.pi),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorativeOrbs(Size size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.08,
          right: -size.width * 0.15,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  15 * math.sin(_backgroundController.value * 2 * math.pi),
                  15 * math.cos(_backgroundController.value * 2 * math.pi),
                ),
                child: Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(isDark ? 0.2 : 0.08),
                        AppColors.primaryDark.withOpacity(isDark ? 0.05 : 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -size.height * 0.12,
          left: -size.width * 0.2,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -20 * math.sin(_backgroundController.value * 2 * math.pi),
                  20 * math.cos(_backgroundController.value * 2 * math.pi),
                ),
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryDark.withOpacity(isDark ? 0.15 : 0.06),
                        AppColors.primary.withOpacity(isDark ? 0.04 : 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
