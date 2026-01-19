import 'package:fair_deals_app/screens/customer/customer_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_dashboard.dart';
import '../shop/shop_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Password hashing function
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Login method
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: _emailController.text.trim())
            .get();

        if (querySnapshot.docs.isEmpty) throw Exception('Email not registered.');

        final userDoc = querySnapshot.docs.first;
        final storedPasswordHash = userDoc['encrypted_password'];
        final enteredPasswordHash = _hashPassword(_passwordController.text.trim());

        if (enteredPasswordHash != storedPasswordHash) throw Exception('Incorrect password.');

        final role = userDoc['role'] ?? 'guest';
        
        // Save login state to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userDoc.id);
        await prefs.setString('role', role);
        
        if (!mounted) return;
        _navigateBasedOnRole(role, userDoc.id);
      } catch (e) {
        if (!mounted) return;
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        _showSnackBar(errorMessage.isNotEmpty ? errorMessage : 'An error occurred. Please try again.');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateBasedOnRole(String role, String userId) {
    if (role == 'shop') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ShopDashboardScreen(
            navigatorKey: GlobalKey<NavigatorState>(),
            shopId: userId,
          ),
        ),
      );
    } else if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboardScreen(
            navigatorKey: GlobalKey<NavigatorState>(),
            shopId: userId,
          ),
        ),
      );
    }
    else if (role == 'customer'){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => customer_MainScreen(
            navigatorKey: GlobalKey<NavigatorState>(),
            userId: userId,
          ),
        ),
      );
    }
    else {
      _showSnackBar('Role not recognized. Contact support.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  _buildLogo(),
                  SizedBox(height: 20),
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Log in to continue',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildInputCard(),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : _buildLoginButton(),
                  _buildFooterLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
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
    );
  }
  Widget _buildInputCard() {
    return Card(
      elevation: 0, // Remove shadow for a clean transparent look
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(_emailController, 'Email', Icons.email, false),
            SizedBox(height: 10),
            _buildTextField(_passwordController, 'Password', Icons.lock, true),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool obscure) {
    return TextFormField(
      controller: controller,
      obscureText: obscure ? _obscurePassword : false,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white), // White label text
        hintStyle: TextStyle(color: Colors.white70), // Slightly lighter hint text
        prefixIcon: Icon(icon, color: Colors.white), // White icon
        filled: true,
        fillColor: Colors.transparent, // Fully transparent background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)), // Subtle white border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)), // Slight white border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white, width: 2), // Stronger focus border
        ),
        suffixIcon: obscure
            ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        )
            : null,
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF384959),
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text('Login', style: TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/forgot-password', arguments: {'fromNavbar': true});
          },
          child: Text('Forgot Password?', style: TextStyle(color: Colors.white)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Customer Registration Section
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Are you a customer?", style: TextStyle(color: Colors.white)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/customer_RegisterScreen'),
                  child: Text('Register as customer', style: TextStyle(color: Colors.yellow)),
                ),
              ],
            ),
            SizedBox(width: 40), // Add spacing between the two sections
            // Shop Registration Section
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Are you a shop?", style: TextStyle(color: Colors.white)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text('Register as shop', style: TextStyle(color: Colors.yellow)),
                ),
              ],
            ),
          ],
        ),

      ],
    );
  }
}