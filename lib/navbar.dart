import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/profile/screens/profile.dart';
import '../theme.dart'; // <-- Import AppTheme Anda

// Import halaman-halaman Anda
import 'feature/home/screens/home_screen.dart';
import 'feature/tabungan/screens/tabungan.dart';
import 'feature/shu/screens/shu.dart';
import 'feature/form_pinjaman/screens/form_pinjaman.dart'; // Sesuaikan path jika perlu

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0; // Indeks halaman yang aktif

  // Daftar halaman yang akan dinavigasi (pastikan nama class benar)
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Halaman Beranda Anda
    TabunganPage(), // Halaman Tabungan Anda
    ShuPage(), // Halaman SHU Anda
    ProfileScreen(), // Halaman Pinjaman/Formulir Anda
    // Tambahkan halaman lain jika perlu
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil warna dari AppTheme (asumsi menggunakan light theme)
    // Anda mungkin perlu logika tambahan jika mendukung dark mode di sini
    final Color navBarBackgroundColor =
        AppColors.secondaryLight; // Warna background NavBar (Putih)
    final Color shadowColor = AppColors.secondaryTextLight.withOpacity(
      0.3,
    ); // Warna shadow (Abu-abu transparan)
    final Color indicatorColor = AppColors.primaryLight.withOpacity(
      0.15,
    ); // Warna indikator item terpilih
    final Color selectedItemColor =
        AppColors.primaryLight; // Warna ikon/label terpilih (Hijau)
    final Color unselectedItemColor =
        AppColors
            .secondaryTextLight; // Warna ikon/label tidak terpilih (Abu-abu)
    final TextStyle? labelStyle =
        AppTheme.textThemeLight.labelSmall; // Style teks label

    return Scaffold(
      // Biarkan AppBar di masing-masing halaman jika berbeda
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // --- Perubahan untuk Floating Navigation Bar ---
      bottomNavigationBar: Container(
        // Margin untuk efek mengambang
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 20),
        decoration: BoxDecoration(
          color: navBarBackgroundColor, // Background putih untuk container
          borderRadius: BorderRadius.circular(30), // Sudut melengkung
          boxShadow: [
            BoxShadow(
              color: shadowColor, // Warna shadow
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4), // Posisi shadow
            ),
          ],
        ),
        // Penting: Clip agar NavigationBar mengikuti lengkungan container
        clipBehavior: Clip.antiAlias,
        child: NavigationBar(
          onDestinationSelected: _onItemTapped,
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.transparent, // NavBar dibuat transparan
          indicatorColor: indicatorColor, // Warna indicator dari theme
          elevation:
              0, // Hilangkan shadow default NavBar, sudah dihandle Container
          height: 65, // Sesuaikan tinggi jika perlu
          labelBehavior:
              NavigationDestinationLabelBehavior
                  .alwaysShow, // Atau .alwaysHide jika hanya ikon
          // destinations di-styling menggunakan NavigationBarThemeData di AppTheme
          destinations: <NavigationDestination>[
            NavigationDestination(
              // Gunakan warna dari theme, tapi bisa override jika perlu
              selectedIcon: Icon(Icons.home, color: selectedItemColor),
              icon: Icon(Icons.home_outlined, color: unselectedItemColor),
              label: 'Beranda',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.savings, color: selectedItemColor),
              icon: Icon(Icons.savings_outlined, color: unselectedItemColor),
              label: 'Tabungan',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.pie_chart, color: selectedItemColor),
              icon: Icon(
                Icons.pie_chart_outline_outlined,
                color: unselectedItemColor,
              ), // pastikan icon benar
              label: 'SHU',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.person, color: selectedItemColor),
              icon: Icon(Icons.person, color: unselectedItemColor),
              label: 'Profile',
            ),
          ],
          // Terapkan style label dari theme
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return labelStyle?.copyWith(
                color: selectedItemColor,
                fontWeight: FontWeight.bold,
              );
            }
            return labelStyle?.copyWith(color: unselectedItemColor);
          }),
        ),
      ),
      // --- Akhir Perubahan ---
    );
  }
}
