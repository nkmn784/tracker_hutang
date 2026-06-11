class HutangModel {
  final String nama;
  final int jumlah;
  final String jenis;
  final DateTime? jatuhTempo;

  HutangModel({
    required this.nama,
    required this.jumlah,
    required this.jenis,
    this.jatuhTempo,
  });
}
