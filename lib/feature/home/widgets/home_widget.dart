import 'package:flutter/material.dart';

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
class BannerWidget extends StatelessWidget {
  const BannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/images/banner.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.3), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ),
    );
  }
}

// Widget: Categories
class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final List<Map<String, dynamic>> categories = [
      {"icon": Icons.calculate, "label": "Simulasi Pinjaman"},
      {"icon": Icons.assignment, "label": "Pengajuan Pinjaman"},
      {"icon": Icons.info, "label": "Info SHU"},
      {"icon": Icons.person, "label": "Info Profile"},
      {"icon": Icons.savings, "label": "Info Tabungan"},
      {"icon": Icons.monetization_on, "label": "Pencairan Tabungan"},
      // {"icon": Icons.monetization_on, "label": "Pencairan Tabungan"},
      // {"icon": Icons.monetization_on, "label": "Pencairan Tabungan"},
    ];

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 4 : 3,
        childAspectRatio: 1,
        crossAxisSpacing: 5,
        mainAxisSpacing: 3,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: Icon(category['icon'], color: Colors.blueAccent, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              category['label'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
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
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
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
