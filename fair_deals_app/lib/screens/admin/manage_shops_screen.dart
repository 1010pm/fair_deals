import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/shop_model.dart';

class ManageShopsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Manage Shops'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'shop')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No shops available.'));
            }

            var shops = snapshot.data!.docs;

            return ListView.builder(
              itemCount: shops.length,
              itemBuilder: (context, index) {
                Shop shop = Shop.fromFirestore(shops[index]);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Color(0xFF6AB9A7), // Soft Green for card background
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(shop.imageUrl),
                      backgroundColor: Colors.transparent,
                    ),
                    title: Text(
                      shop.shopName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact: ${shop.contactInfo}', style: TextStyle(color: Colors.white70)),
                        Text('Status: ${shop.status}', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.location_on, color: Colors.red),
                          onPressed: () {
                            _openGoogleMaps(shop.location);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editShop(context, shop);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openGoogleMaps(String location) async {
    List<String> coordinates = location.split(', ');
    double latitude = double.parse(coordinates[0]);
    double longitude = double.parse(coordinates[1]);

    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not open Google Maps';
    }
  }

  void _editShop(BuildContext context, Shop shop) {
    TextEditingController nameController = TextEditingController(text: shop.shopName);
    TextEditingController contactController = TextEditingController(text: shop.contactInfo);
    TextEditingController emailController = TextEditingController(text: shop.email);
    TextEditingController locationController = TextEditingController(text: shop.location);
    TextEditingController commercialRegController = TextEditingController(text: shop.commercialRegistration);
    TextEditingController imageUrlController = TextEditingController(text: shop.imageUrl);
    String status = shop.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Shop Details"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("Shop Name", nameController),
              _buildTextField("Contact Info", contactController),
              _buildTextField("Email", emailController),
              _buildTextField("Location", locationController),
              _buildTextField("Commercial Reg", commercialRegController),
              _buildTextField("Image URL", imageUrlController),
              DropdownButtonFormField<String>(
                value: status,
                items: ['Active', 'Inactive', 'Pending']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) => status = value ?? 'Pending',
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _updateShopDetails(shop.shopId, {
                'shop_name': nameController.text,
                'contact_info': contactController.text,
                'email': emailController.text,
                'location': locationController.text,
                'commercial_reg': commercialRegController.text,
                'image_url': imageUrlController.text,
                'status': status,
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void _updateShopDetails(String shopId, Map<String, dynamic> updatedData) {
    FirebaseFirestore.instance.collection('users').doc(shopId).update(updatedData);
  }
}