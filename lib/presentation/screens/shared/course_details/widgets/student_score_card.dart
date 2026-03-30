import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/course_models.dart';

class StudentScoreCard extends StatelessWidget {
  final StudentCourseScore studentScore;

  const StudentScoreCard({super.key, required this.studentScore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = studentScore.percentage.clamp(0.0, 100.0);

    final Color percentColor = percentage >= 80
        ? const Color(0xFF00E676)
        : percentage >= 50
            ? const Color(0xFFFFD740)
            : AppColors.primary;

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A0D10),
                    const Color(0xFF120A0D),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFFFF9F9),
                  ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.primary.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.18),
                          AppColors.primary.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ملخص أدائك في الكورس',
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Progress bar (percentage) ─────────────
              _buildProgressSection(
                  context, isDark, percentage, percentColor),

              const SizedBox(height: 14),

              // ── 3 stat chips in one row ───────────────
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      isDark: isDark,
                      icon: Icons.assignment_rounded,
                      iconColor: const Color(0xFF74B9FF),
                      value: '${studentScore.examsCount}',
                      label: 'إجمالي الاختبارات',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatChip(
                      isDark: isDark,
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF00E676),
                      value: '${studentScore.completedExamsCount}',
                      label: 'مكتملة',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatChip(
                      isDark: isDark,
                      icon: Icons.star_rounded,
                      iconColor: Colors.amber.shade400,
                      value:
                          '${studentScore.totalScore.toStringAsFixed(0)}/${studentScore.maxScore}',
                      label: 'مجموع الدرجات',
                      smallValue: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    bool isDark,
    double percentage,
    Color percentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'النسبة المئوية',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withOpacity(0.45)
                    : Colors.black38,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: percentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: percentColor.withOpacity(0.25)),
              ),
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: percentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              // Background
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                height: 8,
                width: constraints.maxWidth *
                    (percentage / 100).clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      percentColor,
                      percentColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: percentColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStatChip({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool smallValue = false,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : iconColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: smallValue ? 13 : 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.tajawal(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withOpacity(0.35)
                  : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
