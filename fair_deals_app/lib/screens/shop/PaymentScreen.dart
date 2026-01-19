import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class PaymentScreen extends StatefulWidget {
  final String shopId;
  final String duration;
  final double price;

  const PaymentScreen({
    Key? key,
    required this.shopId,
    required this.duration,
    required this.price,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  bool _isProcessing = false;
  bool _saveCard = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _completePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Get the shop email from Firestore
      DocumentSnapshot shopDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.shopId)
          .get();

      if (!shopDoc.exists) throw Exception('Shop not found');
      String shopEmail = shopDoc['email'];

      // Calculate end date based on duration
      final endDate = DateTime.now().add(
        widget.duration == "1 Month" ? const Duration(days: 30) :
        widget.duration == "3 Months" ? const Duration(days: 90) :
        const Duration(days: 365),
      );

      // Save subscription data
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(widget.shopId)
          .set({
        'shopId': widget.shopId,
        'duration': widget.duration,
        'price': widget.price,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(endDate),
        'paymentMethod': 'Card',
        'lastUpdated': Timestamp.now(),
      });

      // Send confirmation email
      await _sendEmail(shopEmail, endDate);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful! Confirmation email sent.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _sendEmail(String email, DateTime endDate) async {
    // In production, use environment variables or secure storage for credentials
    final smtpServer = gmail('yahyathani16@gmail.com', 'dqpo iloj jsis xmae');

    final message = Message()
      ..from = const Address('yahyathani16@gmail.com', 'Fair Deals App')
      ..recipients.add(email)
      ..subject = 'Payment Confirmation - ${widget.duration} Subscription'
      ..html = '''
        <h2>Thank you for your payment!</h2>
        <p>Your subscription is now active.</p>
        
        <h3>Subscription Details:</h3>
        <ul>
          <li><strong>Plan:</strong> ${widget.duration}</li>
          <li><strong>Amount:</strong> OMR ${widget.price.toStringAsFixed(2)}</li>
          <li><strong>Start Date:</strong> ${DateTime.now().toString().split(' ')[0]}</li>
          <li><strong>End Date:</strong> ${endDate.toString().split(' ')[0]}</li>
        </ul>
        
        <p>If you have any questions, please contact our support team.</p>
        <p>Thank you for being a valued customer!</p>
      ''';

    try {
      await send(message, smtpServer);
    } on MailerException catch (e) {
      debugPrint('Email sending failed: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),

              // Payment Summary
              _buildSummaryCard(),

              // Payment Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                      _buildInputField(
                      label: "Card Number",
                      controller: _cardNumberController,
                      icon: Icons.credit_card,
                      isNumber: true,
                      maxLength: 16,
                      formatter: _formatCardNumber,
                      validator: _validateCardNumber,
                    ),

                    _buildInputField(
                      label: "Card Holder Name",
                      controller: _cardHolderController,
                      icon: Icons.person,
                      validator: _validateCardHolder,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: "Expiry Date (MM/YY)",
                            controller: _expiryDateController,
                            icon: Icons.date_range,
                            maxLength: 5,
                            formatter: _formatExpiryDate,
                            validator: _validateExpiryDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: "CVV",
                            controller: _cvvController,
                            icon: Icons.lock,
                            isNumber: true,
                            isPassword: true,
                            maxLength: 4,
                            validator: _validateCVV,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Save Card Option
                    Row(
                      children: [
                        Checkbox(
                          value: _saveCard,
                          onChanged: (value) => setState(() => _saveCard = value ?? false),
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                                (states) => states.contains(MaterialState.selected)
                                ? Colors.greenAccent
                                : Colors.white.withOpacity(0.5),
                          )),
                           Text(
                            "Save card for future payments",
                            style: TextStyle(color: Colors.white70),
                          ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Pay Now Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: _isProcessing ? null : _completePayment,
                            child: _isProcessing
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              "PAY NOW",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Secure Payment Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              "Secure Payment · Powered by Paymob",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Text(
            "Complete Payment",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscription Plan: ${widget.duration}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: OMR ${widget.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool isNumber = false,
    bool isPassword = false,
    int? maxLength,
    String? Function(String?)? validator,
    String? Function(String?)? formatter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        obscureText: isPassword,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
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
          counterText: "",
        ),
        inputFormatters: formatter != null
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'))]
            : null,
        validator: validator,
        onChanged: formatter,
      ),
    );
  }

  // Validation and formatting functions
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) return "Card number is required";
    if (!_isValidCardNumber(value.replaceAll(' ', ''))) return "Invalid card number";
    return null;
  }

  String? _validateCardHolder(String? value) {
    if (value == null || value.isEmpty) return "Card holder name is required";
    if (value.length < 3) return "Name is too short";
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) return "Expiry date is required";
    if (!_isValidExpiryDate(value)) return "Invalid or expired date";
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) return "CVV is required";
    if (value.length < 3 || value.length > 4) return "Invalid CVV";
    return null;
  }

  String? _formatCardNumber(String? input) {
    if (input == null) return null;
    final text = input.replaceAll(' ', '');
    if (text.length > 16) return _cardNumberController.text;
    if (text.length >= 4 && text.length <= 16 && text.length % 4 == 0) {
      _cardNumberController.text = '$text ';
      _cardNumberController.selection = TextSelection.fromPosition(
        TextPosition(offset: _cardNumberController.text.length),
      );
    }
    return null;
  }

  String? _formatExpiryDate(String? input) {
    if (input == null) return null;
    if (input.length == 2 && !input.contains('/')) {
      _expiryDateController.text = '$input/';
      _expiryDateController.selection = TextSelection.fromPosition(
        TextPosition(offset: _expiryDateController.text.length),
      );
    }
    return null;
  }

  bool _isValidCardNumber(String input) {
    if (input.length != 16) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = input.length - 1; i >= 0; i--) {
      int n = int.parse(input[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  bool _isValidExpiryDate(String input) {
    final regExp = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
    if (!regExp.hasMatch(input)) return false;

    final parts = input.split('/');
    final month = int.parse(parts[0]);
    final year = 2000 + int.parse(parts[1]);

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return false;
    }
    return true;
  }
}