import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final String shopId;

  const AddProductScreen({super.key, required this.shopId});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController warrantyPeriodController = TextEditingController();
  final TextEditingController offersController = TextEditingController(text: '0');

  String? selectedCategory;
  File? _selectedImage;
  bool isLoading = false;
  String? shopName;
  String? shopLocation;

  List<String> categories = [
    'Smart Phones',
    'Smart Watches',
    'Tablets',
    'Laptops',
    'Smart Home Devices',
    'Wireless Earbuds',
    'Gaming Consoles',
    'VR & AR Devices',
    'Wearable Technology',
    'Smart Assistants'
  ];

  @override
  void initState() {
    super.initState();
    _getShopDetails();
  }

  Future<void> _getShopDetails() async {
    try {
      DocumentSnapshot shopSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.shopId).get();
      if (shopSnapshot.exists) {
        setState(() {
          shopName = shopSnapshot['shop_name'];
          shopLocation = shopSnapshot['location'];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching shop details: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('product_images/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => isLoading = true);
    try {
      String imageUrl = await _uploadImage(_selectedImage!);
      DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc();
      Product newProduct = Product(
        id: productRef.id,
        name: nameController.text,
        category: selectedCategory ?? 'Others',
        description: descriptionController.text,
        imageUrl: imageUrl,
        price: double.parse(priceController.text),
        warrantyPeriod: warrantyPeriodController.text,
        shopId: widget.shopId,
        shopName: shopName ?? '',
        shopLocation: shopLocation ?? '',
        offers: offersController.text.isEmpty ? '0' : offersController.text,
      );
      await productRef.set(newProduct.toMap());

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product added successfully!')));
      Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding product: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding product. Please try again.')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔙 Back Arrow & Title
                  Row(
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
                      SizedBox(width: 16),
                      Text(
                        "Add Product",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // 🛒 Input Fields
                  _buildTextField(nameController, 'Product Name', 'Enter a product name'),
                  _buildDropdownField(),
                  _buildTextField(descriptionController, 'Description', 'Enter a description', maxLines: 3),
                  _buildTextField(priceController, 'Price', 'Enter a valid price', keyboardType: TextInputType.number),
                  _buildImagePicker(),
                  _buildTextField(warrantyPeriodController, 'Warranty Period (Optional)', '', keyboardType: TextInputType.number, isOptional: true),
                  _buildTextField(offersController, 'Offer', 'Enter a valid offer', keyboardType: TextInputType.number, isOptional: true),
                  SizedBox(height: 24),
                  _buildSubmitButton(),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        _selectedImage != null ? Image.file(_selectedImage!, height: 150) : Container(),
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('Select Image' ,style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent, // Standout button
            padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // 🌟 TextField with Transparent Design
  Widget _buildTextField(TextEditingController controller, String label, String validationMessage,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2), // ✅ Transparent input fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) return validationMessage;
          if (keyboardType == TextInputType.number && value != null && value.isNotEmpty && double.tryParse(value) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  // 🌟 Dropdown Field
  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedCategory,
        items: categories.map((category) => DropdownMenuItem(value: category, child: Text(category, style: TextStyle(color: Colors.black)))).toList(),
        onChanged: (value) => setState(() => selectedCategory = value),
        decoration: InputDecoration(
          labelText: 'Category',
          labelStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2), // ✅ Transparent dropdown
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value == null ? 'Select a category' : null,
      ),
    );
  }

  // 🌟 Submit Button
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _addProduct,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange, // Standout button
        padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
        'Add Product',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
