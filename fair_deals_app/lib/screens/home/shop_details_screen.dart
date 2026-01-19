import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopDetailsScreen extends StatefulWidget {
  final String shopId;

  ShopDetailsScreen({required this.shopId});

  @override
  _ShopDetailsScreenState createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  Position? _currentPosition;
  double? _distance;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();
    if (permission.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  double _calculateDistance(String shopLocation) {
    if (_currentPosition == null || shopLocation.isEmpty) return 0.0;

    List<String> coordinates = shopLocation.split(',');
    if (coordinates.length != 2) return 0.0;

    double? lat = double.tryParse(coordinates[0].trim());
    double? lng = double.tryParse(coordinates[1].trim());

    if (lat == null || lng == null) return 0.0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000; // Convert to kilometers
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

  @override
  Widget build(BuildContext context) {
    double topPadding = MediaQuery
        .of(context)
        .padding
        .top + 10;

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
                        child: Icon(
                            Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                    ),
                    SizedBox(width: 16),
                    // 📌 Title
                    Expanded(
                      child: Text(
                        "Shop Details",
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

              // 🔎 Fetching Shop Details
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(
                      widget.shopId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                          child: CircularProgressIndicator(color: Colors
                              .white));
                    }

                    final shopData = snapshot.data!.data() as Map<
                        String,
                        dynamic>;
                    final shopLocation = shopData['location'] ?? '';

                    // Calculate distance when location is available
                    if (_currentPosition != null) {
                      _distance = _calculateDistance(shopLocation);
                    }

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📸 Shop Image
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                shopData['image_url'] ??
                                    'https://via.placeholder.com/150',
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // 🏪 Shop Name
                          Center(
                            child: Text(
                              shopData['shop_name'] ?? 'Unknown Shop',
                              style: TextStyle(fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 8),

                          // 📍 Shop Location
                          Center(
                            child: Text(
                              shopLocation.isNotEmpty
                                  ? shopLocation
                                  : 'No location available',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70),
                            ),
                          ),
                          SizedBox(height: 10),

                          // 📏 Distance (if available)
                          if (_distance != null)
                            Center(
                              child: Text(
                                'Distance: ${_distance!.toStringAsFixed(2)} km',
                                style: TextStyle(fontSize: 16,
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          SizedBox(height: 20),

                          // ℹ️ Shop Information
                          _buildInfoSection("Shop Information", [
                            _buildInfoRow('Commercial Registration:',
                                shopData['commercial_reg']),
                            _buildInfoRow(
                                'Contact Info:', shopData['contact_info']),
                            _buildInfoRow('Email:', shopData['email']),
                          ]),

                          SizedBox(height: 20),

                          // 🌍 View Location Button
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _openLocation(shopLocation),
                              icon: Icon(
                                  Icons.location_on, color: Colors.white),
                              label: Text('View Location on Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),

                          SizedBox(height: 20),

                          // 🛒 Products Section
                          _buildInfoSection("Products", []),

                          SizedBox(height: 10),

                          // 📦 Fetch Products
                          _buildProductList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ℹ️ Section Header
  Widget _buildInfoSection(String title, List<Widget> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 10),
        Column(children: content),
      ],
    );
  }

// 📌 Info Row
  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title ',
            style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70),
          ),
          Expanded(
            child: Text(
              value ?? 'Not available',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

// 📦 Product List
  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where(
          'shopId', isEqualTo: widget.shopId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return Center(
            child: Text(
              "No products available",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final product = products[index];

            // Parse price & discount safely
            final double originalPrice = double.tryParse(
                product['price']?.toString() ?? '0') ?? 0.0;
            final double discount = double.tryParse(
                product['offers']?.toString() ?? '0') ?? 0.0;
            final double discountedPrice = originalPrice -
                (originalPrice * (discount / 100));
            final bool hasDiscount = discount > 0 && discount < 100;

            return _buildProductCard(
                product, originalPrice, discountedPrice, hasDiscount);
          },
        );
      },
    );
  }

// 📦 Product Card
  Widget _buildProductCard(DocumentSnapshot product, double originalPrice,
      double discountedPrice, bool hasDiscount) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product['imageUrl'] ?? 'https://via.placeholder.com/70',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
                if (hasDiscount)
                  Text(
                    '${originalPrice.toStringAsFixed(2)} OMR',
                    style: TextStyle(decoration: TextDecoration.lineThrough,
                        color: Colors.red,
                        fontSize: 14),
                  ),
                Text(
                  '${discountedPrice.toStringAsFixed(2)} OMR',
                  style: TextStyle(color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}