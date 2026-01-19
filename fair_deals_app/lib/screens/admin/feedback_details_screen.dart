import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackDetailsScreen extends StatefulWidget {
  @override
  _FeedbackDetailsScreenState createState() => _FeedbackDetailsScreenState();
}

class _FeedbackDetailsScreenState extends State<FeedbackDetailsScreen> {
  String _selectedFilter = "All";

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      throw Exception("User not found");
    }
  }

  Future<Map<String, dynamic>> getSentimentAnalysis(String text) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/predict_sentiment/'), //192.168.100.25

      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load sentiment');
    }
  }

  @override
  Widget build(BuildContext context) {
    var dateFormat = DateFormat.yMMMd();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Feedback Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              // Stylish Dropdown Filter
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    items: ['All', 'Positive', 'Negative']
                        .map((filter) => DropdownMenuItem(
                      child: Text(filter),
                      value: filter,
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 4),

              // Feedback List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feedbacks')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No feedback available.'));
                    }

                    var feedbacks = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        var feedbackMap = feedbacks[index].data() as Map<String, dynamic>;
                        String userId = feedbackMap['userId'];
                        String feedbackText = feedbackMap['feedbackText'];

                        return FutureBuilder<Map<String, dynamic>>(
                          future: getUserDetails(userId),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) return SizedBox.shrink();
                            var userDetails = userSnapshot.data!;
                            return FutureBuilder<Map<String, dynamic>>(
                              future: getSentimentAnalysis(feedbackText),
                              builder: (context, sentimentSnapshot) {
                                if (!sentimentSnapshot.hasData) return SizedBox.shrink();
                                var sentiment = sentimentSnapshot.data!['sentiment'];
                                var confidence = sentimentSnapshot.data!['confidence'];

                                if (_selectedFilter != "All" &&
                                    _selectedFilter.toLowerCase() != sentiment.toLowerCase()) {
                                  return SizedBox.shrink();
                                }

                                Color cardColor = sentiment.toLowerCase() == 'positive'
                                    ? Colors.green.shade100
                                    : Colors.red.shade100;

                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundImage: userDetails['image_url'] != null
                                                  ? NetworkImage(userDetails['image_url'])
                                                  : null,
                                              child: userDetails['image_url'] == null
                                                  ? Icon(Icons.account_circle, size: 50, color: Colors.grey[600])
                                                  : null,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    userDetails['shop_name'] ?? 'Unknown Shop',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  Text(
                                                    userDetails['contact_info'] ?? '',
                                                    style: TextStyle(color: Colors.grey[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Sentiment: $sentiment (${(confidence * 100).toStringAsFixed(2)}%)',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500, color: Colors.black87),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          feedbackText,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
