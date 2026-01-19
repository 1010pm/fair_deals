import 'package:fair_deals_app/screens/home/shop_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot product;

  ProductDetailScreen({required this.product});

  void _openWhatsApp(String phoneNumber) async {
    final url = 'https://wa.me/$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (kDebugMode) {
        debugPrint('Could not launch $url');
      }
    }
  }

  void _openLocation(String coordinates) async {
    if (coordinates.isEmpty) return;
    final url = "https://www.google.com/maps/search/?api=1&query=$coordinates";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (kDebugMode) {
        debugPrint('Could not launch $url');
      }
    }
  }

  double _calculateDiscountedPrice(double price, int discountPercentage) {
    return price - (price * discountPercentage / 100);
  }

  @override
  Widget build(BuildContext context) {
    double topPadding = MediaQuery.of(context).padding.top + 10;

    int discountPercentage = int.tryParse(product['offers'] ?? "0") ?? 0;
    double originalPrice = product['price'].toDouble();
    double discountedPrice = _calculateDiscountedPrice(originalPrice, discountPercentage);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 Back Arrow & Title in the Same Row
                Padding(
                  padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 🔙 Back Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                      ),
                      SizedBox(width: 16),
                      // 📌 Title
                      Expanded(
                        child: Text(
                          product['name'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 📸 Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product['imageUrl'] ?? 'https://via.placeholder.com/150',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                SizedBox(height: 16),

                // 🏷️ Product Details
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📌 Product Name
                      Text(
                        product['name'],
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),

                      SizedBox(height: 8),

                      // 📝 Product Description
                      Text(
                        product['description'] ?? 'No description available',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),

                      SizedBox(height: 12),

                      // 💲 Price with Offer
                      Row(
                        children: [
                          if (discountPercentage > 0)
                            Text(
                              '${originalPrice.toStringAsFixed(2)} OMR',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          SizedBox(width: 8),
                          Text(
                            '${discountedPrice.toStringAsFixed(2)} OMR',
                            style: TextStyle(fontSize: 20, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                          if (discountPercentage > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text('-$discountPercentage%', style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 12),

                      // 🛡️ Warranty Period
                      Text(
                        'Warranty: ${product['warrantyPeriod'] ?? 'No warranty'} year(s)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),

                      SizedBox(height: 20),
                      Divider(color: Colors.white54),

                      // 🏬 Shop Details Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🏪 Shop Name
                            Row(
                              children: [
                                Icon(Icons.store, color: Colors.white, size: 28),
                                SizedBox(width: 8),
                                Text(
                                  product['shopName'] ?? 'Unknown Shop',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // 📍 Store Location
                            ListTile(
                              leading: Icon(Icons.location_on, color: Colors.red),
                              title: Text('Store Location', style: TextStyle(color: Colors.white)),
                              subtitle: Text(product['shopLocation'] ?? 'No location provided', style: TextStyle(color: Colors.white70)),
                              trailing: Icon(Icons.arrow_forward, color: Colors.blue),
                              onTap: () => _openLocation(product['shopLocation'] ?? ''),
                            ),

                            // 📞 Contact Info
                            ListTile(
                              leading: Icon(Icons.phone, color: Colors.green),
                              title: Text('Contact Seller', style: TextStyle(color: Colors.white)),
                              subtitle: Text('Chat on WhatsApp', style: TextStyle(color: Colors.white70)),
                              trailing: Icon(Icons.chat, color: Colors.green),
                              onTap: () => _openWhatsApp(product['shopId'] ?? ''),
                            ),

                            // 🔗 View Shop Button
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShopDetailsScreen(shopId: product['shopId']),
                                  ),
                                );
                              },
                              icon: Icon(Icons.storefront),
                              label: Text('View Shop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amberAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
