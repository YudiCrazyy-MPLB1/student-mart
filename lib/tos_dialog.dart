import 'package:flutter/material.dart';

class TosDialog extends StatefulWidget {
  const TosDialog({super.key});

  @override
  State<TosDialog> createState() => _TosDialogState();
}

class _TosDialogState extends State<TosDialog> {
  final ScrollController _scrollController = ScrollController();

  bool _isBottomReached = false;
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();

    // Mengecek posisi scroll secara real-time
    _scrollController.addListener(() {
      // Jika posisi scroll sudah mencapai batas maksimal bawah (dengan toleransi 10 pixel)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 10) {
        if (!_isBottomReached) {
          setState(() {
            _isBottomReached = true;
          });
        }
      }
    });

    // Cek di awal: jika teks ternyata pendek dan tidak bisa di-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.position.maxScrollExtent <= 0) {
        setState(() {
          _isBottomReached = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        child: Column(
          children: [
            // AREA TEKS TOS (SCROLLABLE)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: const Text('''SYARAT DAN KETENTUAN PENITIPAN BARANG (KONSINYASI) STUDENT MART:

1. Sistem Konsinyasi (Bagi Hasil)
Pihak kantin, koperasi, atau pemasok yang menitipkan jualannya di aplikasi Student Mart dikenakan biaya sistem sebesar 1% dari total keuntungan bersih bulanan yang mereka dapatkan melalui Student Mart.

2. Siklus Pembayaran (Payouts)
Pencairan dana hasil penjualan dapat ditarik pada periode waktu yang telah disepakati melalui Admin Student Mart.

3. Risiko Kehilangan dan Kerusakan
Pihak Student Mart akan menjaga barang titipan dengan sebaik-baiknya. Namun, kerusakan akibat masa kedaluwarsa (expired) atau cacat dari pabrik tetap menjadi tanggung jawab pihak penitip.

4. Masa Retur (Pengembalian Barang)
Jika barang titipan tidak terjual dalam waktu yang telah ditentukan, pihak penitip wajib menarik/mengambil kembali barang tersebut dari etalase Student Mart.

5. Hak Kurasi Admin
Admin berhak menolak barang titipan jika dinilai tidak layak jual, melanggar aturan sekolah, atau harga dasar yang diajukan terlalu tinggi.

[Scroll terus ke bawah untuk menyetujui]
* Pastikan barang yang dititipkan dalam kondisi baik.
* Pihak Student Mart berhak mengubah syarat dan ketentuan ini dengan pemberitahuan sebelumnya.
* Dengan menyetujui persyaratan ini, Anda terikat secara sistem untuk mematuhi regulasi konsinyasi Student Mart SMK Negeri 4 Jember.
''', style: TextStyle(fontSize: 14, height: 1.6)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CHECKBOX PERSETUJUAN
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  activeColor: const Color.fromARGB(255, 27, 177, 164),
                  // Checkbox HANYA BISA DIKLIK JIKA sudah scroll sampai bawah
                  onChanged: _isBottomReached
                      ? (bool? value) {
                          setState(() {
                            _isChecked = value ?? false;
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: Text(
                    'Saya setuju dengan ketentuan di atas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isBottomReached ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            // PESAN PERINGATAN (Hilang kalau sudah scroll sampai bawah)
            if (!_isBottomReached)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, left: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '*Silakan baca (scroll) sampai akhir untuk menyetujui.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          // Tombol HANYA AKTIF JIKA checkbox sudah dicentang
          onPressed: _isChecked ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 27, 177, 164),
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Setuju & Lanjutkan',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
