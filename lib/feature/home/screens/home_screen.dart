import 'package:flutter/material.dart';
import 'package:kkba_mobile/page_wrapper.dart';
import '../widgets/home_widget.dart';
import '../../../theme.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ), // Padding kiri & kanan
          child: Row(
            children: const [
              CircleAvatar(
                backgroundImage: AssetImage('assets/images/profile.jpg'),
                radius: 16,
              ),
              SizedBox(width: 10),
              Text('Welcome, Alwi Ghozali'),
            ],
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: PageWrapper(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BannerWidget(),
                SizedBox(height: 20),
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 20),

                CategoriesWidget(),
                SizedBox(height: 20),
                RecentTransactionsWidget(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
