import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'subfolder_page.dart';
import 'package:path/path.dart' as p;

class FolderExplorerPage extends StatefulWidget {
  const FolderExplorerPage({super.key});

  @override
  State<FolderExplorerPage> createState() => _FolderExplorerPageState();
}

class _FolderExplorerPageState extends State<FolderExplorerPage> {
  String? _basePath; 
  List<Directory> _cameraFolders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final path = await StorageService.getBaseDirPublic();
      
      if (mounted) setState(() => _basePath = path);

      final baseDir = Directory(path);
      if (!(await baseDir.exists())) {
        await baseDir.create(recursive: true);
      }
      
      final cam1 = Directory(p.join(baseDir.path, 'Camera 1'));
      final cam2 = Directory(p.join(baseDir.path, 'Camera 2'));

      if (!(await cam1.exists())) await cam1.create(recursive: true);
      if (!(await cam2.exists())) await cam2.create(recursive: true);

      if (mounted) {
        setState(() {
          _cameraFolders = [cam1, cam2];
        });
      }

    } catch (e) {
      print("Error memuat folder: $e");
      if (mounted) {
        setState(() {
          _basePath = 'error';
          _cameraFolders = [];
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Gagal mengakses folder lokal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state (hapus const pada Scaffold)
    if (_basePath == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Penyimpanan File")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Main Content
    return Scaffold(
      appBar: AppBar(title: const Text("Penyimpanan File")),
      
      body: _cameraFolders.isEmpty
          ? Center(
              child: Text(
                _basePath == 'error'
                    ? 'Gagal memuat atau folder kosong.'
                    : 'Belum ada folder kamera yang dibuat.',
              ),
            )
          : ListView(
              children: _cameraFolders.map((folder) {
                final folderName = p.basename(folder.path);
                return _buildCameraFolder(context, folderName);
              }).toList(),
            ),
    );
  }

  Widget _buildCameraFolder(BuildContext context, String name) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(
        leading: const Icon(Icons.camera_alt, size: 40, color: Color(0xFF2979FF)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Folder Camera'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubFolderPage(camera: name),
            ),
          );
        },
      ),
    );
  }
}
