import 'package:fair_deals_app/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import '../shop/shop_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String shopId;
  AdminDashboardScreen({required this.shopId, required GlobalKey<NavigatorState> navigatorKey});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final String adminImageUrl = "https://img.lovepik.com/element/45004/4952.png_860.png";

  final List<DashboardTileData> dashboardTiles = [
    DashboardTileData(icon: Icons.store, label: 'Manage Shops', routeName: '/manage_shops'),
    DashboardTileData(icon: Icons.inventory, label: 'View Reports', routeName: '/view_reports'),
    DashboardTileData(icon: Icons.feedback, label: 'Feedback Details', routeName: '/feedback_details'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _screens() {
    return [
      HomeScreen(),
      _buildDashboard(),
      ShopSettingsScreen(shopId: widget.shopId),
    ];
  }

  Widget _buildDashboard() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2,
        ),
        itemCount: dashboardTiles.length,
        itemBuilder: (context, index) {
          return DashboardTile(
            icon: dashboardTiles[index].icon,
            label: dashboardTiles[index].label,
            onTap: () {
              Navigator.pushNamed(context, dashboardTiles[index].routeName);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF384959), // Dark Blue-Gray (Top)
              Color(0xFF88BDF2), // Light Sky Blue (Bottom)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFF88BDF2), // Light Sky Blue Background
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home, color: Color(0xFF384959)), label: 'Home'), // Dark Blue-Gray Icons
            BottomNavigationBarItem(icon: Icon(Icons.dashboard, color: Color(0xFF384959)), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.settings, color: Color(0xFF384959)), label: 'Settings'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Text('Admin Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundImage: NetworkImage(adminImageUrl),
        ),
      ),
    );
  }
}

class DashboardTileData {
  final IconData icon;
  final String label;
  final String routeName;
  DashboardTileData({required this.icon, required this.label, required this.routeName});
}

class DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DashboardTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.white.withOpacity(0.4),
      child: Card(
        elevation: 10.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Color(0xFF6AB9A7), // Soft Green for Body Items
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0, color: Colors.white),
              SizedBox(height: 16.0),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}