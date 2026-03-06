import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/offline_queue_repository.dart';
import '../services/sync_service.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueCountAsync = ref.watch(offlineQueueCountProvider);
    final isSyncingAsync = ref.watch(isSyncingProvider);

    final queueCount = queueCountAsync.value ?? 0;
    final isSyncing = isSyncingAsync.value ?? false;

    if (queueCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSyncing
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSyncing
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          else
            const Icon(
              Icons.cloud_upload_outlined,
              size: 16,
              color: Colors.orange,
            ),
          const SizedBox(width: 8),
          Text(
            isSyncing ? 'Syncing...' : '$queueCount Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSyncing ? Colors.blue : Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }
}
