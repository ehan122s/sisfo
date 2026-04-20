import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/data/auth_repository.dart';
import '../features/profile/data/profile_repository.dart';
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

// Helper: Fade + Slide transition
CustomTransitionPage _buildPageWithTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade + slide up
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      final slideTween =
          Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      return FadeTransition(
        opacity: fadeTween,
        child: SlideTransition(position: slideTween, child: child),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authRepository.authStateChanges),

    redirect: (context, state) {
      final currentUser = ref.read(authRepositoryProvider).currentUser;
      final isLoggedIn = currentUser != null;
      final path = state.uri.toString();
      final isLoggingIn = path == '/login';
      final isSplash = path == '/splash';

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
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/verification',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: VerificationStatusScreen(
            status: state.extra as String? ?? 'pending',
          ),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const _RoleBaseRedirector(),
        ),
      ),

      // --- ADMIN ROUTE ---
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const AdminDashboardScreen(),
        ),
      ),

      // --- TEACHER ROUTE ---
      GoRoute(
        path: '/teacher',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const TeacherDashboardScreen(),
        ),
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
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context: context,
                  state: state,
                  child: const HomeScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'announcements/detail',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildPageWithTransition(
                      context: context,
                      state: state,
                      child: AnnouncementDetailScreen(
                        announcement: state.extra as AnnouncementModel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context: context,
                  state: state,
                  child: const AttendanceHistoryScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context: context,
                  state: state,
                  child: const DailyJournalScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _buildPageWithTransition(
                      context: context,
                      state: state,
                      child: const JournalFormScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context: context,
                  state: state,
                  child: const ProfileScreen(),
                ),
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
        print('=== PROFILE DATA: $profile');

        if (profile == null) {
          print('=== PROFILE NULL, ke login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = profile['role']?.toString().toLowerCase() ?? 'student';
        final status =
            profile['status']?.toString().toLowerCase() ?? 'pending';

        print('=== ROLE: $role, STATUS: $status');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (role == 'admin') {
            context.go('/admin');
          } else if (role == 'teacher') {
            context.go('/teacher');
          } else {
            if (status == 'active') {
              context.go('/home');
            } else {
              context.go('/verification', extra: status);
            }
          }
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () {
        print('=== PROFILE LOADING...');
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (err, stack) {
        print('=== PROFILE ERROR: $err');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        );
      },
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