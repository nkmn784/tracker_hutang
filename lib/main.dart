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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker Hutang')),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
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
                      simpanHutang(hasil);
                    }
                  },

                  child: const Text('Tambah Data Hutang'),
                ),
              ),

              const SizedBox(height: 20),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('hutang')
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  int totalPiutang = 0;
                  int totalHutang = 0;

                  for (var doc in docs) {
                    final data = doc.data();

                    if (data['jenis'] == 'Piutang') {
                      totalPiutang += (data['jumlah'] as num).toInt();
                    } else {
                      totalHutang += (data['jumlah'] as num).toInt();
                    }
                  }

                  return Column(
                    children: [
                      Text(
                        'Total Piutang: Rp $totalPiutang',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Total Hutang: Rp $totalHutang',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 20),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,

                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final docId = docs[index].id;
                          return Card(
                            child: ListTile(
                              title: Text(data['nama']),

                              subtitle: Text(
                                '${data['jenis']} - Rp ${data['jumlah']}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),

                                    onPressed: () {
                                      showDialog(
                                        context: context,

                                        builder: (context) {
                                          TextEditingController namaController =
                                              TextEditingController(
                                                text: data['nama'],
                                              );

                                          TextEditingController
                                          jumlahController =
                                              TextEditingController(
                                                text: data['jumlah'].toString(),
                                              );

                                          return AlertDialog(
                                            title: const Text('Edit Data'),

                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,

                                              children: [
                                                TextField(
                                                  controller: namaController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Nama',
                                                      ),
                                                ),

                                                TextField(
                                                  controller: jumlahController,
                                                  keyboardType:
                                                      TextInputType.number,

                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Jumlah',
                                                      ),
                                                ),
                                              ],
                                            ),

                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },

                                                child: const Text('Batal'),
                                              ),

                                              ElevatedButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('hutang')
                                                      .doc(docId)
                                                      .update({
                                                        'nama':
                                                            namaController.text,
                                                        'jumlah': int.parse(
                                                          jumlahController.text,
                                                        ),
                                                      });

                                                  Navigator.pop(context);
                                                },

                                                child: const Text('Simpan'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),

                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),

                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('hutang')
                                          .doc(docId)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
