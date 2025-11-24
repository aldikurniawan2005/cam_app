import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'file_list_page.dart';
import '../services/storage_service.dart';

class SubFolderPage extends StatefulWidget {
  final String camera; // "Camera 1" atau "Camera 2"
  const SubFolderPage({super.key, required this.camera});

  @override
  State<SubFolderPage> createState() => _SubFolderPageState();
}

class _SubFolderPageState extends State<SubFolderPage> {
  List<Directory> _typeFolders = []; // Folder Gambar & Video

  @override
  void initState() {
    super.initState();
    _loadTypeFolders();
  }

  Future<void> _loadTypeFolders() async {
    final baseDirPublic = await StorageService.getBaseDirPublic();
    final cameraDir = Directory(p.join(baseDirPublic, widget.camera));

    // ✅ Pastikan folder Gambar dan Video dibuat dan dimuat
    final videoDir = Directory(p.join(cameraDir.path, 'Video'));
    final imageDir = Directory(p.join(cameraDir.path, 'Gambar'));

    if (!(await videoDir.exists())) await videoDir.create(recursive: true);
    if (!(await imageDir.exists())) await imageDir.create(recursive: true);

    setState(() {
      _typeFolders = [imageDir, videoDir];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.camera} Folder")),
      body: _typeFolders.isEmpty
          ? const Center(child: Text("Memuat folder..."))
          : ListView.builder(
              itemCount: _typeFolders.length,
              itemBuilder: (context, index) {
                final folder = _typeFolders[index];
                final name = p.basename(folder.path);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    leading: Icon(name == 'Video' ? Icons.video_library : Icons.image, 
                                  color: name == 'Video' ? Colors.red : Colors.green, 
                                  size: 48),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Folder Jenis File'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigasi ke folder tanggal
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DateFolderPage(typeFolder: folder), // Navigasi ke halaman folder tanggal
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class DateFolderPage extends StatefulWidget {
  final Directory typeFolder; // Folder Gambar atau Video
  const DateFolderPage({super.key, required this.typeFolder});

  @override
  State<DateFolderPage> createState() => _DateFolderPageState();
}

class _DateFolderPageState extends State<DateFolderPage> {
  List<Directory> _dateFolders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    if (await widget.typeFolder.exists()) {
      final dirs = widget.typeFolder
          .listSync()
          .whereType<Directory>()
          .toList()
          .cast<Directory>()
          ..sort((a, b) => b.path.compareTo(a.path)); // Sort terbaru dulu
      setState(() => _dateFolders = dirs);
    }
  }

  String _formatFolderName(String folderName) {
    // Format nama folder dari Senin-2025-11-03 menjadi Senin, 03-11-2025
    final parts = folderName.split('-');
    if (parts.length == 4) {
      final day = parts[0];
      final year = parts[1];
      final month = parts[2];
      final date = parts[3];
      return "$day, $date-$month-$year";
    }
    return folderName;
  }

  @override
  Widget build(BuildContext) {
    final typeName = p.basename(widget.typeFolder.path);
    return Scaffold(
      appBar: AppBar(title: Text("Folder $typeName")),
      body: _dateFolders.isEmpty
          ? Center(child: Text("Belum ada folder $typeName tersimpan"))
          : ListView.builder(
              itemCount: _dateFolders.length,
              itemBuilder: (context, index) {
                final folder = _dateFolders[index];
                final name = p.basename(folder.path);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blueGrey, size: 48),
                    title: Text(_formatFolderName(name), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(name),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigasi ke halaman list file
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FileListPage(folder: folder),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}