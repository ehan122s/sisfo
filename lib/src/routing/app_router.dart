import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/verification_status_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/home/presentation/main_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/announcement_detail_screen.dart';
import '../features/home/domain/announcement_model.dart'; // Needed for route extra
import '../features/attendance/presentation/attendance_history_screen.dart';
import '../features/journal/presentation/daily_journal_screen.dart';
import '../features/journal/presentation/journal_form_screen.dart';
import '../features/teacher/presentation/teacher_dashboard_screen.dart';
import '../features/teacher/presentation/teacher_attendance_monitor_screen.dart';
import '../features/teacher/presentation/teacher_journal_approval_screen.dart';
import '../features/teacher/presentation/teacher_student_list_screen.dart';
import '../features/teacher/presentation/teacher_student_detail_screen.dart';
import '../features/teacher/presentation/notifications/notification_screen.dart';

import '../features/authentication/presentation/splash_screen.dart'; // Import Splash

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  // We listen to the stream for refreshing
  final authRepository = ref.watch(authRepositoryProvider);
  final authStream = authRepository.authStateChanges;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      // Read directly from repository to avoid StreamProvider race conditions
      final currentUser = ref.read(authRepositoryProvider).currentUser;
      final isLoggedIn = currentUser != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSplash = state.uri.toString() == '/splash';

      debugPrint("GoRouter Redirect: Path=${state.uri}, LoggedIn=$isLoggedIn");

      if (!isLoggedIn) {
        // Allow login and splash screens
        return (isLoggingIn || isSplash) ? null : '/login';
      }

      // If logged in, check web vs mobile and profile status
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) {
          final status = state.extra as String? ?? 'pending';
          return VerificationStatusScreen(status: status);
        },
      ),
      GoRoute(
        path: '/teacher/dashboard',
        builder: (context, state) => const TeacherDashboardScreen(),
        routes: [
          GoRoute(
            path: 'attendance',
            builder: (context, state) => const TeacherAttendanceMonitorScreen(),
          ),
          GoRoute(
            path: 'journals',
            builder: (context, state) => const TeacherJournalApprovalScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: 'students',
            builder: (context, state) => const TeacherStudentListScreen(),
            routes: [
              GoRoute(
                path: ':studentId',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId']!;
                  final studentData = state.extra as Map<String, dynamic>;
                  return TeacherStudentDetailScreen(
                    studentId: studentId,
                    studentData: studentData,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      // Mobile App Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Guard: Check Profile Status Here
          // We return a "Guard" widget that checks profile status
          // If active -> render MainScreen (with navigationShell)
          // If web -> redirect to admin (handled in redirect? No, redirect checks path)
          // We can do a check here.

          if (kIsWeb) {
            return const AdminDashboardScreen();
          }

          return _ProfileGuard(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'announcements/detail',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final announcement = state.extra as AnnouncementModel;
                      return AnnouncementDetailScreen(
                        announcement: announcement,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const AttendanceHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (context, state) => const DailyJournalScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey, // Full screen
                    builder: (context, state) => const JournalFormScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// Helper class to convert Stream to Listenable for GoRouter
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Internal Widget to check Profile Status before showing Shell
class _ProfileGuard extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _ProfileGuard({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text("Profil tidak ditemukan.")),
          );
        }
        final status = profile['status'] ?? 'pending';
        final role = profile['role'] ?? 'student';

        if (role == 'teacher') {
          Future.microtask(() {
            if (context.mounted) context.go('/teacher/dashboard');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (status != 'active') {
          // Show Verification Screen instead of Shell
          return VerificationStatusScreen(status: status);
        }

        return MainScreen(navigationShell: navigationShell);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
