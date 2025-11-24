import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/storage_service.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

enum SortOrder { terbaru, terlama, nameAZ, nameZA }

class _StoragePageState extends State<StoragePage> {
  Map<String, Map<String, List<Map<String, dynamic>>>> groupedFiles = {};
  SortOrder _sortOrder = SortOrder.terbaru;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await StorageService.getFiles();
    final tempGroup = {
      'Gambar': <String, List<Map<String, dynamic>>>{},
      'Video': <String, List<Map<String, dynamic>>>{}
    };

    for (var f in files) {
      final main = f['main'];
      final folder = f['folder'];
      tempGroup[main] ??= {};
      tempGroup[main]![folder] ??= [];
      tempGroup[main]![folder]!.add(f);
    }

    // Sort per folder
    for (var mainType in tempGroup.keys) {
      for (var folder in tempGroup[mainType]!.keys) {
        tempGroup[mainType]![folder]!.sort((a, b) {
          switch (_sortOrder) {
            case SortOrder.terbaru:
              return _parseDate(b['date']).compareTo(_parseDate(a['date']));
            case SortOrder.terlama:
              return _parseDate(a['date']).compareTo(_parseDate(b['date']));
            case SortOrder.nameAZ:
              return a['name'].toString().compareTo(b['name'].toString());
            case SortOrder.nameZA:
              return b['name'].toString().compareTo(a['name'].toString());
          }
        });
      }
    }

    setState(() => groupedFiles = tempGroup);
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split(' • ');
      final datePart = parts[0].split(', ')[1]; // "2025-11-03"
      final timePart = parts.length > 1 ? parts[1] : '00:00';
      return DateTime.parse("$datePart $timePart:00");
    } catch (e) {
      return DateTime.now();
    }
  }

  void _openFile(Map<String, dynamic> f) {
    if (f['type'] == 'video') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerPage(f['path'])),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImageViewerPage(f['path'])),
      );
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> f) async {
    await StorageService.deleteFile(f);
    _loadFiles();
  }

  Future<void> _uploadFolder(String main, String folder) async {
    final files = groupedFiles[main]?[folder] ?? [];
    for (var f in files) {
      await StorageService.sendFile(f);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📤 Folder "$folder" berhasil dikirim')),
    );
  }

  Future<void> _sendAll() async {
    await StorageService.sendAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📤 Semua file dikirim ke server')),
    );
  }

  Future<void> _clearAll() async {
    await StorageService.clearFiles();
    _loadFiles();
  }

  Widget _buildFileRow(Map<String, dynamic> f) {
    return ListTile(
      onTap: () => _openFile(f),
      leading: f['type'] == 'video'
          ? const Icon(Icons.videocam, size: 40)
          : Image.file(File(f['path']), width: 50, height: 50, fit: BoxFit.cover),
      title: Text(f['name']),
      subtitle: Text(f['date']),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              onPressed: () async => await _deleteFile(f),
              icon: const Icon(Icons.delete)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penyimpanan Lokal'),
        actions: [
          DropdownButton<SortOrder>(
            value: _sortOrder,
            underline: const SizedBox(),
            icon: const Icon(Icons.sort, color: Colors.white),
            items: const [
              DropdownMenuItem(value: SortOrder.terbaru, child: Text('Terbaru')),
              DropdownMenuItem(value: SortOrder.terlama, child: Text('Terlama')),
              DropdownMenuItem(value: SortOrder.nameAZ, child: Text('Nama A-Z')),
              DropdownMenuItem(value: SortOrder.nameZA, child: Text('Nama Z-A')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortOrder = value);
                _loadFiles();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Hapus Semua',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: groupedFiles.isEmpty
          ? const Center(child: Text('Belum ada file tersimpan'))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: ['Gambar', 'Video'].map((mainType) {
                      final group = groupedFiles[mainType] ?? {};
                      return ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Text('📂', style: TextStyle(fontSize: 24)),
                        title: Text(
                          mainType,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        children: group.entries.map((entry) {
                          final folder = entry.key;
                          final files = entry.value;
                          return ExpansionTile(
                            leading:
                                const Text('📂', style: TextStyle(fontSize: 20)),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(folder,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                IconButton(
                                    tooltip: 'Upload Folder',
                                    icon: const Icon(Icons.upload),
                                    onPressed: () =>
                                        _uploadFolder(mainType, folder)),
                              ],
                            ),
                            children: files.map((f) => _buildFileRow(f)).toList(),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    onPressed: _sendAll,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('📤 Kirim Semua ke Server'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                  ),
                )
              ],
            ),
    );
  }
}

/// =====================
/// Halaman untuk memutar video
/// =====================
class VideoPlayerPage extends StatefulWidget {
  final String path;
  const VideoPlayerPage(this.path, {super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: true,
          looping: false,
        );
        setState(() {});
      });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: Center(
        child: _chewieController != null && _controller.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// =====================
/// Halaman untuk menampilkan gambar
/// =====================
class ImageViewerPage extends StatelessWidget {
  final String path;
  const ImageViewerPage(this.path, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lihat Gambar')),
      body: Center(
        child: Image.file(File(path), fit: BoxFit.contain),
      ),
    );
  }
}
