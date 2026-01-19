import 'dart:convert';
import 'package:fair_deals_app/screens/home/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;
  CategoryDetailScreen(this.category);

  @override
  _CategoryDetailScreenState createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await ph.Permission.location.request();
      if (permission.isGranted) {
        await _getCurrentLocation();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() => _currentPosition = position);
  }

  double _calculateDistance(String shopLocation) {
    if (_currentPosition == null) return 0.0;

    final coordinates = shopLocation.split(',');
    if (coordinates.length != 2) return 0.0;

    final lat = double.tryParse(coordinates[0].trim());
    final lng = double.tryParse(coordinates[1].trim());
    if (lat == null || lng == null) return 0.0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000;
  }

  Future<Map<String, dynamic>> _fetchPrediction(
      String product,
      double price,
      double distance,
      ) async {
    const apiUrl = 'http://10.0.2.2:8000/predict_deal';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': [
            {
              'product': product,
              'price': price,
              'distance': distance,
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          return data['predictions'][0];
        }
      }
      return {'prediction': 'Unknown', 'error': 'Invalid response'};
    } catch (e) {
      return {'prediction': 'Unknown', 'error': e.toString()};
    }
  }

  Future<bool> _hasActiveSubscription(String shopId) async {
    try {
      final shopDoc = await _db.collection('users').doc(shopId).get();
      return shopDoc.exists && (shopDoc['status'] ?? 'Inactive') == 'Active';
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF384959),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : _buildProductStream(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: 6, // Number of shimmer placeholders
        itemBuilder: (_, index) => _buildShimmerProductCard(),
      ),
    );
  }

  Widget _buildShimmerProductCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Shimmer Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: 12),

            // Shimmer Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // Shimmer Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 60,
                  height: 16,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            widget.category,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Icon(Icons.category_rounded, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
            hintText: 'Search ${widget.category}...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildProductStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('products')
          .where('category', isEqualTo: widget.category)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoadingIndicator();

        final products = snapshot.data!.docs.where((product) {
          final name = product['name'].toString().toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        return FutureBuilder<List<Widget>>(
          future: _buildProductCards(products),
          builder: (context, futureSnapshot) {
            if (!futureSnapshot.hasData) return _buildLoadingIndicator();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: futureSnapshot.data!.length,
              itemBuilder: (context, index) => futureSnapshot.data![index],
            );
          },
        );
      },
    );
  }

  Future<List<Widget>> _buildProductCards(List<QueryDocumentSnapshot> products) async {
    final List<Widget> cards = [];
    final Set<String> shopIds = products.map((p) => p['shopId'].toString()).toSet();

    final activeShops = <String, bool>{};
    for (final shopId in shopIds) {
      activeShops[shopId] = await _hasActiveSubscription(shopId);
    }

    for (final product in products) {
      final shopId = product['shopId'].toString();
      if (!activeShops[shopId]!) continue;

      final distance = _calculateDistance(product['shopLocation']);
      final prediction = await _fetchPrediction(
        product['name'],
        product['price'].toDouble(),
        distance,
      );

      cards.add(_buildProductCard(product, distance, prediction));
    }

    return cards;
  }

  Widget _buildProductCard(
      QueryDocumentSnapshot product,
      double distance,
      Map<String, dynamic> prediction,
      ) {
    final originalPrice = product['price'].toDouble();
    final discount = double.tryParse(product['offers'].toString()) ?? 0.0;
    final discountedPrice = originalPrice * (1 - discount / 100);
    final dealQuality = prediction['prediction'] ?? 'Unknown';
    // Error from prediction API (if any) - currently not displayed but kept for future use
    // final error = prediction['error'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: Image.network(
                    product['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (discount > 0)
                      Text(
                        '${originalPrice.toStringAsFixed(2)} OMR',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red[400],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),

              // Price and Deal Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${discountedPrice.toStringAsFixed(2)} OMR',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product['offers']}% OFF',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDealColor(dealQuality).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getDealColor(dealQuality),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      dealQuality,
                      style: TextStyle(
                        color: _getDealColor(dealQuality),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDealColor(String dealQuality) {
    switch (dealQuality.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'bad':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }
}