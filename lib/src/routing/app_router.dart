import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import repositories
import '../features/authentication/data/auth_repository.dart';
import '../features/profile/data/profile_repository.dart';

// Import screens
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/verification_status_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/home/presentation/main_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/announcement_detail_screen.dart';
import '../features/home/domain/announcement_model.dart';
import '../features/attendance/presentation/attendance_history_screen.dart';
import '../features/journal/presentation/daily_journal_screen.dart';
import '../features/journal/presentation/journal_form_screen.dart';
import '../features/teacher/presentation/teacher_dashboard_screen.dart';
import '../features/authentication/presentation/splash_screen.dart';

// Navigator Keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authStream = authRepository.authStateChanges;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authStream),

    // 🔥 REDIRECT LOGIN
    redirect: (context, state) {
      final currentUser = ref.read(authRepositoryProvider).currentUser;
      final isLoggedIn = currentUser != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSplash = state.uri.toString() == '/splash';

      if (!isLoggedIn) {
        return (isLoggingIn || isSplash) ? null : '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },

    routes: [
      // SPLASH
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // LOGIN
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ADMIN ROUTE (optional)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // 🔥 MAIN APP (SHELL)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ProfileGuard(navigationShell: navigationShell);
        },
        branches: [
          // HOME
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
                      final announcement =
                          state.extra as AnnouncementModel;
                      return AnnouncementDetailScreen(
                        announcement: announcement,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // HISTORY
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) =>
                    const AttendanceHistoryScreen(),
              ),
            ],
          ),

          // JOURNAL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (context, state) =>
                    const DailyJournalScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const JournalFormScreen(),
                  ),
                ],
              ),
            ],
          ),

          // PROFILE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// 🔁 REFRESH STREAM
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
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

// 🔥 PROFILE GUARD (FIX UTAMA ADA DI SINI)
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
            body: Center(child: Text("Profil tidak ditemukan")),
          );
        }

        final role = profile['role'] ?? 'student';
        final status = profile['status'] ?? 'pending';

        // 🔥 DEBUG (lihat di console)
        debugPrint("ROLE: $role");
        debugPrint("STATUS: $status");

        // 🔴 ADMIN
        if (role == 'admin') {
          return const AdminDashboardScreen();
        }

        // 🟡 TEACHER
        if (role == 'teacher') {
          return const TeacherDashboardScreen();
        }

        // ⚠️ BELUM AKTIF
        if (status != 'active') {
          return VerificationStatusScreen(status: status);
        }

        // 🟢 SISWA (DEFAULT)
        return MainScreen(navigationShell: navigationShell);
      },

      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}