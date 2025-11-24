// storage_service.dart
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'connectivity_service.dart';
// ✅ Import Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  // ✅ Inisialisasi Firestore
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  // List in-memory untuk menyimpan metadata yang sudah dimuat/baru dibuat
  static final List<Map<String, dynamic>> _metadata = []; 
  
  static const String _serverUrl = 'http://192.168.1.10:5000/upload'; 

  // Variabel statis untuk kamera aktif
  static String activeCamera = 'Camera 1';
  static const String _settingsDocId = 'global_settings';
  static const String _metadataCollection = 'file_metadata';

  // --- 1. Pengaturan Kamera & Loading ---

  /// ✅ Muat pengaturan dari Firestore saat aplikasi dimulai
  static Future<void> loadSettings() async {
    try {
      final doc = await _db.collection('settings').doc(_settingsDocId).get();
      if (doc.exists && doc.data()!.containsKey('activeCamera')) {
        activeCamera = doc.data()!['activeCamera'] as String;
        print('Pengaturan dimuat dari Firestore: Kamera aktif = $activeCamera');
      }
    } catch (e) {
      print("Gagal memuat pengaturan Firestore: $e");
    }
  }

  /// ✅ Simpan kamera aktif ke Firestore
  static Future<void> setActiveCameraFolder(String camera) async {
    activeCamera = camera;
    try {
      await _db.collection('settings').doc(_settingsDocId).set({
        'activeCamera': camera,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Camera aktif diatur & disimpan ke Firestore: $activeCamera');
    } catch (e) {
      print("Gagal menyimpan activeCamera ke Firestore: $e");
    }
  }

  // --- 2. File I/O & Metadata ---

  static Future<String> _getBaseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<String> getBaseDirPublic() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'SmartCapture');
  }

  /// Simpan file ke folder lokal DAN metadata ke Firestore
  static Future<void> saveFile(String path, String type, String camera) async {
    final baseDir = await getBaseDirPublic();

    // Logika pembentukan path lokal
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final weekday = _getDayName(now.weekday);
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final fileTypeFolder = type == 'video' ? 'Video' : 'Gambar';
    final folderName = "$weekday-$dateStr";
    final subDir = Directory(p.join(baseDir, camera, fileTypeFolder, folderName));
    if (!(await subDir.exists())) await subDir.create(recursive: true);

    final name = p.basename(path);
    final newPath = p.join(subDir.path, name);

    final originalFile = File(path);
    await originalFile.copy(newPath);
    
    // --- Metadata File ---
    final fileInfo = {
      'path': newPath,
      'name': name,
      'type': type,
      'camera': camera,
      'folder': folderName,
      'main': fileTypeFolder,
      'date': "$weekday, $dateStr • $timeStr",
      'uploaded': false,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Timestamp Firestore
      'localPath': newPath, // Simpan path lokal
    };

    // Simpan metadata ke Firestore
    try {
      final docRef = await _db.collection(_metadataCollection).add(fileInfo);
      fileInfo['id'] = docRef.id; // Simpan ID Firestore
      _metadata.insert(0, fileInfo);
    } catch (e) {
      print("Gagal menyimpan metadata ke Firestore: $e");
      _metadata.insert(0, fileInfo); // Tetap simpan di list lokal
    }
    
    // Coba kirim file fisik otomatis
    if (await ConnectivityService.isConnected()) {
      await _trySendFile(fileInfo);
    }
  }

  /// ✅ Ambil metadata dari Firestore (dan lokal in-memory)
  static Future<List<Map<String, dynamic>>> getFiles() async {
    // Selalu coba ambil data terbaru dari Firestore
    try {
      final snapshot = await _db.collection(_metadataCollection)
          .orderBy('createdAt', descending: true)
          .get();
          
      _metadata.clear(); // Hapus data lama in-memory
      
      final files = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Pastikan path lokal tetap ada, karena Firestore tidak bisa menyimpan File objek
        data['path'] = data['localPath']; 
        return data;
      }).toList();
      
      _metadata.addAll(files);
      return files;
      
    } catch (e) {
      print("Gagal mengambil metadata dari Firestore: $e. Menggunakan cache lokal.");
      return List.from(_metadata);
    }
  }

  // --- 3. Hapus, Bersihkan, dan Upload ---
  
  static Future<void> deleteFile(Map<String, dynamic> file) async {
    // 1. Hapus dari penyimpanan lokal
    try {
      final f = File(file['path']);
      if (await f.exists()) await f.delete();
    } catch (e) {
      print("Gagal hapus file lokal: $e");
    }
    
    // 2. Hapus metadata dari Firestore
    try {
      if (file.containsKey('id')) {
        await _db.collection(_metadataCollection).doc(file['id']).delete();
      }
    } catch (e) {
      print("Gagal hapus metadata Firestore: $e");
    }
    
    // 3. Hapus dari list in-memory
    _metadata.removeWhere((e) => e['path'] == file['path']);
  }

  static Future<void> clearFiles() async {
    // Hapus file fisik lokal
    for (var f in List.from(_metadata)) {
      try {
        final file = File(f['path']);
        if (await file.exists()) await file.delete();
      } catch (e) {
        print("Gagal hapus file: $e");
      }
    }
    
    // ✅ Hapus semua metadata dari Firestore
    try {
      final batch = _db.batch();
      final snapshot = await _db.collection(_metadataCollection).get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Gagal clear metadata Firestore: $e");
    }
    
    _metadata.clear();
  }

  static Future<void> _trySendFile(Map<String, dynamic> file,
      {int retryCount = 3}) async {
    final f = File(file['path']);
    if (!await f.exists()) {
      _metadata.removeWhere((e) => e['path'] == file['path']);
      print("❌ File tidak ditemukan: ${file['name']}");
      return;
    }

    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        var req = http.MultipartRequest('POST', Uri.parse(_serverUrl));
        req.files.add(await http.MultipartFile.fromPath('file', f.path));
        req.fields['type'] = file['type'];
        req.fields['camera'] = file['camera'];
        req.fields['folder'] = file['folder'];

        var response = await req.send();
        if (response.statusCode == 200) {
          print("✅ File berhasil dikirim: ${file['name']}");
          
          // ✅ Update status upload di Firestore
          if (file.containsKey('id')) {
            await _db.collection(_metadataCollection).doc(file['id']).update({'uploaded': true});
          }
          file['uploaded'] = true;
          return;
        } else {
          print("❌ Gagal upload (status ${response.statusCode})");
        }
      } catch (e) {
        print("❌ Gagal upload (${file['name']}): $e");
      }
      await Future.delayed(const Duration(seconds: 5));
    }
    print("⚠️ Upload gagal setelah $retryCount percobaan: ${file['name']}");
  }

  static Future<void> sendFile(Map<String, dynamic> file) async {
    await _trySendFile(file);
  }
  
  static Future<void> sendAll() async {
    final filesToUpload = await getFiles(); 
    
    if (!(await ConnectivityService.isConnected())) {
      print("⚠️ Tidak ada koneksi internet. Upload ditunda.");
      return;
    }

    for (var file in filesToUpload) {
      if (file['uploaded'] == false) {
        await _trySendFile(file);
      }
    }
  }
  
  static void startAutoUploadListener() {
    ConnectivityService.connectionStream.listen((connected) {
      if (connected) {
        print("📶 Koneksi online kembali, mengirim semua file...");
        sendAll();
      }
    });
  }


  static String _getDayName(int day) {
    switch (day) {
      case 1:
        return "Senin";
      case 2:
        return "Selasa";
      case 3:
        return "Rabu";
      case 4:
        return "Kamis";
      case 5:
        return "Jumat";
      case 6:
        return "Sabtu";
      case 7:
        return "Minggu";
      default:
        return "";
    }
  }
}