import 'dart:async';

import 'package:fair_deals_app/screens/home/NotificationsScreen.dart';
import 'package:fair_deals_app/screens/home/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:badges/badges.dart' as badges;
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  int _notificationCount = 3;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          searchQuery = _searchController.text.toLowerCase();
        });
      });
    });
  }


  Future<void> _initializeApp() async {
    try {
      await _requestLocationPermission();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      throw Exception('Failed to get location: ${e.toString()}');
    }
  }

  Future<double> _calculateDistance(String shopLocation) async {
    if (_currentPosition == null) return 0.0;

    try {
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
    } catch (e) {
      return 0.0;
    }
  }

  final Map<String, dynamic> _shopCache = {};

  Future<bool> _isShopActive(String shopId) async {
    if (_shopCache.containsKey(shopId)) return _shopCache[shopId]['isActive'];
    final doc = await _db.collection('users').doc(shopId).get();
    final isActive = doc.exists && (doc.data()?['status'] == 'Active');
    _shopCache[shopId] = {'isActive': isActive};
    return isActive;
  }

  Future<bool> _hasValidSubscription(String shopId) async {
    if (_shopCache.containsKey(shopId) && _shopCache[shopId].containsKey('hasSubscription')) {
      return _shopCache[shopId]['hasSubscription'];
    }

    final doc = await _db.collection('subscriptions').doc(shopId).get();
    bool hasSub = false;
    if (doc.exists) {
      final endDate = (doc['endDate'] as Timestamp).toDate();
      hasSub = endDate.isAfter(DateTime.now());
    }
    _shopCache[shopId] ??= {};
    _shopCache[shopId]['hasSubscription'] = hasSub;
    return hasSub;
  }

  Future<Map<String, dynamic>> _fetchPrediction(
      String product, double price, double distance) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF384959),
      appBar: AppBar(
        title: const Text('Home screen',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white
            )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 8, end: 8),
            badgeContent: Text(
              '$_notificationCount',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen()),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _errorMessage != null
          ? _buildError()
          : _buildMainContent(),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(6),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(MediaQuery.of(context).size.width),
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: _getChildAspectRatio(MediaQuery.of(context).size.width),
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          color: const Color(0xFF384959).withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 8,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 2),
                Container(
                  width: 8,
                  height: 6,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth > 900) return 4;
    if (screenWidth > 600) return 3;
    return 2;
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth > 900) return 2.2;
    if (screenWidth > 600) return 2.0;
    return 1.8;
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _initializeApp,
            child: const Text('Retry',
              style: TextStyle(color: Color(0xFF384959)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintText: 'Search for products...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return _buildShimmerLoading();

              final products = snapshot.data!.docs.where((product) {
                final name = product['name'].toString().toLowerCase();
                return name.contains(searchQuery);
              }).toList();

              return FutureBuilder<List<Widget>>(
                future: _buildProductCards(products),
                builder: (context, futureSnapshot) {
                  if (!futureSnapshot.hasData) return _buildShimmerLoading();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(screenWidth),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: _getChildAspectRatio(screenWidth),
                        ),
                        itemCount: futureSnapshot.data!.length,
                        itemBuilder: (_, index) => futureSnapshot.data![index],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<Widget>> _buildProductCards(List<QueryDocumentSnapshot> products) async {
    final List<Future<Widget?>> cardFutures = products.map((product) async {
      try {
        final shopId = product['shopId'];
        final isActive = await _isShopActive(shopId);
        final hasSubscription = await _hasValidSubscription(shopId);
        if (!isActive || !hasSubscription) return null;

        final location = await _getShopLocation(shopId);
        final distance = await _calculateDistance(location);
        final prediction = await _fetchPrediction(
          product['name'],
          product['price'].toDouble(),
          distance,
        );

        return _buildProductCard(product, distance, prediction);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error building product card: $e');
        }
        return null;
      }
    }).toList();

    final results = await Future.wait(cardFutures);
    return results.whereType<Widget>().toList(); // Filter out nulls
  }


  Future<String> _getShopLocation(String shopId) async {
    try {
      final doc = await _db.collection('users').doc(shopId).get();
      return doc.data()?['location']?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildProductCard(
      QueryDocumentSnapshot product,
      double distance,
      Map<String, dynamic> prediction,
      ) {
    final originalPrice = product['price'].toDouble();
    final discount = double.tryParse(product['offers'].toString()) ?? 0.0;
    final discountedPrice = originalPrice * (1 - discount / 100);
    final rawPrediction = prediction['prediction'] ?? 'Unknown';
    final dealQuality = rawPrediction == 'Unknown' ? 'New brand' : rawPrediction;


    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: Image.network(
                    product['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.image_not_supported,
                          size: 18,
                          color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 10,
                            color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10),
                        ),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${originalPrice.toStringAsFixed(2)} OMR',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.red[400],
                          fontSize: 10,
                        ),
                      ),
                    ],
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${product['offers']}% OFF',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getDealColor(dealQuality).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getDealColor(dealQuality),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      dealQuality.split(' ').first,
                      style: TextStyle(
                        color: _getDealColor(dealQuality),
                        fontSize: 9,
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
      case 'excellent deal':
        return Colors.green;
      case 'good':
      case 'good deal':
        return Colors.blue;
      case 'bad':
      case 'bad deal':
        return Colors.red;
      case 'fair':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}