import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/hutang_model.dart';
import 'pages/add_hutang_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Tracker Hutang',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),

        scaffoldBackgroundColor: const Color(0xfff5f7fb),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),

      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<HutangModel> dataHutang = [];
  Future<void> simpanHutang(HutangModel data) async {
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('hutang')
        .add({
          'nama': data.nama,
          'jumlah': data.jumlah,
          'jenis': data.jenis,
          'tanggal': DateTime.now(),
        });

    print("ID data: ${docRef.id}");
  }

  int get totalPiutang {
    int total = 0;

    for (var item in dataHutang) {
      if (item.jenis == 'Piutang') {
        total += item.jumlah;
      }
    }

    return total;
  }

  int get totalHutang {
    int total = 0;

    for (var item in dataHutang) {
      if (item.jenis == 'Hutang') {
        total += item.jumlah;
      }
    }

    return total;
  }

  void tambahData(HutangModel data) {
    setState(() {
      dataHutang.add(data);
    });

    simpanHutang(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker Hutang')),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Total Piutang',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Rp $totalPiutang',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Total Hutang',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Rp $totalHutang',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () async {
                    final hasil = await Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (context) => const AddHutangPage(),
                      ),
                    );

                    if (hasil != null) {
                      tambahData(hasil);
                    }
                  },

                  child: const Text('Tambah Data Hutang'),
                ),
              ),

              const SizedBox(height: 20),

              ListView.builder(
                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),
                itemCount: dataHutang.length,

                itemBuilder: (context, index) {
                  final item = dataHutang[index];

                  return Card(
                    child: ListTile(
                      title: Text(item.nama),

                      subtitle: Text('${item.jenis} - Rp ${item.jumlah}'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
