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
      appBar: AppBar(title: const Text('Tambah Hutang')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: namaController,

              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: 'Jumlah Hutang',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: jenis,

              items: const [
                DropdownMenuItem(
                  value: 'Piutang',
                  child: Text('Orang Hutang ke Saya'),
                ),

                DropdownMenuItem(
                  value: 'Hutang',
                  child: Text('Saya Hutang ke Orang'),
                ),
              ],

              onChanged: (value) {
                setState(() {
                  jenis = value!;
                });
              },

              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(
                jatuhTempo == null
                    ? 'Pilih Jatuh Tempo'
                    : '${jatuhTempo!.day}/${jatuhTempo!.month}/${jatuhTempo!.year}',
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  setState(() {
                    jatuhTempo = picked;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: () {
                  final data = HutangModel(
                    nama: namaController.text,

                    jumlah: int.parse(jumlahController.text),

                    jenis: jenis,

                    jatuhTempo: jatuhTempo,
                  );

                  Navigator.pop(context, data);
                },

                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
