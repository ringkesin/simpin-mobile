import 'package:flutter/material.dart';
import 'package:kkba_mobile/feature/tabungan/screens/tabungan.dart';
import '../../form_pinjaman/screens/form_pinjaman.dart';
import '../../../theme.dart';

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
                      'OVO Cash',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.visibility, color: Colors.white, size: 18),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp 42.743',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
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
                          SizedBox(width: 4),
                          Text(
                            '1.473 Points',
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
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
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

// Widget: Categories
class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;

    final isDarkMode = brightness == Brightness.dark;

    final List<Map<String, dynamic>> categories = [
      {"icon": Icons.calculate, "label": "Simulasi Pinjaman"},
      {"icon": Icons.assignment, "label": "Pengajuan Pinjaman"},
      {"icon": Icons.info, "label": "Info SHU"},
      {"icon": Icons.person, "label": "Info Profile"},
      {"icon": Icons.savings, "label": "Info Tabungan"},
      {"icon": Icons.monetization_on, "label": "Pencairan Tabungan"},
    ];

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 4 : 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        void _navigateToPage() {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TabunganPage()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormWizardScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormWizardScreen()),
              );
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
                MaterialPageRoute(builder: (_) => FormWizardScreen()),
              );
              break;
            case 5:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FormWizardScreen()),
              );
              break;
          }
        }

        return GestureDetector(
          onTap: _navigateToPage,
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    isDarkMode
                        ? AppColors.primaryDark.withOpacity(0.1)
                        : AppColors.primaryLight.withOpacity(0.1),
                child: Icon(
                  category['icon'],
                  color:
                      isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category['label'],
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color:
                      isDarkMode
                          ? AppColors.primaryTextDark
                          : AppColors.primaryTextLight,
                ),
              ),
            ],
          ),
        );
      },
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
