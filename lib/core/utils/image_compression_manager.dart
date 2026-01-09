
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressionManager {
  // Singleton
  static final ImageCompressionManager _instance = ImageCompressionManager._internal();
  factory ImageCompressionManager() => _instance;
  ImageCompressionManager._internal();

  /// Compresses the image at [path] and returns a new [File] with the compressed data.
  /// 
  /// Strategy:
  /// - Format: WebP (lossy)
  /// - Quality: 85
  /// - Min Width/Height: 2048 (auto-resize if larger)
  /// - Keep Exif: false (privacy/size)
  Future<File?> compressImage(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;

    final fileName = p.basenameWithoutExtension(path);
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, '${fileName}_compressed.webp');

    // If it's already small enough or webp, maybe we skip? 
    // But requirement says "Smart Image Compression Engine", implies processing all.
    
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 85,
        format: CompressFormat.webp,
        minWidth: 2048,
        minHeight: 2048,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      // Fallback or error handling
      return null;
    }
  }
}
