import 'package:flutter/material.dart';

void main() => runApp(const JdsKeyholdApp());

class JdsKeyholdApp extends StatelessWidget {
  const JdsKeyholdApp({super.key});

  static const navy = Color(0xFF111D2E);
  static const blue = Color(0xFF3978F6);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JDS Keyhold',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: navy, elevation: 0),
        cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE8EDF3)))),
      ),
      home: const PreviewHome(),
    );
  }
}

class PreviewHome extends StatelessWidget {
  const PreviewHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JDS KEYHOLD', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('PROPERTY OPERATIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Color(0xFF7B8798), fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Good afternoon', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: JdsKeyholdApp.navy)),
        const SizedBox(height: 5),
        const Text('Your portfolio, at a glance.', style: TextStyle(color: Color(0xFF7B8798))),
        const SizedBox(height: 20),
        const Row(children: [Expanded(child: _Metric(title: 'Collected this month', value: 'UGX 8.45M', icon: Icons.trending_up_rounded)), SizedBox(width: 12), Expanded(child: _Metric(title: 'Outstanding', value: 'UGX 2.18M', icon: Icons.schedule_rounded))]),
        const SizedBox(height: 12),
        const Row(children: [Expanded(child: _Metric(title: 'Occupied units', value: '28 / 32', icon: Icons.apartment_rounded)), SizedBox(width: 12), Expanded(child: _Metric(title: 'Payments', value: '24', icon: Icons.receipt_long_rounded))]),
        const SizedBox(height: 24),
        const Text('Your properties', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: JdsKeyholdApp.navy)),
        const SizedBox(height: 10),
        const _PropertyTile(name: 'Muyenga Heights', location: 'Muyenga, Kampala', units: '12 of 13 units occupied', rent: 'UGX 3.2M collected'),
        const _PropertyTile(name: 'Bukasa Court', location: 'Bukasa, Makindye', units: '8 of 9 units occupied', rent: 'UGX 2.6M collected'),
        const _PropertyTile(name: 'Kira Gardens', location: 'Kira, Wakiso', units: '8 of 10 units occupied', rent: 'UGX 2.65M collected'),
        const SizedBox(height: 18),
        const Text('Mobile app scaffold — sample data only. Authentication, Supabase, offline sync, and printer integration are not connected yet.', style: TextStyle(fontSize: 12, color: Color(0xFF7B8798), height: 1.5)),
      ]),
      bottomNavigationBar: NavigationBar(selectedIndex: 0, destinations: const [NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'), NavigationDestination(icon: Icon(Icons.apartment_rounded), label: 'Properties'), NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Billing'), NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Account')], onDestinationSelected: (_) {}),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: JdsKeyholdApp.blue), const SizedBox(height: 12), Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF7B8798))), const SizedBox(height: 6), FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: JdsKeyholdApp.navy)))])));
}

class _PropertyTile extends StatelessWidget {
  const _PropertyTile({required this.name, required this.location, required this.units, required this.rent});
  final String name, location, units, rent;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.apartment_rounded, color: JdsKeyholdApp.blue)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: JdsKeyholdApp.navy)), const SizedBox(height: 3), Text(location, style: const TextStyle(fontSize: 11, color: Color(0xFF7B8798))), const SizedBox(height: 7), Text('$units · $rent', style: const TextStyle(fontSize: 10, color: Color(0xFF627087)))])), const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA4B1))])));
}
