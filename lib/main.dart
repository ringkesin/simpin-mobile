import 'package:flutter/material.dart';
import 'package:kkba_mobile/navbar.dart';
import './feature/home/screens/home_screen.dart';
import './feature/auth/screens/login.dart';
import './theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true; // Tambahkan di main() saat debug
  await dotenv.load(); // Memuat file .env
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        textTheme: AppTheme.textThemeLight, // Gunakan tema terang
        primaryColor:
            AppColors.primaryLight, // Sesuaikan dengan warna utama aplikasi
        scaffoldBackgroundColor: Colors.white,
      ),
      // darkTheme: ThemeData(
      //   textTheme: AppTheme.textThemeDark, // Gunakan tema gelap
      //   primaryColor: AppColors.primaryDark,
      //   scaffoldBackgroundColor: Colors.black,
      // ),
      // themeMode: ThemeMode.system, // Gunakan mode tema berdasarkan sistem
      initialRoute: '/', // Rute awal
      routes: {
        '/': (context) => const LoginPage(), // Halaman login sebagai default
        '/home': (context) => MainWrapper(), // Definisi rute home
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
