import 'package:flutter/material.dart';

class TosReadDialog extends StatelessWidget {
  const TosReadDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Syarat & Ketentuan Konsinyasi',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: SizedBox(
        width: 500, // Lebar maksimal pop-up untuk tampilan web
        height: 400, // Tinggi area teks yang bisa di-scroll
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: const Text(
                '''SYARAT DAN KETENTUAN PENITIPAN BARANG (KONSINYASI) STUDENT MART:

1. Sistem Konsinyasi
Pemasok menitipkan barang untuk dijualkan oleh Student Mart. Atas jasa penjualan dan penggunaan platform ini, Student Mart berhak mendapatkan biaya sistem sebesar 2% dari harga jual yang akan dipotong langsung dari total penjualan.

2. Siklus Pembayaran (Payouts)
Pencairan dana hasil penjualan dapat ditarik pada periode waktu yang telah disepakati melalui Admin Student Mart.

3. Risiko Kehilangan dan Kerusakan
Pihak Student Mart akan menjaga barang titipan dengan sebaik-baiknya. Namun, kerusakan akibat masa kedaluwarsa (expired) atau cacat dari pabrik tetap menjadi tanggung jawab pihak penitip.

4. Masa Retur (Pengembalian Barang)
Jika barang titipan tidak terjual dalam waktu yang telah ditentukan, pihak penitip wajib menarik/mengambil kembali barang tersebut dari etalase Student Mart.

5. Hak Kurasi Admin
Admin berhak menolak barang titipan jika dinilai tidak layak jual, melanggar aturan sekolah, atau harga dasar yang diajukan terlalu tinggi.

* Pastikan barang yang dititipkan dalam kondisi baik.
* Pihak Student Mart berhak mengubah syarat dan ketentuan ini dengan pemberitahuan sebelumnya.
* Dengan menyetujui persyaratan ini, Anda terikat secara sistem untuk mematuhi regulasi konsinyasi Student Mart SMK Negeri 4 Jember.''',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Tutup dialog
          },
          child: const Text(
            'Tutup',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
