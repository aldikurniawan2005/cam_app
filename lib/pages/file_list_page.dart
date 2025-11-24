import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

// ✅ Kelas FileListPage untuk menampilkan file di dalam folder tanggal
class FileListPage extends StatefulWidget {
  final Directory folder; // Folder tanggal (misal: Senin-2025-11-03)
  const FileListPage({super.key, required this.folder});

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  late List<FileSystemEntity> _files;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    final items = widget.folder.listSync()
      ..sort((a, b) => b.path.compareTo(a.path));
    _files = items.whereType<File>().toList();
  }

  bool _isVideo(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.mp4', '.mov', '.avi'].contains(ext);
  }

  void _showImage(File file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }

  void _showVideo(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPreviewPage(file: file)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(p.basename(widget.folder.path))),
      body: _files.isEmpty
          ? const Center(child: Text("Folder kosong"))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index] as File;
                final name = p.basename(file.path);
                final isVid = _isVideo(file.path);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    leading: Icon(isVid ? Icons.videocam : Icons.image, color: Colors.blue, size: 40),
                    title: Text(name),
                    subtitle: Text("Ukuran: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB"),
                    onTap: () => isVid ? _showVideo(file) : _showImage(file),
                  ),
                );
              },
            ),
    );
  }
}

// ✅ Kelas VideoPreviewPage (seperti yang ada di file lama)
class VideoPreviewPage extends StatefulWidget {
  final File file;
  const VideoPreviewPage({super.key, required this.file});

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(p.basename(widget.file.path))),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
      ),
    );
  }
}