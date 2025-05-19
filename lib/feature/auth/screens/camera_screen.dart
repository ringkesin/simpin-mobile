import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk SystemChrome
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart'; // Import ImagePicker
// Asumsi AppColors ada di theme.dart atau ganti dengan Colors.
import '../../../theme.dart'; // Sesuaikan path jika perlu

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
  bool _isPickingImage = false; // State untuk loading saat memilih dari galeri
  XFile? _capturedImageFile;

  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

  final Color primaryColor = AppColors.primaryLight;
  final Color accentColor = Colors.white;
  final Color secondaryButtonColor = Colors.white;
  final Color secondaryButtonTextColor = AppColors.primaryLight;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (widget.cameras.isEmpty) {
      print("No cameras available");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Tidak ada kamera yang ditemukan.")),
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
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize().catchError((e) {
      print("Error initializing camera: $e");
      if (mounted) {
        String errorMessage = "Gagal menginisialisasi kamera.";
        if (e is CameraException) {
          errorMessage =
              "Gagal menginisialisasi kamera: ${e.description ?? e.code}";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
    if (_isTakingPicture || !_controller.value.isInitialized || _isPickingImage)
      return;

    try {
      setState(() => _isTakingPicture = true);
      await _initializeControllerFuture;

      final XFile pictureFile = await _controller.takePicture();

      if (mounted) {
        setState(() {
          _capturedImageFile = pictureFile;
          // _isTakingPicture akan direset saat UI berubah ke preview foto atau _retakePhoto
        });
      }
    } catch (e) {
      print("Error taking picture: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: ${e.toString()}')),
        );
        setState(() => _isTakingPicture = false);
      }
    }
    // Tidak perlu setState _isTakingPicture = false di sini jika _capturedImageFile sudah di-set,
    // karena UI akan berganti ke mode preview.
  }

  Future<void> _pickImageFromGallery() async {
    if (_isPickingImage || _isTakingPicture)
      return; // Jangan proses jika sudah ada aksi lain

    try {
      setState(() => _isPickingImage = true);
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kualitas gambar bisa disesuaikan
        maxWidth: 1024, // Batasi ukuran gambar jika perlu
      );

      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _capturedImageFile = pickedFile;
            _isPickingImage = false;
          });
        }
      } else {
        // User membatalkan pemilihan gambar
        if (mounted) {
          setState(() => _isPickingImage = false);
        }
        print('Pemilihan gambar dari galeri dibatalkan.');
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: ${e.toString()}')),
        );
        setState(() => _isPickingImage = false);
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
      _isPickingImage = false;
    });
  }

  Widget _buildKtpOverlay(BuildContext context) {
    // ... (Implementasi _buildKtpOverlay tetap sama) ...
    final Size screenSize = MediaQuery.of(context).size;
    const double ktpAspectRatio = 1.586 / 1.0;
    final double overlayWidth = screenSize.width * 0.85;
    final double overlayHeight = overlayWidth / ktpAspectRatio;

    return Center(
      child: Container(
        width: overlayWidth,
        height: overlayHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 3.0),
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
    // ... (Implementasi _buildFullscreenCameraPreview tetap sama) ...
    if (!_controller.value.isInitialized ||
        _controller.value.previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.previewSize!.height,
        height: _controller.value.previewSize!.width,
        child: CameraPreview(_controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Bagian awal build method tetap sama) ...
    if (widget.cameras.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "Kamera Tidak Tersedia",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            "Tidak ada kamera yang ditemukan.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
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
                            const Text(
                              "Gagal memuat kamera.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
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
                    // --- UI untuk Tampilan Kamera Aktif ---
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // --- Tombol Kontrol Kamera di Bawah ---
                        Positioned(
                          bottom: screenPadding.bottom + 24.0,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Tombol Pilih dari Galeri
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed:
                                      _isTakingPicture || _isPickingImage
                                          ? null
                                          : _pickImageFromGallery,
                                  tooltip: 'Pilih dari Galeri',
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              // Tombol Ambil Foto (Shutter)
                              FloatingActionButton(
                                onPressed:
                                    _isTakingPicture || _isPickingImage
                                        ? null
                                        : _takePicture,
                                backgroundColor: Colors.white,
                                elevation: 4.0,
                                child:
                                    _isTakingPicture
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.grey,
                                            strokeWidth: 3,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.black,
                                          size: 32,
                                        ), // Icon lebih besar
                              ),
                              // Spacer atau tombol lain jika ada (misal, switch camera)
                              SizedBox(
                                width: 48 + 24,
                              ), // Lebar IconButton + padding agar simetris
                            ],
                          ),
                        ),
                        // Indikator loading untuk _isPickingImage (jika diperlukan, bisa di tengah layar)
                        if (_isPickingImage)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
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
                // Tampilan setelah foto diambil/dipilih (preview)
                // ... (Bagian preview foto dan tombol "Ambil Ulang" / "Pakai Foto" tetap sama) ...
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        screenPadding.top + 16,
                        16,
                        16,
                      ),
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
                          icon: Icon(
                            Icons.replay,
                            color: secondaryButtonTextColor,
                          ),
                          label: Text(
                            "Ambil Ulang",
                            style: TextStyle(
                              color: secondaryButtonTextColor,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: _retakePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryButtonColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.check_circle, color: accentColor),
                          label: Text(
                            "Pakai Foto",
                            style: TextStyle(fontSize: 16, color: accentColor),
                          ),
                          onPressed: _usePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
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
