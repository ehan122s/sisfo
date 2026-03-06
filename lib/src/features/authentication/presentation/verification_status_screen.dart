import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

class VerificationStatusScreen extends ConsumerWidget {
  final String status;

  const VerificationStatusScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isRejected = status == 'rejected';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
              size: 80,
              color: isRejected ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              isRejected ? "Pendaftaran Ditolak" : "Menunggu Verifikasi",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isRejected ? Colors.red : Colors.orange[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isRejected
                  ? "Mohon maaf, pendaftaran akun Anda ditolak oleh Admin. Silakan hubungi sekolah untuk informasi lebih lanjut."
                  : "Akun Anda sedang dalam proses verifikasi oleh Admin/Guru Pembimbing. Anda dapat login kembali setelah akun disetujui.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
