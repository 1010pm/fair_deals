import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'ChangePasswordScreen.dart';
import '../../models/shop_model.dart';

class ShopSettingsScreen extends StatefulWidget {
  final String shopId;

  ShopSettingsScreen({required this.shopId});

  @override
  _ShopSettingsScreenState createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  bool _isProfileEditing = false;
  final _shopNameController = TextEditingController();
  final _shopEmailController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _commercialRegistrationController = TextEditingController();
  String? _imageUrl;
  File? _newImage;

  // Define the color scheme
  final Color _primaryColor = Color(0xFF384959);
  final Color _secondaryColor = Color(0xFF88BDF2);
  final Color _accentColor = Colors.white10;

  Future<Shop> _fetchShopData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.shopId)
        .get();

    if (doc.exists) {
      return Shop.fromFirestore(doc);
    } else {
      throw Exception('Shop not found');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File imageFile, String oldImageUrl) async {
    final storageRef = FirebaseStorage.instance.ref();
    final profileImagesRef = storageRef.child('profile_images/${widget.shopId}.jpg');

    try {
      // Delete old image if it exists
      if (oldImageUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error deleting old image: $e");
      }
    }

    // Upload new image
    await profileImagesRef.putFile(imageFile);
    return await profileImagesRef.getDownloadURL();
  }

  Future<void> _updateProfile() async {
    try {
      Shop shop = await _fetchShopData();
      String imageUrl = shop.imageUrl;

      if (_newImage != null) {
        imageUrl = await _uploadImage(_newImage!, shop.imageUrl);
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.shopId).update({
        'shop_name': _shopNameController.text.isNotEmpty ? _shopNameController.text : shop.shopName,
        'email': _shopEmailController.text.isNotEmpty ? _shopEmailController.text : shop.email,
        'location': _locationController.text.isNotEmpty ? _locationController.text : shop.location,
        'contact_info': _contactInfoController.text.isNotEmpty ? _contactInfoController.text : shop.contactInfo,
        'commercial_reg': _commercialRegistrationController.text.isNotEmpty ? _commercialRegistrationController.text : shop.commercialRegistration,
        'image_url': imageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          )
      );
      setState(() {
        _isProfileEditing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primaryColor,
        iconTheme: IconThemeData(color: _accentColor),
      ),
      body: FutureBuilder<Shop>(
        future: _fetchShopData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _primaryColor));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: _primaryColor)));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No shop data found.', style: TextStyle(color: _primaryColor)));
          }

          Shop shop = snapshot.data!;
          _shopNameController.text = shop.shopName;
          _shopEmailController.text = shop.email;
          _locationController.text = shop.location;
          _contactInfoController.text = shop.contactInfo;
          _commercialRegistrationController.text = shop.commercialRegistration;
          _imageUrl = shop.imageUrl;

          return ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: _secondaryColor.withOpacity(0.2),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: _secondaryColor,
                          backgroundImage: _newImage != null
                              ? FileImage(_newImage!)
                              : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
                          child: _newImage == null && _imageUrl == null
                              ? Icon(Icons.camera_alt, size: 30, color: _accentColor)
                              : null,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(shop.shopName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor)),
                      Text(shop.status, style: TextStyle(color: Colors.orangeAccent)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              _isProfileEditing
                  ? Column(
                children: [
                  _buildProfileTextField(_shopNameController, 'Shop Name'),
                  _buildProfileTextField(_shopEmailController, 'Email'),
                  _buildProfileTextField(_locationController, 'Location'),
                  _buildProfileTextField(_contactInfoController, 'Contact Info'),
                  _buildProfileTextField(_commercialRegistrationController, 'Commercial Registration'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _accentColor,
                    ),
                    child: Text('Save Changes' , style: TextStyle(color: Colors.white),),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isProfileEditing = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: _accentColor,
                    ),
                    child: Text('Cancel' , style: TextStyle(color: Colors.white),),
                  ),
                ],
              )
                  : _buildEditProfileTile(),
              Divider(color: _primaryColor.withOpacity(0.3)),
              _buildChangePasswordTile(),
              Divider(color: _primaryColor.withOpacity(0.3)),
              ListTile(
                title: Text('Logout', style: TextStyle(color: _primaryColor)),
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('/MainScreen');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _primaryColor),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: _primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _primaryColor),
          ),
        ),
        style: TextStyle(color: _primaryColor),
      ),
    );
  }

  Widget _buildEditProfileTile() {
    return ListTile(
      title: Text('Edit Profile', style: TextStyle(color: _primaryColor)),
      leading: Icon(Icons.edit, color: _primaryColor),
      onTap: () {
        setState(() {
          _isProfileEditing = true;
        });
      },
    );
  }

  Widget _buildChangePasswordTile() {
    return ListTile(
      title: Text('Change Password', style: TextStyle(color: _primaryColor)),
      leading: Icon(Icons.lock, color: _primaryColor),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangePasswordScreen(shopId: widget.shopId),
          ),
        );
      },
    );
  }
}