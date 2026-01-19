import 'dart:io' show File;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';


class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _shopNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _commercialRegController = TextEditingController();


  LatLng? _selectedLocation;
  bool _isLoading = false;


  // Visibility states
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Validator for password field
  String? _passwordValidator(String? value, {bool isConfirm = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isConfirm) {
      if (value.length < 8) return 'Password must be at least 8 characters';
      if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must include an uppercase letter';
      if (!RegExp(r'[a-z]').hasMatch(value)) return 'Must include a lowercase letter';
      if (!RegExp(r'\d').hasMatch(value)) return 'Must include a number';
      if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
        return 'Must include a special character';
      }
    } else if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }


  Future<void> _pickLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _locationController.text = "${position.latitude}, ${position.longitude}";
    });
  }



  // Helper: Generate Random Code
  String _generateRandomCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  // Helper: Hash Password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _registerShop() async {
    if (!_formKey.currentState!.validate()) return;



    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final resetCode = _generateRandomCode();

      // Check if email already exists
      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw Exception('This email is already registered.');
      }

      final smtpServer = gmail('yahyathani16@gmail.com', 'dqpo iloj jsis xmae'); // Use secure storage for credentials
      final message = Message()
        ..from = Address('yahyathani16@gmail.com', 'Fair Deals App')
        ..recipients.add(email)
        ..subject = 'Email Verification Code'
        ..text = 'Your verification code is: $resetCode';

      try {
        await send(message, smtpServer);
        if (kDebugMode) {
          debugPrint('Email sent successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error sending email: $e');
        }
      }

      Fluttertoast.showToast(
          msg: 'Verification code sent to your email.',
          backgroundColor: Colors.green);



      // Navigate to Verification Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyCodeScreen(
            email: email,
            resetCode: resetCode,
            shopName: _shopNameController.text.trim(),
            onVerified: () async {
              String imageUrl = _selectedImage != null
                  ? await _uploadImage(_selectedImage!)
                  : 'https://static.vecteezy.com/system/resources/thumbnails/005/544/718/small_2x/profile-icon-design-free-vector.jpg';


              await FirebaseFirestore.instance.collection('users').add({
                'shop_name': _shopNameController.text.trim(),
                'location': _locationController.text.trim(),
                'contact_info': _contactInfoController.text.trim(),
                'email': email,
                'encrypted_password': _hashPassword(_passwordController.text),
                'commercial_reg': _commercialRegController.text.trim(),
                'status': 'Pending',
                'role': 'shop',
                'image_url': imageUrl  // Save the image URL
              });

              Fluttertoast.showToast(
                  msg: 'Shop registered successfully!',
                  backgroundColor: Colors.green);

              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    const url = 'https://www.google.com/maps/'; // URL to open Google Maps
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }


  File? _selectedImage;
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
      Reference ref = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }



  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? hintText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.blue),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.deepPurple[400]!, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as a new Shop', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Section
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Container(
                      width: 100, // Matches CircleAvatar radius*2
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 11,
                            spreadRadius: 2,
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage('assets/icon1.png'),
                          fit: BoxFit.cover, // Fills entire circle
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon1.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.phone_android,
                            size: 50,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ),

                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Register Your Shop",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF384959),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Fill in your shop details to get started",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Image Upload
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                        : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text(
                            'Shop Image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF384959),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: const Text(
                      'Upload Shop Image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form Fields
              _buildTextField(
                controller: _shopNameController,
                label: 'Shop Name',
                icon: Icons.store,
                validator: (value) => value!.isEmpty ? 'Enter shop name' : null,
                hintText: 'E.g. My Awesome Shop',
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on,
                      validator: (value) => value!.isEmpty ? 'Pick a location' : null,
                      hintText: 'E.g. 24.7136, 46.6753',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Color(0xFF384959),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.map, color: Colors.white),
                      onPressed: _pickLocation,
                    ),
                  ),
                ],
              ),

              _buildTextField(
                controller: _contactInfoController,
                label: 'Contact Number',
                icon: Icons.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter contact info';
                  }
                  if (!RegExp(r'^[79]\d{7}$').hasMatch(value.trim())) {
                    return 'Must be 8 digits & start with 7 or 9';
                  }
                  return null;
                },
                hintText: 'E.g. 71234567',
              ),

              _buildTextField(
                controller: _commercialRegController,
                label: 'Commercial Register',
                icon: Icons.assignment,
                hintText: 'Ex: E01-12345678',
                validator: (value) => !RegExp(r'^[A-Z]{1}\d{2}-\d{8}$')
                    .hasMatch(value!) ? 'Invalid format: Example E01-12345678' : null,
              ),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                validator: (value) => !value!.contains('@') ? 'Enter a valid email' : null,
                hintText: 'E.g. shop@example.com',
              ),

              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock,
                obscureText: !_isPasswordVisible,
                validator: (value) => _passwordValidator(value),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Color(0xFF384959),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock,
                obscureText: !_isConfirmPasswordVisible,
                validator: (value) => _passwordValidator(value, isConfirm: true),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Color(0xFF384959),
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF384959),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Register Shop',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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


































