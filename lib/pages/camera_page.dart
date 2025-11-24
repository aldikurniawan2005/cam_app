import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import '../services/video_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  bool _isRecording = false;
  List<CameraDescription>? _cameras;
  final VideoService _videoService = VideoService();
  ResolutionPreset _currentPreset = ResolutionPreset.medium;

  /// ✅ Tambahkan variabel ini untuk simpan kamera aktif
  String selectedCamera = 'Camera 1';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Ambil argumen dari SettingsPage (misal: 'Camera 1' / 'Camera 2')
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args.containsKey('camera')) {
      selectedCamera = args['camera'];
      debugPrint('📷 Menggunakan: $selectedCamera');
    }
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_controller != null) {
        await _controller!.dispose();
      }

      // Gunakan selalu kamera pertama (indeks 0), biasanya kamera belakang
      CameraDescription cameraToUse = _cameras!.first;

      // ❌ Baris di bawah ini dihapus/diubah untuk selalu menggunakan kamera belakang (indeks 0)
      /*
      if (selectedCamera == 'Camera 2' && _cameras!.length > 1) {
        cameraToUse = _cameras![1];
      } else {
        cameraToUse = _cameras!.first;
      }
      */

      _controller = CameraController(
        cameraToUse, // Selalu menggunakan kamera pertama
        _currentPreset,
        enableAudio: true,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final XFile xfile = await _controller!.takePicture();
    final dir = await getApplicationDocumentsDirectory();
    final savePath =
        '${dir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(xfile.path).copy(savePath);

    // ✅ kirim nama kamera ke StorageService
    await StorageService.saveFile(savePath, 'image', selectedCamera);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📸 Foto tersimpan')),
    );
  }

  Future<void> _toggleRecord() async {
    if (_controller == null) return;

    if (_isRecording) {
      await _videoService.stopRecording(_controller, selectedCamera);
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🛑 Rekaman berhenti & disimpan')),
      );
    } else {
      await _videoService.startRecording(_controller!,
          camera: selectedCamera, durationMinutes: 10);
      setState(() => _isRecording = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔴 Rekaman dimulai')),
      );

      _videoService.onRecordingComplete = () {
        if (mounted) setState(() => _isRecording = false);
      };
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Kamera ($selectedCamera)'),
        actions: [
          DropdownButton<ResolutionPreset>(
            value: _currentPreset,
            items: ResolutionPreset.values.map((preset) {
              return DropdownMenuItem(
                value: preset,
                child: Text(preset.toString().split('.').last),
              );
            }).toList(),
            onChanged: (preset) async {
              if (preset != null) {
                setState(() => _currentPreset = preset);
                await _initCamera();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text('Status',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _isRecording ? 'Merekam...' : 'Siap',
                      style: const TextStyle(color: Color(0xFF9AA4B2)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('📷'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _toggleRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRecording ? Colors.red : Colors.blue,
                      ),
                      child: Text(_isRecording ? 'STOP' : 'REC'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}