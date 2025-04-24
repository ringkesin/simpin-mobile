import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) {
      // Handle case where no cameras are available
      print("No cameras available");
      // Optionally pop or show an error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return; // Prevent further initialization
    }
    _controller = CameraController(
      widget.cameras[0], // Gunakan kamera belakang
      ResolutionPreset.high, // Atur resolusi
      enableAudio: false, // Tidak perlu audio untuk foto KTP
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return; // Hindari multiple taps

    try {
      setState(() {
        _isTakingPicture = true;
      });
      await _initializeControllerFuture; // Pastikan controller siap

      // Buat path unik untuk menyimpan file
      final directory = await getTemporaryDirectory();
      final String filePath = join(
        directory.path,
        '${DateTime.now().millisecondsSinceEpoch}_ktp.jpg',
      );

      // Ambil gambar
      XFile pictureFile = await _controller.takePicture();

      // Kembalikan file gambar ke halaman sebelumnya
      if (mounted) {
        Navigator.pop(context, pictureFile);
      }
    } catch (e) {
      print("Error taking picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where cameras list was empty during initState
    if (widget.cameras.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Kamera Tidak Tersedia")),
        body: Center(child: Text("Tidak ada kamera yang ditemukan.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang hitam untuk kamera
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Jika future selesai, tampilkan preview
            return Stack(
              alignment: Alignment.center,
              children: [
                // Bungkus CameraPreview dengan AspectRatio sesuai kamera
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                ),
                // Tambahkan Overlay KTP
                _buildKtpOverlay(context),
                // Tombol Ambil Gambar
                Positioned(
                  bottom: 30.0,
                  child: FloatingActionButton(
                    onPressed: _isTakingPicture ? null : _takePicture,
                    backgroundColor: Colors.white,
                    child:
                        _isTakingPicture
                            ? CircularProgressIndicator(color: Colors.grey)
                            : Icon(Icons.camera_alt, color: Colors.black),
                  ),
                ),
                // Tombol Kembali (opsional, jika ingin tombol back di layar)
                Positioned(
                  top: 40.0,
                  left: 20.0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            );
          } else {
            // Jika masih loading, tampilkan indicator
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Widget untuk menggambar overlay KTP
  Widget _buildKtpOverlay(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    // Estimasi rasio KTP (85.6mm x 53.98mm ≈ 1.586)
    const double ktpAspectRatio = 1.586 / 1.0;
    // Tentukan lebar overlay (misal 85% dari lebar layar)
    final double overlayWidth = screenSize.width * 0.85;
    // Hitung tinggi overlay berdasarkan rasio
    final double overlayHeight = overlayWidth / ktpAspectRatio;

    return Center(
      child: Container(
        width: overlayWidth,
        height: overlayHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(
              0.8,
            ), // Warna border putih semi-transparan
            width: 3.0, // Ketebalan border
          ),
          borderRadius: BorderRadius.circular(
            8.0,
          ), // Sedikit lengkungan di sudut
          // Efek bayangan untuk menonjolkan area KTP (opsional)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 10,
              offset: Offset(0, 0),
            ),
          ],
          // Anda bisa membuat bagian tengah transparan dan luar gelap
          // menggunakan CustomPainter jika ingin lebih presisi,
          // tapi border sederhana ini sudah cukup untuk panduan.
        ),
        // Tambahkan teks panduan (opsional)
        child: Center(
          child: Text(
            "Posisikan KTP di dalam area ini",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              backgroundColor: Colors.black.withOpacity(
                0.5,
              ), // background agar mudah terbaca
            ),
          ),
        ),
      ),
    );
  }
}
