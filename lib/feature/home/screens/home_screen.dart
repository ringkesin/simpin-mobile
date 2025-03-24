import 'package:flutter/material.dart';
import '../widgets/home_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: const [
            CircleAvatar(
              backgroundImage: AssetImage(
                'assets/images/profile.jpg',
              ), // Replace with your profile image asset path
              radius: 16,
            ),
            SizedBox(width: 10),
            Text('Welcome, Alwi Ghozali'),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              BannerWidget(),
              SizedBox(height: 20),
              Text('Categories'),
              SizedBox(height: 20),

              CategoriesWidget(),
              SizedBox(height: 20),
              RecentTransactionsWidget(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
