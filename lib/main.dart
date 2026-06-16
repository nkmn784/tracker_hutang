import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/hutang_model.dart';
import 'pages/add_hutang_page.dart';
import 'dart:math';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //menghubungkan aplikasi flutter dengan firebase
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
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      ),
      home: LoginPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  String searchQuery = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ─── HELPER: referensi collection hutang milik user yang login ───
  CollectionReference get _hutangRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('hutang');
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      cekJatuhTempo();
    });
  }

  Future<void> cekJatuhTempo() async {
    // ─── DIUPDATE: pakai _hutangRef agar hanya data milik user sendiri ───
    final snapshot = await _hutangRef.get();

    int jumlahTerlambat = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['jatuhTempo'] != null && data['status'] != 'Lunas') {
        final dueDate = (data['jatuhTempo'] as Timestamp).toDate();

        if (dueDate.isBefore(DateTime.now())) {
          jumlahTerlambat++;
        }
      }
    }

    if (jumlahTerlambat > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠ Ada $jumlahTerlambat transaksi yang sudah jatuh tempo',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  //  FIREBASE LOGIC(menyimpan data hutang/piutang ke firestore)
  Future<void> simpanHutang(HutangModel data) async {
    // ─── DIUPDATE: pakai _hutangRef, uid tidak perlu disimpan lagi ───
    DocumentReference docRef = await _hutangRef.add({
      'nama': data.nama,
      'jumlah': data.jumlah,
      'jenis': data.jenis,
      'tanggal': DateTime.now(),

      // fitur cicilan
      'dibayar': 0,
      'sisa': data.jumlah,
      'status': 'Belum Lunas',

      'jatuhTempo': data.jatuhTempo,
    });

    print("ID data: ${docRef.id}");
  }

  //
  String _formatRupiah(int amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp $amount';
  }

  String _formatRupiahFull(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6584),
      const Color(0xFF43C6AC),
      const Color(0xFFFFA552),
      const Color(0xFF4ECDC4),
      const Color(0xFFFF6B6B),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showEditDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final namaController = TextEditingController(text: data['nama']);
    final jumlahController = TextEditingController(
      text: data['jumlah'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                namaController,
                'Nama',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                jumlahController,
                'Jumlah (Rp)',
                Icons.payments_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // ─── DIUPDATE: pakai _hutangRef ───
                        await _hutangRef.doc(docId).update({
                          'nama': namaController.text,
                          'jumlah': int.parse(jumlahController.text),
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            //HEADER
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tracker Hutang',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Kelola keuangan dengan bijak',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 8),

                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ─── DIUPDATE: pakai _hutangRef ───
                        // Mengambil data realtime dari Firebase Firestore
                        StreamBuilder<QuerySnapshot>(
                          stream: _hutangRef.snapshots(),
                          builder: (context, snapshot) {
                            // Variabel untuk menghitung total hutang dan piutang
                            int totalPiutang = 0;
                            int totalHutang = 0;

                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;

                                final sisa =
                                    (data['sisa'] ?? data['jumlah']) as num;

                                if (data['jenis'] == 'Piutang') {
                                  totalPiutang += sisa.toInt();
                                } else {
                                  totalHutang += sisa.toInt();
                                }
                              }
                            }

                            final selisih = totalPiutang - totalHutang;

                            return Column(
                              children: [
                                // Net balance card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo Bersih',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatRupiahFull(selisih.abs()),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            selisih >= 0
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            color: selisih >= 0
                                                ? const Color(0xFF4ECDC4)
                                                : const Color(0xFFFF6584),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            selisih >= 0
                                                ? 'Lebih banyak piutang'
                                                : 'Lebih banyak hutang',
                                            style: TextStyle(
                                              color: selisih >= 0
                                                  ? const Color(0xFF4ECDC4)
                                                  : const Color(0xFFFF6584),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Piutang & Hutang mini cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MiniSummaryCard(
                                        label: 'Total Piutang',
                                        amount: _formatRupiah(totalPiutang),
                                        icon: Icons.arrow_upward_rounded,
                                        color: const Color(0xFF4ECDC4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _MiniSummaryCard(
                                        label: 'Total Hutang',
                                        amount: _formatRupiah(totalHutang),
                                        icon: Icons.arrow_downward_rounded,
                                        color: const Color(0xFFFF6584),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── LIST SECTION ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    // ─── DIUPDATE: pakai _hutangRef ───
                    StreamBuilder<QuerySnapshot>(
                      stream: _hutangRef.snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count data',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },

                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                      hintText: 'Cari transaksi...',
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ─── DIUPDATE: pakai _hutangRef ───
            StreamBuilder<QuerySnapshot>(
              stream: _hutangRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                size: 40,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tambah data hutang atau piutang\npertamamu sekarang',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data =
                        docs[index].data()
                            as Map<String, dynamic>; //menambah filter data
                    final nama = data['nama'].toString().toLowerCase();

                    if (!nama.contains(searchQuery)) {
                      return const SizedBox();
                    }
                    final docId = docs[index].id;
                    final isPiutang = data['jenis'] == 'Piutang';
                    final dibayar = (data['dibayar'] ?? 0) as num;
                    final sisa = (data['sisa'] ?? data['jumlah']) as num;
                    final status = data['status'] ?? 'Belum Lunas';
                    final jatuhTempo = data['jatuhTempo'];

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        index == 0 ? 4 : 0,
                        20,
                        12,
                      ),
                      child: _TransactionCard(
                        nama: data['nama'],
                        jenis: data['jenis'],
                        jumlah: (data['jumlah'] as num).toInt(),
                        dibayar: dibayar.toInt(),
                        sisa: sisa.toInt(),
                        status: status,
                        jatuhTempo: jatuhTempo,
                        docId: docId,
                        isPiutang: isPiutang,
                        avatarColor: _avatarColor(data['nama']),
                        initials: _initials(data['nama']),
                        formatRupiah: _formatRupiahFull,
                        hutangRef: _hutangRef, // ─── DIUPDATE ───
                        onEdit: () => _showEditDialog(context, docId, data),
                        onDelete: () async {
                          // ─── DIUPDATE: pakai _hutangRef ───
                          await _hutangRef.doc(docId).delete();
                        },
                      ),
                    );
                  }, childCount: docs.length),
                );
              },
            ),

            //
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // Tombol untuk menambah data baru
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final hasil = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddHutangPage()),
          );
          if (hasil != null) {
            simpanHutang(hasil); //menyimpan input ke firebase
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Data',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _MiniSummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _MiniSummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String nama;
  final String jenis;
  final int jumlah;
  final int dibayar;
  final int sisa;
  final String status;
  final dynamic jatuhTempo;
  final String docId;
  final bool isPiutang;
  final Color avatarColor;
  final String initials;
  final String Function(int) formatRupiah;
  final CollectionReference hutangRef; // ─── DIUPDATE: tambah parameter ───
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.nama,
    required this.jenis,
    required this.jumlah,
    required this.dibayar,
    required this.sisa,
    required this.status,
    required this.jatuhTempo,
    required this.docId,
    required this.isPiutang,
    required this.avatarColor,
    required this.initials,
    required this.formatRupiah,
    required this.hutangRef, // ─── DIUPDATE: tambah ke constructor ───
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = isPiutang
        ? const Color(0xFF4ECDC4)
        : const Color(0xFFFF6584);
    final typeBg = isPiutang
        ? const Color(0xFF4ECDC4).withOpacity(0.08)
        : const Color(0xFFFF6584).withOpacity(0.08);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          jenis,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total : ${formatRupiah(jumlah)}',
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Dibayar : ${formatRupiah(dibayar)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            'Sisa : ${formatRupiah(sisa)}',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'Lunas'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Lunas'
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (jatuhTempo != null) ...[
                            const SizedBox(height: 6),

                            Text(
                              'Jatuh Tempo: ${jatuhTempo.toDate().day}/${jatuhTempo.toDate().month}/${jatuhTempo.toDate().year}',
                              style: TextStyle(
                                color:
                                    jatuhTempo.toDate().isBefore(DateTime.now())
                                    ? Colors.red
                                    : Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                _ActionButton(
                  icon: Icons.edit_rounded,
                  color: const Color(0xFF6C63FF),
                  onTap: onEdit,
                ),
                const SizedBox(height: 6),

                _ActionButton(
                  icon: Icons.payments_rounded,
                  color: Colors.green,
                  onTap: () {
                    final bayarController = TextEditingController();

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Bayar Cicilan'),

                          content: TextField(
                            controller: bayarController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan nominal',
                            ),
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
                                int nominal =
                                    int.tryParse(bayarController.text) ?? 0;

                                int dibayarBaru = dibayar + nominal;

                                int sisaBaru = jumlah - dibayarBaru;

                                String statusBaru = sisaBaru <= 0
                                    ? 'Lunas'
                                    : 'Belum Lunas';

                                // ─── DIUPDATE: pakai hutangRef ───
                                await hutangRef.doc(docId).update({
                                  'dibayar': dibayarBaru,
                                  'sisa': sisaBaru < 0 ? 0 : sisaBaru,
                                  'status': statusBaru,
                                });

                                await hutangRef
                                    .doc(docId)
                                    .collection('riwayat')
                                    .add({
                                      'nominal': nominal,
                                      'tanggal': DateTime.now(),
                                    });

                                Navigator.pop(context);
                              },
                              child: const Text('Bayar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                //tambah tombol riwayat
                const SizedBox(height: 6),

                _ActionButton(
                  icon: Icons.history_rounded,
                  color: Colors.blue,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Riwayat Cicilan'),

                          content: SizedBox(
                            width: 300,
                            height: 300,
                            child: StreamBuilder(
                              // ─── DIUPDATE: pakai hutangRef ───
                              stream: hutangRef
                                  .doc(docId)
                                  .collection('riwayat')
                                  .orderBy('tanggal', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final docs = snapshot.data!.docs;

                                if (docs.isEmpty) {
                                  return const Center(
                                    child: Text('Belum ada riwayat cicilan'),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data();

                                    return ListTile(
                                      leading: const Icon(
                                        Icons.payments,
                                        color: Colors.green,
                                      ),
                                      title: Text(
                                        formatRupiah(
                                          (data['nominal'] as num).toInt(),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                _ActionButton(
                  icon: Icons.delete_rounded,
                  color: const Color(0xFFFF6584),
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
