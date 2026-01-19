import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ShopEditProductScreen.dart';

class ShopManageProductsScreen extends StatefulWidget {
  final String shopEmail;

  ShopManageProductsScreen({required this.shopEmail});

  @override
  _ShopManageProductsScreenState createState() => _ShopManageProductsScreenState();
}

class _ShopManageProductsScreenState extends State<ShopManageProductsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String shopId = "";
  String shopName = "";
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchShopData();
  }

  Future<void> _fetchShopData() async {
    try {
      final querySnapshot = await _db.collection('users').where('email', isEqualTo: widget.shopEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        setState(() {
          shopId = doc.id;
          shopName = doc['shop_name'];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: EdgeInsets.symmetric(vertical: 60, horizontal: 25),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Manage Products",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : hasError
                  ? Center(
                child: Text(
                  "No shop found for the provided email.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Hello, $shopName! Here are your products:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  Expanded(child: _buildProductList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('products').where('shopId', isEqualTo: shopId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return Center(
            child: Text('No products found for this shop.', style: TextStyle(color: Colors.white)),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data() as Map<String, dynamic>;
            final productId = products[index].id;
            final productName = product['name'] ?? 'Unnamed Product';
            final productImage = product['imageUrl'] ?? 'https://via.placeholder.com/150';
            final productPrice = product['price'] ?? 0;
            final warrantyPeriod = product['warrantyPeriod'] ?? 'N/A';
            final additionalInfo = product['description'] ?? 'No details';
            final offer = product['offers'] ?? '0';

            return _buildProductCard(
              productId: productId,
              productName: productName,
              productImage: productImage,
              productPrice: productPrice,
              warrantyPeriod: warrantyPeriod,
              additionalInfo: additionalInfo,
              offer: offer,
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard({
    required String productId,
    required String productName,
    required String productImage,
    required dynamic productPrice,
    required String warrantyPeriod,
    required String additionalInfo,
    required String offer,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            productImage,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.image_not_supported, size: 60, color: Colors.white70),
          ),
        ),
        title: Text(
          productName,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: $productPrice OMR', style: TextStyle(color: Colors.white70)),
            Text('Warranty: $warrantyPeriod year(s)', style: TextStyle(color: Colors.white70)),
            Text('Additional Info: $additionalInfo', style: TextStyle(color: Colors.white70)),
            Text('Offer: $offer%', style: TextStyle(color: Colors.white70)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopEditProductScreen(
                      shopId: shopId,
                      productId: productId,
                      initialPrice: productPrice.toDouble(),
                      initialAdditionalInfo: additionalInfo,
                      initialWarranty: warrantyPeriod,
                      initialProductId: productId,
                      shopName: shopName,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                await _deleteProduct(productId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