class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final String resetCode;
  final String shopName;
  final VoidCallback onVerified;

  VerifyCodeScreen({
    required this.email,
    required this.resetCode,
    required this.shopName,
    required this.onVerified,
  });

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  String? _error;
  bool _isVerifying = false;
  bool _isSuccess = false;

  Future<void> _sendEmails() async {
    final smtpServer = gmail('yahyathani16@gmail.com', 'dqpo iloj jsis xmae'); // Use secure storage for credentials
    const adminEmail = 'dealsappfair@gmail.com'; //  admin email

    // Email to Shop Owner
    final shopOwnerMessage = Message()
      ..from = Address('yahyathani16@gmail.com', 'Fair Deals App')
      ..recipients.add(widget.email)
      ..subject = 'Registration Successful - ${widget.shopName}'
      ..text = 'Congratulations! Your shop "${widget.shopName}" has been successfully registered. '
          'Please wait for admin approval to activate your store.';

    // Email to Admin
    final adminMessage = Message()
      ..from = Address('yahyathani16@gmail.com', 'Fair Deals App')
      ..recipients.add(adminEmail)
      ..subject = 'New Shop Registration - ${widget.shopName}'
      ..text = 'A new shop "${widget.shopName}" has been registered. '
          'Please review and verify the shop details to activate it.';

    try {
      await send(shopOwnerMessage, smtpServer);
      await send(adminMessage, smtpServer);
      if (kDebugMode) {
        debugPrint('Emails sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending email: $e');
      }
    }
  }


  Future<void> _verifyCode() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    await Future.delayed(Duration(seconds: 1)); // Simulated delay for UX

    if (_codeController.text.trim() == widget.resetCode) {
      // Simulate sending emails
      await _sendEmails();

      setState(() {
        _isSuccess = true;
      });

      // Show success animation and navigate back
      Future.delayed(Duration(seconds: 2), () {
        widget.onVerified();
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      setState(() {
        _isVerifying = false;
        _error = 'Invalid verification code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: _isSuccess
          ? _buildSuccessScreen()
          : _buildVerificationForm(),
    );
  }

  // Verification Input Form
  Widget _buildVerificationForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Illustration

          SizedBox(height: 16),

          // Message
          Text(
            'Enter the 6-digit verification code sent to:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
          SizedBox(height: 5),
          Text(
            widget.email,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          SizedBox(height: 24),

          // Code Input Field
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              errorText: _error,
              counterText: "",
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Verify Button
          _isVerifying
              ? SpinKitCircle(color: Colors.deepPurple, size: 50)
              : ElevatedButton(
            onPressed: _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Verify',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          SizedBox(height: 16),

          // Resend Code Option
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Verification code resent to your email.'),
              ));
            },
            child: Text(
              'Didn’t receive the code? Resend',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  // Success Screen
  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success Animation

          SizedBox(height: 16),
          Text(
            'Verification Successful!',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          SizedBox(height: 8),
          Text(
            'Redirecting...',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}