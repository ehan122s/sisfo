import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressionService {
  /// Compresses an image file to a target size/quality.
  ///
  /// Returns a new [File] with the compressed image.
  /// The original file is not modified.
  Future<File> compressImage(File file) async {
    // Create output path in temporary directory

    // Or closer to documentation standard:
    final tempDir = await getTemporaryDirectory();
    final fileName = p.basenameWithoutExtension(file.path);
    final targetPath = p.join(tempDir.path, '${fileName}_compressed.jpg');

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }
}

final imageCompressionServiceProvider = Provider<ImageCompressionService>((
  ref,
) {
  return ImageCompressionService();
});
