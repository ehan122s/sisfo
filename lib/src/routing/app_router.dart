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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authRepository.authStateChanges),

    redirect: (context, state) {
      final currentUser = ref.read(authRepositoryProvider).currentUser;
      final isLoggedIn = currentUser != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSplash = state.uri.toString() == '/splash';

      if (!isLoggedIn) {
        return (isLoggingIn || isSplash) ? null : '/login';
      }

      if (isLoggedIn && (isLoggingIn || isSplash)) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/',
        builder: (context, state) => const _RoleBaseRedirector(),
      ),

      // --- ADMIN ROUTE ---
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // --- TEACHER ROUTE ---
      GoRoute(
        path: '/teacher',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TeacherDashboardScreen(),
      ),

      // --- STUDENT SHELL ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history', 
                builder: (context, state) => const AttendanceHistoryScreen()
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal', 
                builder: (context, state) => const DailyJournalScreen(),
                routes: [
                  // FIX: Menambahkan sub-route /create agar /journal/create bisa diakses
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey, // Supaya form menutupi bottom nav
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
                builder: (context, state) => const ProfileScreen()
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RoleBaseRedirector extends ConsumerWidget {
  const _RoleBaseRedirector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const LoginScreen();

        final role = profile['role']?.toString().toLowerCase() ?? 'student';
        final status = profile['status']?.toString().toLowerCase() ?? 'pending';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (role == 'admin') {
            context.go('/admin');
          } else if (role == 'teacher') {
            context.go('/teacher');
          } else {
            if (status != 'active') {
              context.go('/login'); // Atau arahkan ke VerificationStatusScreen
              showDialog(
                context: context,
                builder: (context) => VerificationStatusScreen(status: status),
              );
            } else {
              context.go('/home');
            }
          }
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Gagal memuat profil: $err')),
      ),
    );
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}