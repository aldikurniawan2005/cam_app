import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    ConnectivityService.connectionStream.listen((v){
      setState(()=> _connected = v);
    });
    ConnectivityService.isConnected().then((v) => setState(()=> _connected = v));
  }

  void _toggleConnection() {
    // hanya simulasi toggle local (real toggling jaringan tidak mungkin)
    setState(()=> _connected = !_connected);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_connected ? 'Terhubung' : 'Tidak Terhubung')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koneksi & Sinkron')),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(children: [
          Card(
            color: Colors.white.withOpacity(0.02),
            child: ListTile(
              title: Text(_connected ? 'Terhubung' : 'Tidak Terhubung'),
              subtitle: const Text('Server: contoh.server.local', style: TextStyle(color: Color(0xFF9AA4B2))),
              trailing: ElevatedButton(onPressed: _toggleConnection, child: Text(_connected ? 'Putuskan' : 'Hubungkan')),
            ),
          ),
          const SizedBox(height:12),
          const Text('Sinkron terakhir: -', style: TextStyle(color: Color(0xFF9AA4B2))),
        ]),
      ),
    );
  }
}