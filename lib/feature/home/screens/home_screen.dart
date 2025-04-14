import 'package:flutter/material.dart';
import 'package:kkba_mobile/page_wrapper.dart';
import 'package:kkba_mobile/theme.dart';
import '../widgets/home_widget.dart';
// import '../../../theme.dart';

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
              color: AppColors.alternateLight,
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
                  SizedBox(height: 30),

                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 20),
                  CategoriesWidget(),
                  SizedBox(height: 0),
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
