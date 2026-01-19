import 'package:fair_deals_app/screens/customer/CustomerProfileScreen.dart';
import 'package:fair_deals_app/screens/customer/customer_home.dart';
import 'package:fair_deals_app/screens/home/PricePredictionPage.dart';
import 'package:fair_deals_app/screens/home/category_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class customer_MainScreen extends StatefulWidget {
  final String userId;
  customer_MainScreen({required this.userId, required GlobalKey<NavigatorState> navigatorKey});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<customer_MainScreen> {
  int _selectedIndex = 1; // Start with Home selected (middle index)
  final PageController _pageController = PageController(initialPage: 1);
  final Color primaryColor = Color(0xFF384959);
  final Color inactiveColor = Colors.grey[600]!;

  // Using widget.userId inside the State class
  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = widget.userId; // Assign widget.userId to a variable for ease of access
  }

  // The pages list now references the userId dynamically
  final List<Widget> _pages = [];

  @override
  Widget build(BuildContext context) {
    _pages
      ..clear() // Clear previous pages before adding them to avoid duplication
      ..addAll([
        CategoryScreen(),
        customer_HomeScreen(userId: userId), // Passing the userId
        PricePredictionWizard(),
        CustomerProfileScreen(userId: userId), // Profile Page, passing userId correctly
      ]);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: _buildCustomIOSNavBar(),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildCustomIOSNavBar() {
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCustomNavItem(0, Icons.widgets_outlined, 'Categories'),
          _buildCustomNavItem(1, Icons.home_rounded, 'Home'),
          _buildCustomNavItem(2, Icons.insights_rounded, 'Predict'),
          _buildCustomNavItem(3, Icons.person_rounded, 'Profile'), // Profile Tab
        ],
      ),
    );
  }

  Widget _buildCustomNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? primaryColor : inactiveColor;
    final iconSize = isSelected ? 26.0 : 24.0;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          splashColor: primaryColor.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      icon,
                      size: iconSize,
                      color: color,
                    ),
                    if (isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

