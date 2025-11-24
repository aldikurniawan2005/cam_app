import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'package:intl/intl.dart';

class VideoService {
  Timer? _timer;
  VoidCallback? onRecordingComplete;

  String _timestampFilename(String prefix, String ext) {
    final now = DateTime.now();
    final df = DateFormat('yyyy-MM-dd_HH-mm-ss');
    return '${prefix}_${df.format(now)}$ext';
  }

  /// Mulai merekam video dengan durasi tertentu
  Future<void> startRecording(
    CameraController controller, {
    required String camera,
    int durationMinutes = 10,
  }) async {
    try {
      if (!controller.value.isRecordingVideo) {
        // mulai rekaman; CameraController menangani path internal
        await controller.startVideoRecording();

        // Auto-stop setelah durasi tertentu
        _timer?.cancel();
        _timer = Timer(Duration(minutes: durationMinutes), () async {
          await stopRecording(controller, camera);
        });
      }
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  /// Hentikan rekaman dan simpan video ke folder aplikasi
  Future<void> stopRecording(
      [CameraController? controller,
      String camera = 'Camera 1']) async {
    try {
      if (controller != null && controller.value.isRecordingVideo) {
        final XFile file = await controller.stopVideoRecording();

        // simpan sementara di app dir dengan nama terformat
        final dir = await getApplicationDocumentsDirectory();
        final filename = _timestampFilename('VID', '.mp4');
        final savePath = '${dir.path}/$filename';

        await File(file.path).copy(savePath);

        // kirim nama kamera dan jenis ke StorageService => akan memindahkan ke Camera X/Video/yyyy-MM-dd/
        await StorageService.saveFile(savePath, 'video', camera);
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
    } finally {
      _timer?.cancel();
      onRecordingComplete?.call();
    }
  }
}
