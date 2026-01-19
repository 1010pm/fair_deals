import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ShopEditProductScreen extends StatefulWidget {
  final String shopId;
  final String productId;
  final String shopName;
  final double initialPrice;
  final String initialAdditionalInfo;
  final String initialWarranty;

  const ShopEditProductScreen({
    Key? key,
    required this.shopName,
    required this.shopId,
    required this.productId,
    required this.initialPrice,
    required this.initialAdditionalInfo,
    required this.initialWarranty,
    required String initialProductId,
  }) : super(key: key);

  @override
  _ShopEditProductScreenState createState() => _ShopEditProductScreenState();
}

class _ShopEditProductScreenState extends State<ShopEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController warrantyController = TextEditingController();
  final TextEditingController offersController = TextEditingController();

  File? _selectedImage;
  String? selectedCategory;
  bool isLoading = true;
  bool isUpdating = false;
  String imageUrl = "";
  String previousOffers = "0";
  bool _isImageFullScreen = false;

  final List<String> categories = [
    'Smart Phones', 'Smart Watches', 'Tablets', 'Laptops',
    'Smart Home Devices', 'Wireless Earbuds', 'Gaming Consoles',
    'VR & AR Devices', 'Wearable Technology', 'Smart Assistants'
  ];

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      DocumentSnapshot doc = await _db.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          descriptionController.text = data['description'] ?? '';
          priceController.text = (data['price'] as num).toString();
          warrantyController.text = data['warrantyPeriod']?.toString() ?? '';
          offersController.text = data['offers']?.toString() ?? '0';
          previousOffers = offersController.text;
          selectedCategory = data['category']?.toString();
          imageUrl = data['imageUrl']?.toString() ?? '';
          isLoading = false;
        });
      } else {
        _showErrorSnackbar("Product not found");
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackbar("Failed to load product details");
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackbar("Failed to pick image");
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      setState(() => isUpdating = true);
      String fileName = 'product_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showErrorSnackbar("Image upload failed");
      return null;
    }
  }

  Future<void> _deleteOldImageIfNeeded(String? newImageUrl) async {
    if (imageUrl.isNotEmpty && newImageUrl != null && imageUrl != newImageUrl) {
      try {
        Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        debugPrint('Error deleting old image: $e');
      }
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUpdating = true);

    try {
      String? newImageUrl = imageUrl;

      if (_selectedImage != null) {
        newImageUrl = await _uploadImage(_selectedImage!);
        if (newImageUrl == null) return;
        await _deleteOldImageIfNeeded(newImageUrl);
      }

      Map<String, dynamic> updateData = {
        'name': nameController.text,
        'description': descriptionController.text,
        'price': double.tryParse(priceController.text) ?? 0.0,
        'category': selectedCategory,
        'warrantyPeriod': warrantyController.text,
        'offers': offersController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        updateData['imageUrl'] = newImageUrl;
      }

      await _db.collection('products').doc(widget.productId).update(updateData);

      if (previousOffers != offersController.text && offersController.text != "0") {
        await _db.collection('notifications').add({
          'shopId': widget.shopId,
          'shopName': widget.shopName,
          'productId': widget.productId,
          'productName': nameController.text,
          'offer': offersController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      _showSuccessSnackbar("Product updated successfully");
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackbar("Failed to update product");
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleImageFullScreen() {
    setState(() {
      _isImageFullScreen = !_isImageFullScreen;
    });
  }

  Widget _buildImagePreview(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: _toggleImageFullScreen,
      onLongPress: _pickImage,
      child: Hero(
        tag: 'product-image-${widget.productId}',
        child: Container(
          height: screenWidth * 0.6, // Responsive height based on screen width
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: _selectedImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
            ),
          )
              : imageUrl.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate,
                  size: screenWidth * 0.15, // Responsive icon size
                  color: Colors.white70),
              SizedBox(height: screenWidth * 0.03),
              Text('Tap to add product image',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.04, // Responsive text size
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenImage() {
    return GestureDetector(
      onTap: _toggleImageFullScreen,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Hero(
            tag: 'product-image-${widget.productId}',
            child: _selectedImage != null
                ? Image.file(_selectedImage!)
                : imageUrl.isNotEmpty
                ? Image.network(imageUrl)
                : Container(),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final screenWidth = MediaQuery.of(context).size.width;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white70,
        fontSize: screenWidth * 0.04, // Responsive font size
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, // Responsive padding
        vertical: screenWidth * 0.03,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isImageFullScreen) {
      return _buildFullScreenImage();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Product',
          style: TextStyle(fontSize: screenWidth * 0.05), // Responsive title
        ),
        backgroundColor: const Color(0xFF384959),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: screenWidth * 0.06),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePreview(context),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration(context, 'Product Name'),
                  validator: (value) => value!.isEmpty ? 'Required field' : null,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: descriptionController,
                  maxLines: isSmallScreen ? 2 : 3,
                  decoration: _inputDecoration(context, 'Description'),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(context, 'Price (OMR)'),
                  validator: (value) {
                    if (value!.isEmpty) return 'Required field';
                    if (double.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenHeight * 0.02),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value),
                  decoration: _inputDecoration(context, 'Category'),
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: warrantyController,
                  decoration: _inputDecoration(context, 'Warranty Period (years)'),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: offersController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(context, 'Offers (%)'),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
                SizedBox(height: screenHeight * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUpdating ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isUpdating
                        ? CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : Text(
                      'UPDATE PRODUCT',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    warrantyController.dispose();
    offersController.dispose();
    super.dispose();
  }
}