// main.dart
import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';
import 'pages/camera_page.dart';
import 'pages/storage_page.dart';
import 'pages/status_page.dart';
import 'pages/folder_explorer_page.dart';
import 'services/connectivity_service.dart';
// ✅ Import Firebase Core
import 'package:firebase_core/firebase_core.dart';
// ✅ Import file konfigurasi yang dihasilkan
import 'firebase_options.dart'; 
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ Muat pengaturan kamera awal dari Firestore
  await StorageService.loadSettings(); 

  // mulai listener koneksi (opsional inisialisasi)
  ConnectivityService.init();
  StorageService.startAutoUploadListener(); // Mulai listener sinkronisasi
  
  runApp(const SmartCaptureApp());
}

class SmartCaptureApp extends StatelessWidget {
  const SmartCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData.dark();
    return MaterialApp(
      title: 'Smart Capture',
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        primaryColor: const Color(0xFF2979FF),
        textTheme: base.textTheme.apply(bodyColor: const Color(0xFFE6EEF6)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0x0F0F1720),
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),
        '/settings': (context) => const SettingsPage(),
        '/camera': (context) => const CameraPage(),
        '/storage': (context) => const StoragePage(), 
        '/explorer': (context) => const FolderExplorerPage(), 
        '/status': (context) => const StatusPage(),
      },
    );
  }
}