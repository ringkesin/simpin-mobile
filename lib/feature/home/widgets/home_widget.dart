import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/shu/screens/shu.dart';
import 'package:kkba_mobile/feature/simulasi_pinjaman/screens/simulasi_pinjaman.dart';
import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart';
import '../../form_pinjaman/screens/form_pinjaman.dart';
import '../../../theme.dart';
import '../../../page_wrapper.dart';

// Widget: Header
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Welcome, Alwi Ghozali",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Widget: Banner
// Widget: Banner (OVO Cash Style)
class BannerWidget extends StatelessWidget {
  const BannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OVO Cash & Total Balance
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Tabungan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.visibility, color: Colors.white, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp 42.743',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.purple[800],
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '1.473 Points',
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.purple[800],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.add, 'Top Up'),
                _buildActionButton(Icons.swap_horiz, 'Transfer'),
                _buildActionButton(Icons.arrow_downward, 'Tarik Tunai'),
                _buildActionButton(Icons.history, 'History'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

// Widget: Categories
// Widget: Categories (MODIFIED childAspectRatio)
class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, dynamic>> categories = [
      {"icon": Icons.calculate, "label": "Simulasi Pinjaman"},
      {"icon": Icons.assignment, "label": "Pengajuan Pinjaman"},
      {"icon": Icons.info, "label": "Info SHU"},
      {"icon": Icons.person, "label": "Info Profile"},
      {"icon": Icons.savings, "label": "Info Tabungan"},
      {"icon": Icons.monetization_on, "label": "Pencairan Tabungan"},
    ]; // Data tidak diubah

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 4 : 3,
        // --- PERUBAHAN HANYA DI SINI ---
        // Mengurangi aspect ratio untuk memberi ruang tinggi lebih pada item,
        // mengatasi overflow saat teks label 2 baris.
        // Coba nilai lain (misal: 0.95, 0.9) jika 1.0 belum cukup.
        childAspectRatio: 1.0, // Diubah dari 1.2
        // --- AKHIR PERUBAHAN ---
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryItem(
          // Memanggil CategoryItem
          category: category,
          isDarkMode: isDarkMode,
          textTheme: textTheme,
          onTap: () {
            _navigateToPage(context, index);
          },
        );
      },
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    // Logika navigasi tidak diubah
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SimulasiPinjamanScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FormWizardScreen()),
        );
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ShuPage()));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FormWizardScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TabunganPage()),
        ); // Seharusnya ke Info Tabungan? -> TabunganPage()
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FormWizardScreen()),
        ); // Seharusnya ke Pencairan?
        break;
    }
  }
}

class CategoryItem extends StatelessWidget {
  const CategoryItem({
    Key? key,
    required this.category,
    required this.isDarkMode,
    required this.textTheme,
    required this.onTap,
  }) : super(key: key);

  final Map<String, dynamic> category;
  final bool isDarkMode;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? AppColors.primaryDark.withOpacity(0.1)
                  : AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.transparent,
              child: Icon(
                category['icon'],
                color:
                    isDarkMode ? AppColors.primaryLight : AppColors.primaryDark,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              // Added SizedBox to limit the width of the Text widget
              width: 80, // You can adjust this value as needed
              child: Text(
                category['label'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isDarkMode
                          ? AppColors.primaryTextLight
                          : AppColors.primaryTextLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget: Recent Transactions
class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = [
      {
        "title": "Potongan Angsuran",
        "date": "10 September 2023",
        "amount": "Rp. 500.000",
      },
      {
        "title": "Potongan Angsuran",
        "date": "10 Agustus 2023",
        "amount": "Rp. 500.000",
      },
      {
        "title": "Potongan Angsuran",
        "date": "10 Juli 2023",
        "amount": "Rp. 500.000",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Transactions",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        ...transactions.map((transaction) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.arrow_upward, color: Colors.red),
              title: Text(
                transaction['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(transaction['date']),
              trailing: Text(
                transaction['amount'],
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

// Widget: Bottom Navigation Bar
class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        // BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card),
          label: "Transactions",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header dengan background berbeda (gray)
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.alternateLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: const [
                          CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/images/profile.jpg',
                            ),
                            radius: 16,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Welcome, Alwi Ghozali',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Banner Widget
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BannerWidget(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content area dengan background putih
          SliverToBoxAdapter(
            child: PageWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  CategoriesWidget(),
                  const SizedBox(height: 0),
                  RecentTransactionsWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
