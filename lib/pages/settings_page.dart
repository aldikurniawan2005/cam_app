import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart'; // ✅ Pastikan import ada

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _resolution = '1280x720';
  int _duration = 10;
  // ✅ Mengambil nilai awal dari StorageService
  String _selectedCamera = StorageService.activeCamera; 
  TimeOfDay _time1 = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _time2 = const TimeOfDay(hour: 15, minute: 0);

  Future<void> _pickTime(int idx) async {
    final t = await showTimePicker(
      context: context,
      initialTime: idx == 1 ? _time1 : _time2,
    );
    if (t != null) {
      setState(() {
        if (idx == 1) {
          _time1 = t;
        } else {
          _time2 = t;
        }
      });
    }
  }

  void _saveSettings() async {
    // Simpan kamera aktif ke StorageService sebelum navigasi
    await StorageService.setActiveCameraFolder(_selectedCamera); // ✅ Memperbaiki error dengan menambahkan fungsi di StorageService

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan')),
    );

    // Contoh pengiriman data ke halaman kamera
    Navigator.pushReplacementNamed(context, '/camera', arguments: {
      'camera': _selectedCamera,
      'resolution': _resolution,
      'duration': _duration,
      'time1': _time1,
      'time2': _time2,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Capture')),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: ListView(
          children: [
            const Text(
              'Pengaturan Kamera',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text('Pilih Kamera', style: TextStyle(color: Color(0xFF9AA4B2))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedCamera,
              items: const [
                DropdownMenuItem(value: 'Camera 1', child: Text('Camera 1')),
                DropdownMenuItem(value: 'Camera 2', child: Text('Camera 2')),
              ],
              onChanged: (v) async {
                if (v != null) {
                  setState(() => _selectedCamera = v);
                  await StorageService.setActiveCameraFolder(v); // ✅ Memperbaiki error dengan menambahkan fungsi di StorageService
                }
              },
            ),
            const SizedBox(height: 20),

            const Text('Pengaturan Video',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            const Text('Resolusi', style: TextStyle(color: Color(0xFF9AA4B2))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _resolution,
              items: const [
                DropdownMenuItem(value: '640x360', child: Text('640 x 360 (SD)')),
                DropdownMenuItem(value: '1280x720', child: Text('1280 x 720 (HD)')),
                DropdownMenuItem(value: '1920x1080', child: Text('1920 x 1080 (FHD)')),
              ],
              onChanged: (v) => setState(() => _resolution = v!),
            ),
            const SizedBox(height: 12),
            const Text('Durasi per file', style: TextStyle(color: Color(0xFF9AA4B2))),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _duration,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 menit')),
                DropdownMenuItem(value: 20, child: Text('20 menit')),
                DropdownMenuItem(value: 30, child: Text('30 menit')),
              ],
              onChanged: (v) => setState(() => _duration = v!),
            ),
            const SizedBox(height: 12),
            const Text('Jadwal (2 contoh waktu)',
                style: TextStyle(color: Color(0xFF9AA4B2))),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => _pickTime(1),
                      child: Text(_time1.format(context)))),
              const SizedBox(width: 8),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => _pickTime(2),
                      child: Text(_time2.format(context)))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Simpan & Gunakan Kamera')),
              const SizedBox(width: 8),
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal')),
            ]),
          ],
        ),
      ),
    );
  }
}