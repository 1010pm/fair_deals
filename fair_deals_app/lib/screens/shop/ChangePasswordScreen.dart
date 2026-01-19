import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String shopId;

  ChangePasswordScreen({required this.shopId});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _sentResetCode;
  bool _isCodeSent = false;

  String _generateRandomCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _sendResetCode() async {
    final resetCode = _generateRandomCode();
    try {
      setState(() {
        _isLoading = true;
      });

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.shopId)
          .get();
      final email = doc['email'];

      final smtpServer = gmail('yahyathani16@gmail.com', 'dqpo iloj jsis xmae');
      final message = Message()
        ..from = Address('yahyathani16@gmail.com', 'Fair Deals App')
        ..recipients.add(email)
        ..subject = 'Password Reset Code'
        ..text = 'Your password reset code is: $resetCode';

      await send(message, smtpServer);

      _sentResetCode = resetCode;

      setState(() {
        _isCodeSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset code sent to your email.'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset code: $e'))
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final enteredCode = _resetCodeController.text.trim();

    if (_sentResetCode == null || enteredCode != _sentResetCode) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid or missing reset code'))
      );
      return;
    }

    // Additional password validation
    final passwordError = _validatePassword(newPassword);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passwordError))
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match'))
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final hashedPassword = _hashPassword(newPassword);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.shopId)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found'))
        );
        return;
      }

      final currentPasswordHash = userDoc['encrypted_password'];

      if (currentPasswordHash == hashedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('The new password must be different from the old password'),
              backgroundColor: Colors.orange,
            )
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.shopId)
          .update({
        'encrypted_password': hashedPassword,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: Colors.green,
          )
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password: $e'),
            backgroundColor: Colors.red,
          )
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    } else if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    } else if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one number';
    } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    } else if (password.contains(' ')) {
      return 'Password cannot contain spaces';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    } else if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateResetCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Reset code cannot be empty';
    } else if (value.length != 6) {
      return 'Reset code must be 6 digits';
    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Reset code must contain only numbers';
    }
    return null;
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
                    "Change Password",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isCodeSent) ...[
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sendResetCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                                vertical: 14.0,
                                horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                              'Send Reset Code',
                              style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ] else ...[
                        _buildTextField(
                          _resetCodeController,
                          "Enter Reset Code",
                          validator: _validateResetCode,
                        ),
                        SizedBox(height: 16),
                        _buildPasswordField(
                          _newPasswordController,
                          "New Password",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'New password cannot be empty';
                            }
                            return _validatePassword(value);
                          },
                        ),
                        SizedBox(height: 16),
                        _buildPasswordField(
                          _confirmPasswordController,
                          "Confirm Password",
                          validator: _validateConfirmPassword,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                              'Reset Password',
                              style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        String? Function(String?)? validator,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField(
      TextEditingController controller,
      String label, {
        String? Function(String?)? validator,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        validator: validator,
      ),
    );
  }
}