import 'dart:math';
import 'package:fair_deals_app/screens/auth/ResetPasswordScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:mailer/smtp_server.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  String _generateRandomCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email cannot be empty';
    } else if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError = _validateEmail(email);
    });
    if (_emailError != null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Check if the email exists in Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Email not found in our records.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Generate the reset code
      final resetCode = _generateRandomCode();

      // Send the reset code via email (update credentials securely)
      final smtpServer = gmail('yahyathani16@gmail.com', 'dqpo iloj jsis xmae');
      final message = Message()
        ..from = Address('yahyathani16@gmail.com', 'Fair Deals App')
        ..recipients.add(email)
        ..subject = 'Password Reset Code'
        ..text = 'Your password reset code is: $resetCode\n\n'
            'Please enter this code in the app to reset your password.';

      await send(message, smtpServer);

      Fluttertoast.showToast(
        msg: 'Reset code sent to your email.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Navigate to the code verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyCodeScreen(
            email: email,
            resetCode: resetCode,
          ),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to send email: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Enter your email to receive a password reset code',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: Color(0xFF6A11CB)),
                            errorText: _emailError,
                            prefixIcon: Icon(Icons.email, color: Color(0xFF6A11CB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendResetCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A11CB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                              shadowColor: Colors.black.withOpacity(0.2),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                                : Text(
                              'Send Reset Code',
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
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final String resetCode;

  VerifyCodeScreen({required this.email, required this.resetCode});

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeVerified = false;
  bool _isLoading = false;

  late String _currentResetCode;

  @override
  void initState() {
    super.initState();
    _currentResetCode = widget.resetCode;
  }

  String _generateRandomCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  Future<void> _resendCode() async {
    try {
      Fluttertoast.showToast(
        msg: 'Resending code...',
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      setState(() {
        _isLoading = true;
      });

      _currentResetCode = _generateRandomCode();

      final smtpServer = gmail('yahyathani16@gmail.com', 'dqpo iloj jsis xmae');
      final message = Message()
        ..from = Address('yahyathani16@gmail.com', 'Fair Deals App')
        ..recipients.add(widget.email)
        ..subject = 'Password Reset Code'
        ..text = 'Your new password reset code is: $_currentResetCode\n\n'
            'Use this code to reset your password.';

      await send(message, smtpServer);

      Fluttertoast.showToast(
        msg: 'A new reset code has been sent to ${widget.email}.',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to resend the code: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyCode() {
    if (_codeController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Code cannot be empty.',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      if (_codeController.text.trim() == _currentResetCode) {
        setState(() {
          _isCodeVerified = true;
        });
        Fluttertoast.showToast(
          msg: 'Code verified! Enter your new password.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.email),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Invalid code. Please try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Verify Your Code',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'We sent a 6-digit code to\n${widget.email}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: 'Verification Code',
                            labelStyle: TextStyle(color: Color(0xFF6A11CB)),
                            prefixIcon: Icon(Icons.code, color: Color(0xFF6A11CB)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: TextStyle(
                            fontSize: 22,
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A11CB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                              shadowColor: Colors.black.withOpacity(0.2),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                                : Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        TextButton(
                          onPressed: _isLoading ? null : _resendCode,
                          child: Text(
                            "Didn't receive code? Resend",
                            style: TextStyle(
                              color: Color(0xFF6A11CB),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

