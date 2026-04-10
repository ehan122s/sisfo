import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/services/supabase_config.dart'; // Uncomment once keys are ready

import 'package:intl/date_symbol_data_local.dart';
import 'src/routing/app_router.dart';
import 'src/features/offline/services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();
  await initializeDateFormatting('id_ID', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    ref.watch(syncServiceProvider); // Initialize Sync Service

    return MaterialApp.router(
      title: 'E-PKL SMEA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006400),
        ), // Dark Green (SMK Vibe)
        useMaterial3: true,
        fontFamily: 'GoogleFonts.inter().fontFamily',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: router,
    );
  }
}
