import 'package:fair_deals_app/screens/home/CategoryDetailScreen.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'title': 'Smart Phones', 'icon': Icons.smartphone, 'color': Colors.blue},
    {'title': 'Smart Watches', 'icon': Icons.watch, 'color': Colors.amber},
    {'title': 'Tablets', 'icon': Icons.tablet, 'color': Colors.purple},
    {'title': 'Laptops', 'icon': Icons.laptop, 'color': Colors.teal},
    {'title': 'Smart Home Devices', 'icon': Icons.home, 'color': Colors.orange},
    {'title': 'Wireless Earbuds', 'icon': Icons.headset, 'color': Colors.green},
    {'title': 'Gaming Consoles', 'icon': Icons.videogame_asset, 'color': Colors.red},
    {'title': 'VR & AR Devices', 'icon': Icons.vrpano, 'color': Colors.deepPurple},
    {'title': 'Wearable Tech', 'icon': Icons.accessibility, 'color': Colors.cyan},
    {'title': 'Smart Assistants', 'icon': Icons.speaker, 'color': Colors.blueGrey},
  ];

  @override
  Widget build(BuildContext context) {
    double topPadding = MediaQuery.of(context).padding.top + 10; // Dynamic top padding

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)], // Gradient theme
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Title Row
              Padding(
                padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
                child: Row(
                  children: [

                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Categories",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis, // Prevents text overflow
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // 📦 Responsive Category Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: BouncingScrollPhysics(), // ✅ Smooth scrolling
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // 📱 Responsive columns
                      childAspectRatio: 3 / 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (ctx, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryDetailScreen(categories[index]['title']),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [categories[index]['color'], Colors.black.withOpacity(0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(categories[index]['icon'], size: 40, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                categories[index]['title'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Slightly smaller for better fitting
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
