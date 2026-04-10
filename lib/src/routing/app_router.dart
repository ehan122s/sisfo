import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/splash_screen.dart';

import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/teacher/presentation/teacher_dashboard_screen.dart';

import '../features/profile/presentation/profile_screen.dart';

import '../features/home/presentation/main_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/announcement_detail_screen.dart';
import '../features/home/domain/announcement_model.dart'; 

import '../features/attendance/presentation/attendance_history_screen.dart';

import '../features/journal/presentation/daily_journal_screen.dart';
import '../features/journal/presentation/journal_form_screen.dart';

final supabase = Supabase.instance.client;

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final authStream = authRepository.authStateChanges;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authStream),

    redirect: (context, state) {
      final currentUser = authRepository.currentUser;
      final isLoggedIn = currentUser != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSplash = state.uri.toString() == '/splash';

      if (isSplash) return null;

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },

    routes: [
      /// SPLASH
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      /// LOGIN
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      /// 🔒 ADMIN ROUTE (PROTECTED)
      GoRoute(
        path: '/admin',
        builder: (context, state) {
          return FutureBuilder(
            future: supabase
                .from('profiles')
                .select('role')
                .eq('id', supabase.auth.currentUser!.id)
                .single(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = snapshot.data!['role'];

              if (role != 'admin') {
                return const Scaffold(
                  body: Center(child: Text("Unauthorized")),
                );
              }

              return const AdminDashboardScreen();
            },
          );
        },
      ),

      /// MAIN APP (STUDENT/TEACHER SHELL)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ProfileGuard(navigationShell: navigationShell);
        },
        branches: [
          /// HOME
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
                      return AnnouncementDetailScreen(announcement: announcement);
                    },
                  ),
                ],
              ),
            ],
          ),

          /// HISTORY
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const AttendanceHistoryScreen(),
              ),
            ],
          ),

          /// JOURNAL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                builder: (context, state) => const DailyJournalScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const JournalFormScreen(),
                  ),
                ],
              ),
            ],
          ),

          /// PROFILE
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

/// 🔄 REFRESH ROUTER
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// 🔥 ROLE GUARD
class _ProfileGuard extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _ProfileGuard({required this.navigationShell});

  Future<String?> _getRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    return data['role'];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: _getRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;

        if (role == 'admin') {
          return const AdminDashboardScreen();
        }

        if (role == 'teacher') {
          return const TeacherDashboardScreen();
        }

        /// DEFAULT = STUDENT (MainScreen)
        return MainScreen(navigationShell: navigationShell);
      },
    );
  }
}