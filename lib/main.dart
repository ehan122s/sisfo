import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/services/supabase_config.dart';
import 'src/services/fcm_service.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/routing/app_router.dart';
import 'src/features/offline/services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Init Supabase
  await SupabaseConfig.initialize();

  // 3. Init date formatting
  await initializeDateFormatting('id_ID', null);

  // 4. Init FCM
  await FcmService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    ref.watch(syncServiceProvider);

    return MaterialApp.router(
      title: 'SIP SMEA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006400)),
        useMaterial3: true,
        fontFamily: 'GoogleFonts.inter().fontFamily',
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: router,
    );
  }
}
