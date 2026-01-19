import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/feedback_model.dart';

class FeedbackScreen extends StatefulWidget {
  final String shopId;

  FeedbackScreen({required this.shopId});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackbar('Feedback cannot be empty!');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userDoc = await _firestore.collection('users').doc(widget.shopId).get();

      if (!userDoc.exists) {
        _showSnackbar('User details not found. Please try again later.');
        return;
      }

      final feedback = FeedbackModel(
        userId: widget.shopId,
        feedbackText: _feedbackController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _firestore.collection('feedbacks').add(feedback.toMap());
      _showSnackbar('Feedback submitted successfully!', success: true);
      _feedbackController.clear();
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: success ? Colors.green : Colors.red,
          ),
        ),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 350;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Responsive AppBar
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.05,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.075),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      "Submit Feedback",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.02,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight * 0.7,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isSmallScreen),
                        SizedBox(height: screenHeight * 0.02),
                        _buildUserDetailsSection(),
                        SizedBox(height: screenHeight * 0.03),
                        _buildFeedbackTextField(screenHeight),
                        SizedBox(height: screenHeight * 0.03),
                        _buildSubmitButton(screenWidth),
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

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          Icons.feedback,
          size: isSmallScreen ? 30 : 40,
          color: Colors.white,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'We value your feedback!',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailsSection() {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(widget.shopId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${userData?['shop_name'] ?? 'Guest'}!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Email: ${userData?['email'] ?? 'N/A'}',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'Phone: ${userData?['contact_info'] ?? 'N/A'}',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackTextField(double screenHeight) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: TextField(
        controller: _feedbackController,
        maxLines: (screenHeight < 600) ? 4 : 6,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Share your thoughts with us...',
          hintStyle: TextStyle(color: Colors.white70),
          labelText: 'Your Feedback',
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(double screenWidth) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
          'Submit Feedback',
          style: TextStyle(
            fontSize: screenWidth < 350 ? 14 : 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}