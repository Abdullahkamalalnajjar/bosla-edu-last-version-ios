import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edu_platform_app/core/constants/app_colors.dart';
import 'package:edu_platform_app/data/models/notification_models.dart';
import 'package:edu_platform_app/data/services/user_notification_service.dart';
import 'package:edu_platform_app/data/services/notification_service.dart';
import 'package:edu_platform_app/data/services/notification_cache_service.dart';
import 'package:edu_platform_app/data/services/token_service.dart';
import 'package:edu_platform_app/data/services/course_service.dart';
import 'package:edu_platform_app/data/models/course_models.dart';
import 'package:edu_platform_app/presentation/screens/teacher/teacher_subscriptions_screen.dart';
import 'package:edu_platform_app/presentation/screens/student/my_courses_page.dart';
import 'package:edu_platform_app/presentation/screens/shared/course_details/course_details_screen.dart';
import 'package:edu_platform_app/presentation/screens/student/student_exam_screen.dart';
import 'package:edu_platform_app/presentation/screens/teacher/exam_submissions_screen.dart';
import 'package:edu_platform_app/core/network/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = UserNotificationService();
  final _tokenService = TokenService();
  bool _isLoading = true;
  String? _error;
  List<NotificationItem> _notifications = [];
  // Inline search state (replaces floating overlay)
  bool _isSearching = false;
  int _searchStep = 0;
  String _searchMessage = '';
  String _searchType = 'exam'; // 'exam', 'lecture', 'content'
  // Search/filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _notificationService.getUserNotifications();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (response.succeeded && response.data != null) {
        _notifications = response.data!;
        // Sort by date descending (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        _error = response.message;
      }
    });
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.isRead) return;

    // Optimistic update
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          timestamp: notification.timestamp,
          isRead: true,
          type: notification.type,
          courseId: notification.courseId,
          examId: notification.examId,
          lectureId: notification.lectureId,
          status: notification.status,
          teacherId: notification.teacherId,
          lectureName: notification.lectureName,
          courseName: notification.courseName,
        );
      }
    });

    // Call API (silent fail handling mostly, or revert if needed)
    await _notificationService.markAsRead(notification.id);
  }

  Future<void> _deleteNotification(NotificationItem notification) async {
    // Optimistic update: remove from list immediately
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    final response = await _notificationService.deleteNotification(
      notification.id,
    );

    if (!response.succeeded) {
      if (mounted) {
        // Revert on failure (fetch again or add back)
        _fetchNotifications();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    // Optimistic update — mark all as read in UI immediately
    setState(() {
      _notifications = _notifications.map((n) => n.isRead
          ? n
          : NotificationItem(
              id: n.id,
              title: n.title,
              body: n.body,
              timestamp: n.timestamp,
              isRead: true,
              type: n.type,
              courseId: n.courseId,
              examId: n.examId,
              lectureId: n.lectureId,
              status: n.status,
              teacherId: n.teacherId,
              lectureName: n.lectureName,
              courseName: n.courseName,
            )).toList();
    });

    // Call markAsRead for each unread notification individually
    for (final notification in unread) {
      await _notificationService.markAsRead(notification.id);
    }
  }

  /// Show inline loading while searching for the notification target
  Future<bool> _navigateWithLoadingDialog(String title, String body) async {
    final nav = navigatorKey.currentState;
    if (nav == null || !mounted) return false;

    // Determine search type from notification text
    final combined = '$title $body';
    String searchType = 'content';
    if (_isExamRelatedText(title, body)) {
      searchType = 'exam';
    } else if (combined.contains('محاضرة') || combined.contains('درس')) {
      searchType = 'lecture';
    }

    // Show inline loading
    setState(() {
      _isSearching = true;
      _searchStep = 0;
      _searchMessage = 'جاري تحديد الإشعار...';
      _searchType = searchType;
    });

    void updateProgress(int step, String message) {
      if (mounted) {
        setState(() {
          _searchStep = step;
          _searchMessage = message;
        });
      }
    }

    void stopSearching() {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }

    try {
      final role = await _tokenService.getRole();
      final roleLower = role?.toLowerCase();
      final isTeacher = roleLower == 'teacher' || roleLower == 'assistant';

      if (isTeacher) {
        // Quick check: subscription notifications don't need search
        if (title.contains('طالب جديد') ||
            title.contains('مشترك') ||
            body.contains('اشترك في')) {
          stopSearching();
          nav.push(MaterialPageRoute(
            builder: (_) => const TeacherSubscriptionsScreen(),
          ));
          return true;
        }

        // Search teacher's own courses
        updateProgress(1, 'جاري البحث في كورساتك...');
        final teacherId = await _tokenService.getTeacherId();
        print('👨‍🏫 Teacher ID: $teacherId');
        if (teacherId == null) {
          print('👨‍🏫 teacherId is null, falling back');
          stopSearching();
          return _inferNavigationFromText(title, body);
        }

        final courseService = CourseService();
        final coursesResponse = await courseService.getCoursesByTeacher(teacherId);
        print('👨‍🏫 Courses response: succeeded=${coursesResponse.succeeded}, count=${coursesResponse.data?.length}');
        
        final isExamNotif = _isExamRelatedText(title, body);
        print('👨‍🏫 isExamRelated: $isExamNotif');
        
        if (coursesResponse.succeeded && coursesResponse.data != null) {
          final courses = coursesResponse.data!;
          
          // Search all courses for matching exam or lecture
          updateProgress(2, isExamNotif ? 'جاري البحث عن الامتحان...' : 'جاري البحث عن المحاضرة...');
          for (final courseMap in courses) {
            final courseId = courseMap['id'];
            if (courseId == null) continue;
            final fullCourse = await courseService.getCourseById(courseId);
            if (!fullCourse.succeeded || fullCourse.data == null) continue;
            final course = fullCourse.data!;

            // For exam notifications → find exam → ExamSubmissionsScreen
            if (isExamNotif) {
              final examResult = await _searchExamsInCourse(
                courseService, course, title, body,
                isTeacher: true,
              );
              if (examResult != null) {
                final exam = examResult['exam'] as Exam;
                final lectureTitle = examResult['lectureTitle'] as String? ?? 'الاختبار';
                print('👨‍🏫 ✅ Found exam: ${exam.title} in ${course.title}');
                updateProgress(3, 'جاري فتح التسليمات...');
                stopSearching();
                nav.push(MaterialPageRoute(
                  builder: (_) => ExamSubmissionsScreen(
                    lectureId: exam.lectureId,
                    examId: exam.id,
                    lectureTitle: lectureTitle,
                    courseId: course.id,
                  ),
                ));
                return true;
              }
            }

            // For lecture/content notifications → find lecture → CourseDetailsScreen
            if (!isExamNotif) {
              final matchedLectureId = _findMatchingLectureId(course, title, body);
              if (matchedLectureId != null) {
                print('👨‍🏫 ✅ Found lecture in: ${course.title} (lectureId=$matchedLectureId)');
                updateProgress(3, 'جاري فتح الكورس...');
                stopSearching();
                nav.push(MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(
                    course: course,
                    initialLectureId: matchedLectureId,
                  ),
                ));
                return true;
              }
            }
          }
        }

        // Fallback for teachers
        print('👨‍🏫 ❌ No match found, falling back');
        stopSearching();
        return _inferNavigationFromText(title, body);
      }

      // For students — search for course & exam
      updateProgress(1, 'جاري البحث عن الكورس...');
      final result = await _findExamOrCourseFromNotification(
        title, body,
        onProgress: updateProgress,
      );
      print('🔍 Search result: exam=${result?['exam'] != null}, course=${result?['course'] != null}, matchedLectureId=${result?['matchedLectureId']}');

      // Stop searching, THEN navigate
      stopSearching();

      if (result != null) {
        if (result['exam'] != null) {
          final exam = result['exam'] as Exam;
          final lectureTitle = result['lectureTitle'] as String? ?? 'الاختبار';
          print('🧠 Found matching exam: ${exam.title} (id=${exam.id}) → StudentExamScreen');
          nav.push(MaterialPageRoute(
            builder: (_) => StudentExamScreen(
              lectureId: exam.lectureId,
              examId: exam.id,
              lectureTitle: lectureTitle,
            ),
          ));
          return true;
        } else if (result['course'] != null) {
          final course = result['course'] as Course;
          // If notification was about an exam but we only found the course
          if (_isExamRelatedText(title, body)) {
            print('🧠 Exam not found but course exists → showing not found message');
            _showExamNotFoundMessage();
            return true;
          }
          final matchedLectureId = result['matchedLectureId'] as int?;
          print('🧠 Found matching course: ${course.title} (lectureId=$matchedLectureId) → CourseDetailsScreen');
          nav.push(MaterialPageRoute(
            builder: (_) => CourseDetailsScreen(
              course: course,
              initialLectureId: matchedLectureId,
            ),
          ));
          return true;
        }
      }

      // If notification was about an exam but nothing was found
      if (_isExamRelatedText(title, body)) {
        print('🧠 Exam notification but nothing found → showing not found message');
        _showExamNotFoundMessage();
        return true;
      }

      // Fallback: go to MyCoursesPage
      print('🧠 No course match, falling back to MyCoursesPage');
      nav.push(MaterialPageRoute(
        builder: (_) => const MyCoursesPage(initialTabIndex: 0),
      ));
      return true;
    } catch (e) {
      stopSearching();
      print('❌ Error in _navigateWithLoadingDialog: $e');
      return false;
    }
  }

  /// Infer navigation from notification title/body text.
  /// Since the backend only returns [id, title, body, timestamp, isRead],
  /// we analyze the text to determine which screen to navigate to.
  /// Returns true if navigation was handled, false if not.
  Future<bool> _inferNavigationFromText(String title, String body, {
    void Function(int step, String message)? onProgress,
  }) async {
    final combined = '$title $body';
    final role = await _tokenService.getRole();
    final roleLower = role?.toLowerCase();
    final isTeacher = roleLower == 'teacher' || roleLower == 'assistant';
    final nav = navigatorKey.currentState;
    if (nav == null) return false;

    // --- Subscription-related (Teacher sees these) ---

    // "طالب جديد مشترك" / "اشترك في كورس" → TeacherSubscriptionsScreen
    if (title.contains('طالب جديد') ||
        title.contains('مشترك') ||
        body.contains('اشترك في')) {
      print('🧠 Inferred: new subscription → TeacherSubscriptionsScreen');
      nav.push(MaterialPageRoute(
        builder: (_) => const TeacherSubscriptionsScreen(),
      ));
      return true;
    }

    // --- Subscription-related (Student sees these) ---

    // "تم إضافتك" / "تم اشتراكك" → MyCoursesPage Approved tab
    if (combined.contains('تم إضافتك') ||
        combined.contains('تم اشتراكك') ||
        combined.contains('إضافتك إلى')) {
      print('🧠 Inferred: added by teacher → MyCoursesPage');
      nav.push(MaterialPageRoute(
        builder: (_) => const MyCoursesPage(initialTabIndex: 0),
      ));
      return true;
    }

    // "تمت الموافقة" / "تم قبول" → MyCoursesPage Approved tab
    if (combined.contains('تمت الموافقة') ||
        combined.contains('تم قبول') ||
        combined.contains('موافقة على')) {
      print('🧠 Inferred: subscription approved → MyCoursesPage');
      nav.push(MaterialPageRoute(
        builder: (_) => const MyCoursesPage(initialTabIndex: 0),
      ));
      return true;
    }

    // "تم رفض" → MyCoursesPage Rejected tab
    if (combined.contains('تم رفض') || combined.contains('رفض اشتراك')) {
      print('🧠 Inferred: subscription rejected → MyCoursesPage');
      nav.push(MaterialPageRoute(
        builder: (_) => const MyCoursesPage(initialTabIndex: 2),
      ));
      return true;
    }

    // --- For Students: try to find the specific course and exam ---
    if (!isTeacher) {
      onProgress?.call(1, 'جاري البحث عن الكورس...');
      final result = await _findExamOrCourseFromNotification(title, body, onProgress: onProgress);
      if (result != null) {
        if (result['exam'] != null) {
          // Found the specific exam → go directly to StudentExamScreen
          final exam = result['exam'] as Exam;
          final lectureTitle = result['lectureTitle'] as String? ?? 'الاختبار';
          onProgress?.call(3, 'جاري فتح الاختبار...');
          print('🧠 Found matching exam: ${exam.title} (id=${exam.id}) → StudentExamScreen');
          nav.push(MaterialPageRoute(
            builder: (_) => StudentExamScreen(
              lectureId: exam.lectureId,
              examId: exam.id,
              lectureTitle: lectureTitle,
            ),
          ));
          return true;
        } else if (result['course'] != null) {
          // Found the course but not a specific exam → go to CourseDetailsScreen
          final course = result['course'] as Course;
          onProgress?.call(3, 'جاري فتح الكورس...');
          print('🧠 Found matching course: ${course.title} → CourseDetailsScreen');
          nav.push(MaterialPageRoute(
            builder: (_) => CourseDetailsScreen(course: course),
          ));
          return true;
        }
      }

      // Fallback: go to MyCoursesPage
      print('🧠 No course match, falling back to MyCoursesPage');
      nav.push(MaterialPageRoute(
        builder: (_) => const MyCoursesPage(initialTabIndex: 0),
      ));
      return true;
    }

    // --- No useful navigation possible ---
    print('🧠 Cannot determine navigation target for: $title');
    return false;
  }

  /// Try to find a course and optionally a specific exam from notification text.
  /// Returns a map with 'course' and optionally 'exam' and 'lectureTitle'.
  Future<Map<String, dynamic>?> _findExamOrCourseFromNotification(
      String title, String body, {
      void Function(int step, String message)? onProgress,
  }) async {
    try {
      final courseService = CourseService();
      final response = await courseService.getSubscriptionsByStatus('Approved');
      if (!response.succeeded || response.data == null) return null;

      final combined = '$title $body';
      final isExamRelated = combined.contains('اختبار') ||
          combined.contains('امتحان') ||
          combined.contains('واجب') ||
          combined.contains('تصحيح') ||
          combined.contains('درجة') ||
          combined.contains('نتيجة');

      final subscriptions = response.data!;
      // Helper: normalize whitespace
      String normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
      final normalizedBody = normalize(body);
      final normalizedTitle = normalize(title);

      // === PASS 1: Try matching course name in notification body or title ===
      for (final sub in subscriptions) {
        if (sub.courseName.isEmpty) continue;
        final normalizedCourseName = normalize(sub.courseName);
        if (normalizedBody.contains(normalizedCourseName) ||
            normalizedTitle.contains(normalizedCourseName)) {
          onProgress?.call(1, 'تم العثور على: ${sub.courseName}');
          final courseResponse =
              await courseService.getCourseById(sub.courseId);
          if (!courseResponse.succeeded || courseResponse.data == null) continue;
          final course = courseResponse.data!;

          if (!isExamRelated) {
            // Try to find a matching lecture by title
            final matchedLectureId = _findMatchingLectureId(course, title, body);
            return {'course': course, 'matchedLectureId': matchedLectureId};
          }

          onProgress?.call(2, 'جاري البحث عن الامتحان...');
          final examResult = await _searchExamsInCourse(
            courseService, course, title, body,
          );
          if (examResult != null) return examResult;

          // Course found but no specific exam match
          final matchedLectureId = _findMatchingLectureId(course, title, body);
          return {'course': course, 'matchedLectureId': matchedLectureId};
        }
      }

      // === PASS 2: Course name NOT found — search ALL courses ===
      onProgress?.call(2, 'جاري البحث في جميع الكورسات...');
      for (final sub in subscriptions) {
        final courseResponse =
            await courseService.getCourseById(sub.courseId);
        if (!courseResponse.succeeded || courseResponse.data == null) continue;
        final course = courseResponse.data!;

        // Search for exam if exam-related
        if (isExamRelated) {
          final examResult = await _searchExamsInCourse(
            courseService, course, title, body,
          );
          if (examResult != null) {
            onProgress?.call(2, 'تم العثور على الامتحان في: ${sub.courseName}');
            return examResult;
          }
        }

        // Search for lecture match
        final matchedLectureId = _findMatchingLectureId(course, title, body);
        if (matchedLectureId != null) {
          onProgress?.call(2, 'تم العثور على المحاضرة في: ${sub.courseName}');
          return {'course': course, 'matchedLectureId': matchedLectureId};
        }
      }

      return null;
    } catch (e) {
      print('❌ Error finding exam/course from notification: $e');
      return null;
    }
  }

  /// Search for a matching exam inside a course's lectures (parallel).
  Future<Map<String, dynamic>?> _searchExamsInCourse(
    CourseService courseService,
    Course course,
    String title,
    String body, {
    bool isTeacher = false,
  }) async {
    // Fetch all lecture exams IN PARALLEL
    final examFutures = course.lectures.map((lecture) async {
      final examsResponse =
          await courseService.getExamByLectureId(lecture.id);
      return {
        'lecture': lecture,
        'exams': (examsResponse.succeeded && examsResponse.data != null)
            ? examsResponse.data!
            : <Exam>[],
      };
    }).toList();

    final results = await Future.wait(examFutures);

    // Helper: normalize whitespace
    String normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedBody = normalize(body);
    final normalizedTitle = normalize(title);

    // Extract exam name from quotes if available
    String? extractedName;
    final quoteMatch = RegExp(r"'([^']+)'").firstMatch(body);
    if (quoteMatch != null) {
      extractedName = normalize(quoteMatch.group(1)!);
    }

    // Search for the BEST matching exam (longest title match wins)
    Exam? bestExam;
    String? bestLectureTitle;
    int bestMatchLength = 0;

    for (final result in results) {
      final lecture = result['lecture'] as Lecture;
      final exams = result['exams'] as List<Exam>;
      for (final exam in exams) {
        if (exam.title.length < 3) continue;
        // Teachers can see all exams, students only visible ones
        if (!isTeacher && !exam.isVisible) continue;
        
        final normalizedExamTitle = normalize(exam.title);
        
        // Match: body contains exam title, title contains exam title,
        // or extracted name matches exam title
        final matched = normalizedBody.contains(normalizedExamTitle) ||
            normalizedTitle.contains(normalizedExamTitle) ||
            (extractedName != null && (
              normalizedExamTitle.contains(extractedName) ||
              extractedName.contains(normalizedExamTitle)
            ));
        
        if (matched && normalizedExamTitle.length > bestMatchLength) {
          bestExam = exam;
          bestLectureTitle = lecture.title;
          bestMatchLength = normalizedExamTitle.length;
        }
      }
    }

    if (bestExam != null) {
      return {
        'course': course,
        'exam': bestExam,
        'lectureTitle': bestLectureTitle,
      };
    }
    return null;
  }

  /// Find a lecture that matches the notification text by title.
  /// Falls back to the latest lecture if the notification is lecture-related.
  int? _findMatchingLectureId(Course course, String title, String body) {
    final combined = '$title $body';
    print('📂 _findMatchingLectureId: body="$body"');
    print('📂 Available lectures: ${course.lectures.map((l) => '${l.id}:"${l.title}"(vis=${l.isVisible},idx=${l.index})').join(', ')}');

    // Helper: normalize whitespace (collapse multiple spaces, trim)
    String normalize(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Step 1: Try to extract lecture name from between quotes in body
    // Pattern: المحاضرة 'LECTURE_NAME' متاحة الآن
    final quoteMatch = RegExp(r"'([^']+)'").firstMatch(body);
    if (quoteMatch != null) {
      final extractedName = normalize(quoteMatch.group(1)!);
      print('📂 Extracted name from quotes: "$extractedName"');
      for (final lecture in course.lectures) {
        if (!lecture.isVisible) continue;
        final normalizedTitle = normalize(lecture.title);
        // Check if extracted name contains the lecture title or vice versa
        if (normalizedTitle == extractedName ||
            extractedName.contains(normalizedTitle) ||
            normalizedTitle.contains(extractedName)) {
          print('📂 ✅ Matched by quote extraction: ${lecture.title} (id=${lecture.id})');
          return lecture.id;
        }
      }
    }

    // Step 2: Fuzzy title match with normalized whitespace
    final normalizedBody = normalize(body);
    final normalizedTitle = normalize(title);
    int? bestId;
    int bestLength = 0;
    for (final lecture in course.lectures) {
      if (lecture.title.length < 3) continue;
      if (!lecture.isVisible) continue;
      final normLectureTitle = normalize(lecture.title);
      if (normalizedBody.contains(normLectureTitle) ||
          normalizedTitle.contains(normLectureTitle)) {
        if (normLectureTitle.length > bestLength) {
          bestId = lecture.id;
          bestLength = normLectureTitle.length;
        }
      }
    }
    if (bestId != null) {
      print('📂 ✅ Matched by normalized title: id=$bestId');
      return bestId;
    }

    // Step 3: If notification is about a lecture, pick the LAST visible lecture
    final isLectureRelated = combined.contains('محاضرة') ||
        combined.contains('درس') ||
        combined.contains('مادة') ||
        combined.contains('متاح');
    if (isLectureRelated) {
      final visibleLectures = course.lectures
          .where((l) => l.isVisible)
          .toList();
      if (visibleLectures.isNotEmpty) {
        visibleLectures.sort((a, b) => b.index.compareTo(a.index));
        final lastLecture = visibleLectures.first;
        print('📂 ✅ Fallback to last lecture: ${lastLecture.title} (id=${lastLecture.id})');
        return lastLecture.id;
      }
    }

    print('📂 ❌ No lecture match found');
    return null;
  }

  String _formatDate(DateTime date) {
    // Check if today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return DateFormat('h:mm a', 'ar').format(date);
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    } else {
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    }
  }

  /// Check if notification text is related to exams
  bool _isExamRelatedText(String title, String body) {
    final combined = '$title $body';
    return combined.contains('اختبار') ||
        combined.contains('امتحان') ||
        combined.contains('واجب') ||
        combined.contains('تصحيح') ||
        combined.contains('درجة') ||
        combined.contains('نتيجة');
  }

  /// Show a "exam not found" message to the student
  void _showExamNotFoundMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'الاختبار غير موجود، قد يكون تم حذفه من المعلم',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Build the step indicators for inline search
  List<Widget> _buildSearchSteps(bool isDark) {
    final searchTarget = _searchType == 'exam'
        ? 'الامتحان'
        : _searchType == 'lecture'
            ? 'المحاضرة'
            : 'المحتوى';
    final stepLabels = [
      'البحث في الكورسات',
      'تحديد الكورس',
      'البحث عن $searchTarget',
      'فتح الصفحة',
    ];
    return List.generate(stepLabels.length, (i) {
      final isCompleted = _searchStep > i;
      final isActive = _searchStep == i;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : isActive
                        ? AppColors.primary
                        : isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.grey.shade200,
                border: isActive
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 3)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : isActive
                      ? const Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : null,
            ),
            const SizedBox(width: 12),
            Text(
              stepLabels[i],
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted
                    ? AppColors.success
                    : isActive
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white38 : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0A0C) : const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // ── Premium Header ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A0D10) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.primary.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 17,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + badge
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'الإشعارات',
                            style: GoogleFonts.tajawal(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Menu
                    if (_notifications.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'read_all') {
                            _markAllAsRead();
                          } else if (value == 'delete_all') {
                            _deleteAllNotifications();
                          }
                        },
                        itemBuilder: (context) => [
                          if (_notifications.any((n) => !n.isRead))
                            PopupMenuItem(
                              value: 'read_all',
                              child: Row(children: [
                                const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text('تحديد الكل كمقروء', style: GoogleFonts.tajawal(fontSize: 14)),
                              ]),
                            ),
                          PopupMenuItem(
                            value: 'delete_all',
                            child: Row(children: [
                              const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              const SizedBox(width: 10),
                              Text('حذف جميع الإشعارات',
                                  style: GoogleFonts.tajawal(fontSize: 14, color: AppColors.error)),
                            ]),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(0.1),
                      border: Border.all(color: AppColors.error.withOpacity(0.2), width: 1.5),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text('حذف الإشعارات',
                      style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Text('هل أنت متأكد من حذف جميع الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 13, height: 1.6,
                          color: isDark ? Colors.white38 : Colors.black45)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: Text('نعم، احذف الكل',
                          style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text('إلغاء',
                          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white60 : Colors.black54))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final response = await _notificationService.deleteAll();

    if (response.succeeded) {
      _fetchNotifications();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
      }
    }
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show inline search progress
    if (_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, child) => Transform.scale(scale: value, child: child),
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 32),
              ..._buildSearchSteps(isDark),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_searchMessage, key: ValueKey(_searchMessage),
                    style: GoogleFonts.outfit(fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.grey.shade600),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (_searchStep + 1) / 4),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                style: GoogleFonts.outfit(color: isDark ? Colors.white60 : Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchNotifications,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('إعادة المحاولة',
                    style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.primary.withOpacity(0.12),
                ),
              ),
              child: Icon(Icons.notifications_none_rounded,
                  color: isDark ? Colors.white24 : Colors.black26, size: 40),
            ),
            const SizedBox(height: 20),
            Text('لا توجد إشعارات',
                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('ستظهر جميع إشعاراتك وتنبيهاتك هنا',
                style: GoogleFonts.outfit(fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38)),
          ],
        ),
      );
    }

    // Filter by search
    final filteredNotifications = _searchQuery.isEmpty
        ? _notifications
        : _notifications.where((n) {
            final q = _searchQuery.toLowerCase();
            return n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q);
          }).toList();

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: AppColors.primary,
      child: Column(
        children: [
          // ── Search bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'ابحث في الإشعارات...',
                hintStyle: GoogleFonts.outfit(fontSize: 14,
                    color: isDark ? Colors.white30 : Colors.black38),
                prefixIcon: Icon(Icons.search_rounded, size: 20,
                    color: isDark ? Colors.white30 : Colors.black38),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18,
                            color: isDark ? Colors.white54 : Colors.black38),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${filteredNotifications.length} نتيجة',
                    style: GoogleFonts.outfit(fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38)),
              ),
            ),

          // ── List ─────────────────────────────────────────
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off_rounded, size: 48,
                        color: isDark ? Colors.white24 : Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('لا توجد نتائج',
                        style: GoogleFonts.tajawal(fontSize: 16,
                            color: isDark ? Colors.white38 : Colors.grey.shade500)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      final isUnread = !notification.isRead;

                      return Dismissible(
                        key: Key('notification_${notification.id}'),
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (_) => _deleteNotification(notification),
                        child: GestureDetector(
                          onTap: () async {
                            _markAsRead(notification);
                            print('════════════════════════════════════════');
                            print('🔔 Notification tapped:');
                            print('   title: ${notification.title}');
                            print('   body: ${notification.body}');
                            print('   type: ${notification.type}');
                            print('   examId: ${notification.examId}');
                            print('   lectureId: ${notification.lectureId}');
                            print('   courseId: ${notification.courseId}');
                            print('   hasNavData: ${notification.hasNavigationData}');
                            print('════════════════════════════════════════');
                            if (notification.hasNavigationData) {
                              final navData = notification.toNavigationData();
                              print('✅ Using API navigation data: $navData');
                              NotificationService.handleNotificationData(navData);
                              return;
                            }
                            final cachedData = await NotificationCacheService.findCachedData(
                              notification.title, notification.body,
                            );
                            if (cachedData != null) {
                              print('📦 Found cached data for notification: $cachedData');
                              NotificationService.handleNotificationData(cachedData);
                              return;
                            }
                            final navigated = await _navigateWithLoadingDialog(
                              notification.title, notification.body,
                            );
                            if (navigated) return;
                            print('⚠️ No navigation data found for: ${notification.title}');
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تم قراءة الإشعار',
                                    style: GoogleFonts.outfit(color: Colors.white)),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ));
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isUnread ? const Color(0xFF1E1215) : const Color(0xFF150D0F))
                                  : (isUnread ? Colors.white : const Color(0xFFFAFAFA)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isUnread
                                    ? AppColors.primary.withOpacity(0.25)
                                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.07)),
                              ),
                              boxShadow: isUnread
                                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Left accent bar for unread
                                if (isUnread)
                                  Container(
                                    width: 4,
                                    height: 72,
                                    margin: const EdgeInsets.only(left: 0),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(18),
                                        bottomRight: Radius.circular(18),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      isUnread ? 12 : 16, 14, 16, 14,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Icon
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isUnread
                                                ? AppColors.primary.withOpacity(0.12)
                                                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                            border: isUnread
                                                ? Border.all(color: AppColors.primary.withOpacity(0.2))
                                                : null,
                                          ),
                                          child: Icon(
                                            isUnread
                                                ? Icons.notifications_active_rounded
                                                : Icons.notifications_none_rounded,
                                            color: isUnread
                                                ? AppColors.primary
                                                : (isDark ? Colors.white38 : Colors.black38),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      notification.title,
                                                      style: GoogleFonts.tajawal(
                                                        fontSize: 14,
                                                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                                        color: isDark ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Colors.white.withOpacity(0.06)
                                                          : Colors.black.withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      _formatDate(notification.timestamp),
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w500,
                                                        color: isDark ? Colors.white38 : Colors.black38,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                notification.body,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  height: 1.5,
                                                  color: isUnread
                                                      ? (isDark ? Colors.white60 : Colors.black54)
                                                      : (isDark ? Colors.white38 : Colors.black38),
                                                ),
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
