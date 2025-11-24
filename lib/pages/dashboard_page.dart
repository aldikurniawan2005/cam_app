import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width:44,height:44,decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),gradient: LinearGradient(colors:[Color(0xFF2979FF), Color(0xFF5AA0FF)])), child: const Center(child: Text('CI', style: TextStyle(color: Color(0xFF06102A), fontWeight: FontWeight.bold)))),
          const SizedBox(width:12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Smart Capture', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Dark Elegant • Capture & Storage', style: TextStyle(fontSize:12, color: Color(0xFF9AA4B2))),
          ])
        ]),
        actions: [
          IconButton(onPressed: () => Navigator.pushNamed(context, '/status'), icon: const Icon(Icons.wifi))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            CustomCard(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Halo, Operator', style: TextStyle(fontSize:18, fontWeight: FontWeight.w700)),
                  SizedBox(height:6),
                  Text('Pilih fitur untuk melanjutkan', style: TextStyle(color: Color(0xFF9AA4B2)))
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: const [
                  Text('Default: 2x/hari (08:00, 15:00)', style: TextStyle(color: Color(0xFF9AA4B2), fontSize:12)),
                  SizedBox(height:6),
                  Text('Minggu: 14 file', style: TextStyle(color: Color(0xFF9AA4B2), fontSize:12)),
                ])
              ]),
            ),
            const SizedBox(height:12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _tile(context, '⚙️ Pengaturan', 'Atur resolusi, durasi, jadwal', '/settings'),
                  _tile(context, '📸 Kamera', 'Gunakan kamera untuk rekam / foto', '/camera'),
                  _tile(context, '💾 Penyimpanan', 'Lihat & kirim file ke server', '/explorer'), // ✅ Berubah ke /explorer
                  _tile(context, '📶 Status', 'Monitor koneksi & sinkron', '/status'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String subtitle, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height:8),
          Text(subtitle, style: const TextStyle(color: Color(0xFF9AA4B2))),
        ]),
      ),
    );
  }
}