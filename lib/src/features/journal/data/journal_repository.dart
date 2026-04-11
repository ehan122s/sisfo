import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final journalRepositoryProvider = Provider((ref) {

  return JournalRepository();

});

class JournalRepository {

  final supabase = Supabase.instance.client;

  /// upload file android
  Future<String> uploadEvidenceFile(File file) async {

    final fileName =
        DateTime.now().millisecondsSinceEpoch.toString();

    final path = "journals/$fileName.jpg";

    await supabase.storage

        .from("journal")

        .upload(path, file);

    return supabase.storage

        .from("journal")

        .getPublicUrl(path);
  }

  /// upload file web
  Future<String> uploadEvidenceBytes(

    Uint8List bytes,

  ) async {

    final fileName =
        DateTime.now().millisecondsSinceEpoch.toString();

    final path = "journals/$fileName.jpg";

    await supabase.storage

        .from("journal")

        .uploadBinary(path, bytes);

    return supabase.storage

        .from("journal")

        .getPublicUrl(path);
  }

  /// simpan jurnal
  Future submitJournal({

    required String title,

    required String description,

    required String imageUrl,

  }) async {

    await supabase.from("journals").insert({

      "title": title,

      "description": description,

      "image_url": imageUrl,

      "created_at":
          DateTime.now().toIso8601String(),
    });
  }

  /// ambil data jurnal
  Future<List> getJournals() async {

    final res = await supabase

        .from("journals")

        .select()

        .order("created_at",
            ascending: false);

    return res;
  }
}