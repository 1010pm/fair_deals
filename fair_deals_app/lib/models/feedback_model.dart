import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String userId;

  final String feedbackText;
  final DateTime timestamp;

  FeedbackModel({
    required this.userId,
    required this.feedbackText,
    required this.timestamp,
  });

  // Convert a Feedback object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'feedbackText': feedbackText,
      'timestamp': timestamp,
    };
  }

  // Create a FeedbackModel from a map
  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      userId: map['userId'] ?? '',
      feedbackText: map['feedbackText'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(), // Make sure timestamp exists
    );
  }
}
