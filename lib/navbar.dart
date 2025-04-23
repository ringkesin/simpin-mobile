import 'package:flutter/material.dart';
// Import halaman-halaman Anda
import 'feature/home/screens/home_screen.dart';
import 'feature/tabungan/screens/tabungan.dart';
import 'feature/shu/screens/shu.dart';
import 'feature/form_pinjaman/screens/form_pinjaman.dart'; // Asumsi ada halaman ini atau halaman lain

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; // Indeks halaman yang aktif

  // Daftar halaman yang akan dinavigasi
  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Halaman Beranda Anda
    TabunganPage(), // Halaman Tabungan Anda
    ShuPage(), // Halaman SHU Anda
    FormWizardScreen(), // Halaman Pinjaman/Formulir Anda
    // Tambahkan halaman lain jika perlu, misal Profil
    // ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar bisa ditambahkan di sini jika seragam untuk semua halaman,
      // atau di masing-masing halaman jika berbeda.
      // appBar: AppBar(
      //   title: const Text('Simpin Mobile'),
      // ),
      body: Center(
        // Menampilkan halaman sesuai indeks yang dipilih
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        indicatorColor:
            Theme.of(
              context,
            ).colorScheme.primaryContainer, // Sesuaikan dengan tema Anda
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.savings),
            icon: Icon(Icons.savings_outlined),
            label: 'Tabungan',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.pie_chart),
            icon: Icon(Icons.pie_chart_outline),
            label: 'SHU',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.request_quote,
            ), // Ganti ikon sesuai kebutuhan
            icon: Icon(Icons.request_quote_outlined),
            label: 'Pinjaman', // Ganti label sesuai kebutuhan
          ),
          // Tambahkan destinasi lain jika perlu
          // NavigationDestination(
          //   selectedIcon: Icon(Icons.person),
          //   icon: Icon(Icons.person_outline),
          //   label: 'Profil',
          // ),
        ],
      ),
    );
  }
}
