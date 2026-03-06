import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(LucideIcons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.bookOpen),
            label: 'Jurnal',
          ),
          NavigationDestination(icon: Icon(LucideIcons.user), label: 'Profil'),
        ],
      ),
    );
  }
}
