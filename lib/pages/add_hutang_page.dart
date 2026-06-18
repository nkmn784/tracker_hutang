import 'package:flutter/material.dart';
import '../models/hutang_model.dart';

class AddHutangPage extends StatefulWidget {
  const AddHutangPage({super.key});

  @override
  State<AddHutangPage> createState() => _AddHutangPageState();
}

class _AddHutangPageState extends State<AddHutangPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  String jenis = 'Piutang';
  DateTime? jatuhTempo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── HEADER ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Transaksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Isi detail hutang atau piutang',
                            style: TextStyle(
                              color: Color(0x8DFFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // ── CARD FORM ──
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── JENIS TOGGLE ──
                        const Text(
                          'Jenis Transaksi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _JenisButton(
                                label: 'Orang Hutang ke Saya',
                                icon: Icons.arrow_downward_rounded,
                                value: 'Piutang',
                                selected: jenis == 'Piutang',
                                selectedColor: const Color(0xFF4ECDC4),
                                onTap: () => setState(() => jenis = 'Piutang'),
                              ),
                              _JenisButton(
                                label: 'Saya Hutang ke Orang',
                                icon: Icons.arrow_upward_rounded,
                                value: 'Hutang',
                                selected: jenis == 'Hutang',
                                selectedColor: const Color(0xFFFF6584),
                                onTap: () => setState(() => jenis = 'Hutang'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── NAMA ──
                        _buildLabel('Nama'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: namaController,
                          hint: 'Contoh: Budi Santoso',
                          icon: Icons.person_outline_rounded,
                        ),

                        const SizedBox(height: 20),

                        // ── JUMLAH ──
                        _buildLabel('Jumlah'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: jumlahController,
                          hint: 'Contoh: 500000',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          prefix: 'Rp ',
                        ),

                        const SizedBox(height: 20),

                        // ── JATUH TEMPO ──
                        _buildLabel('Jatuh Tempo'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF6C63FF),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => jatuhTempo = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: jatuhTempo != null
                                    ? const Color.fromARGB(255, 105, 97, 255)
                                    : Colors.grey.shade200,
                                width: jatuhTempo != null ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: jatuhTempo != null
                                      ? const Color(0xFF6C63FF)
                                      : Colors.grey.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  jatuhTempo == null
                                      ? 'Pilih tanggal jatuh tempo'
                                      : '${jatuhTempo!.day}/${jatuhTempo!.month}/${jatuhTempo!.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: jatuhTempo != null
                                        ? const Color(0xFF1A1A2E)
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                const Spacer(),
                                if (jatuhTempo != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => jatuhTempo = null),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey.shade400,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── TOMBOL SIMPAN ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (namaController.text.isEmpty ||
                                  jumlahController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nama dan jumlah wajib diisi',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              final data = HutangModel(
                                nama: namaController.text,
                                jumlah: int.parse(jumlahController.text),
                                jenis: jenis,
                                jatuhTempo: jatuhTempo,
                              );
                              Navigator.pop(context, data);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Simpan Transaksi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── TOMBOL BATAL ──
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          prefixText: prefix,
          prefixStyle: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ── WIDGET TOGGLE JENIS ──
class _JenisButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _JenisButton({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
