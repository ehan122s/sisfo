import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../features/authentication/data/auth_repository.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/verification_status_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/profile/data/profile_repository.dart';
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
  final authStream = authRepository.authStateChanges;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(authStream),
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
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      
      // Tetap sediakan route admin secara manual jika ingin pindah lewat URL
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Mobile App Shell (Tampilan Siswa)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // BYPASS: Langsung return _ProfileGuard tanpa cek kIsWeb
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
                    parentNavigatorKey: _rootNavigatorKey,
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

// --- BYPASS MODE ---
class _ProfileGuard extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _ProfileGuard({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SEMUA LOGIKA PENGECEKAN ROLE DIHAPUS.
    // SIAPAPUN YANG LOGIN AKAN MASUK KE MAINSCREEN (HOME MOBILE).
    return MainScreen(navigationShell: navigationShell);
  }
}