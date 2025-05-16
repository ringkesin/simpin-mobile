import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk SystemChrome
import 'package:camera/camera.dart';

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
  XFile? _capturedImageFile;

  // Definisikan warna utama Anda di sini agar mudah diubah jika perlu
  final Color primaryColor = Colors.green; // Warna hijau tema Anda
  final Color accentColor =
      Colors.white; // Warna aksen (misal untuk teks di atas tombol hijau)
  final Color secondaryButtonColor =
      Colors.white; // Warna untuk tombol sekunder
  final Color secondaryButtonTextColor =
      Colors.green; // Warna teks untuk tombol sekunder

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (widget.cameras.isEmpty) {
      print("No cameras available");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Tidak ada kamera yang ditemukan.")),
          );
          Navigator.pop(context);
        }
      });
      return;
    }
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize().catchError((e) {
      print("Error initializing camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal menginisialisasi kamera: ${e.description ?? e.toString()}",
            ),
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture || !_controller.value.isInitialized) return;

    try {
      setState(() {
        _isTakingPicture = true;
      });
      await _initializeControllerFuture;
      XFile pictureFile = await _controller.takePicture();
      setState(() {
        _capturedImageFile = pictureFile;
      });
    } catch (e) {
      print("Error taking picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  void _usePhoto() {
    if (_capturedImageFile != null && mounted) {
      Navigator.pop(context, _capturedImageFile);
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImageFile = null;
      _isTakingPicture = false;
    });
  }

  Widget _buildKtpOverlay(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    const double ktpAspectRatio = 1.586 / 1.0;
    final double overlayWidth = screenSize.width * 0.85;
    final double overlayHeight = overlayWidth / ktpAspectRatio;

    return Center(
      child: Container(
        width: overlayWidth,
        height: overlayHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(
              0.8,
            ), // Border overlay KTP tetap putih
            width: 3.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Posisikan KTP di dalam area ini",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenCameraPreview() {
    if (!_controller.value.isInitialized) {
      return Container(color: Colors.black);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: CameraPreview(_controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      // Ini akan jarang terjadi jika pengecekan di initState bekerja,
      // tapi sebagai fallback.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return Scaffold(body: Center(child: Text("Kamera tidak tersedia.")));
    }

    final screenPadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _capturedImageFile == null
              ? FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError || !_controller.value.isInitialized) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Gagal memuat kamera.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Kembali",
                                style: TextStyle(color: accentColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Positioned.fill(child: _buildFullscreenCameraPreview()),
                        _buildKtpOverlay(context),
                        Positioned(
                          top: screenPadding.top + 12.0,
                          left: screenPadding.left + 12.0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: screenPadding.bottom + 24.0,
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment: Alignment.center,
                            child: FloatingActionButton(
                              onPressed: _isTakingPicture ? null : _takePicture,
                              backgroundColor:
                                  Colors.white, // Tombol capture tetap putih
                              elevation: 4.0,
                              child:
                                  _isTakingPicture
                                      ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.grey,
                                          strokeWidth: 3,
                                        ),
                                      )
                                      : Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 28,
                                      ), // Icon hitam
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }
                },
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                      child: Image.file(
                        File(_capturedImageFile!.path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.85),
                    padding: EdgeInsets.only(
                      top: 20.0,
                      bottom: screenPadding.bottom + 20.0,
                      left: 20.0,
                      right: 20.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          // Mengganti OutlinedButton menjadi ElevatedButton
                          icon: Icon(
                            Icons.replay,
                            color: secondaryButtonTextColor,
                          ), // Warna icon hijau
                          label: Text(
                            "Ambil Ulang",
                            style: TextStyle(
                              color: secondaryButtonTextColor,
                              fontSize: 16,
                            ),
                          ), // Warna teks hijau
                          onPressed: _retakePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                secondaryButtonColor, // Latar putih
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(
                              color: primaryColor,
                              width: 1.5,
                            ), // Border hijau (opsional)
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(
                            Icons.check_circle,
                            color: accentColor,
                          ), // Icon putih
                          label: Text(
                            "Pakai Foto",
                            style: TextStyle(fontSize: 16, color: accentColor),
                          ), // Teks putih
                          onPressed: _usePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, // Latar hijau
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
