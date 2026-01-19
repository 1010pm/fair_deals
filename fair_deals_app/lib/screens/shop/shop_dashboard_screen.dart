import 'package:fair_deals_app/screens/home/home_screen.dart';
import 'package:fair_deals_app/screens/shop/AddProductScreen.dart';
import 'package:fair_deals_app/screens/shop/SubscriptionScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'feedback_screen.dart';
import 'shop_manage_products_screen.dart';
import 'shop_settings_screen.dart';

class ShopDashboardScreen extends StatefulWidget {
  final String shopId;

  ShopDashboardScreen({required this.shopId, required GlobalKey<NavigatorState> navigatorKey});

  @override
  _ShopDashboardScreenState createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  String shopName = "";
  String shopEmail = "";
  String shopImageUrl = "";
  bool isLoading = true;
  String status = "";
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchShopData();
  }

  Future<void> _fetchShopData() async {
    try {
      final shopDoc = await FirebaseFirestore.instance.collection('users').doc(widget.shopId).get();
      if (shopDoc.exists) {
        setState(() {
          shopName = shopDoc.data()?['shop_name'] ?? "Unknown Shop";
          shopEmail = shopDoc.data()?['email'] ?? "shop@example.com";
          shopImageUrl = shopDoc.data()?['image_url'] ?? "";
          status = shopDoc.data()?['status'] ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

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
    List<Map<String, dynamic>> options = [
      {"icon": Icons.inventory, "label": "Manage Products", "screen": ShopManageProductsScreen(shopEmail: shopEmail)},
      {"icon": Icons.feedback, "label": "Feedback", "screen": FeedbackScreen(shopId: widget.shopId)},
      {"icon": Icons.add, "label": "Add Product", "screen": AddProductScreen(shopId: widget.shopId)},
      {"icon": Icons.subscriptions, "label": "Subscription", "screen": SubscriptionScreen(shopId: widget.shopId)},
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF384959), Color(0xFF88BDF2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Shop Info Section (Replacing AppBar)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
            child: Row(
              children: [
                if (shopImageUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: shopImageUrl.startsWith("data:image")
                        ? MemoryImage(base64Decode(shopImageUrl.split(',')[1]))
                        : NetworkImage(shopImageUrl) as ImageProvider,
                  ),

                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? "Loading..." : shopName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      status == "Active" ? "Shop Active" : "Inactive",
                      style: TextStyle(fontSize: 14, color: status == "Active" ? Colors.greenAccent : Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dashboard Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : status != "Active"
                  ? _buildInactiveShopMessage()
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.1,
                ),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  return _buildTile(
                    options[index]["icon"],
                    options[index]["label"],
                        () {
                      if (status != "Active") {
                        _showInactiveSnackbar();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => options[index]["screen"]),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveShopMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 80, color: Colors.redAccent),
          SizedBox(height: 16),
          Text(
            "Your shop is inactive.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Please contact the administrator to activate your shop.",
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Colors.white.withOpacity(0.2), // Glass effect
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2)
          ],
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showInactiveSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Your shop is inactive. Please activate it first.'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Switch screens based on index
        children: [
          HomeScreen(), // Home
          _buildDashboard(), // Dashboard
          ShopSettingsScreen(shopId: widget.shopId), // Settings
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFF88BDF2), // Light Sky Blue Background
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
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


}