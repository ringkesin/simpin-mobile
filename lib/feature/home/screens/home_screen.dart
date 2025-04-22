import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkba_mobile/page_wrapper.dart';
import 'package:kkba_mobile/theme.dart';
import '../widgets/home_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString(
      'nama',
    ); // Perubahan disini, dari 'name' menjadi 'nama'
    if (name != null) {
      setState(() {
        _userName = name;
      });
    } else {
      setState(() {
        _userName = 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                // Gunakan warna yang Anda sebut "hijau" di sini
                color: AppColors.alternateLight,
                // Menambahkan BorderRadius hanya di sudut bawah
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(
                    30.0,
                  ), // Atur radius sesuai keinginan
                  bottomRight: Radius.circular(
                    30.0,
                  ), // Atur radius sesuai keinginan
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundImage: AssetImage(
                              'assets/images/profile.jpg',
                            ),
                            radius: 16,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Welcome, $_userName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BannerWidget(),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                  const SizedBox(height: 20),
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
