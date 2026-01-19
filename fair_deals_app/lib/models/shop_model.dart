import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String shopId;
  final String shopName;
  final String location;
  final String status;
  final String contactInfo;
  final String email;
  final String commercialRegistration;
  final String imageUrl;


  Shop({
    required this.shopId,
    required this.shopName,
    required this.location,
    required this.status,
    required this.contactInfo,
    required this.email,
    required this.commercialRegistration,
    required this.imageUrl,
  });

  // Factory method to create a Shop object from Firestore
  factory Shop.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Shop(
        shopId: doc.id,
        shopName: data['shop_name'] ?? '',
        location: data['location'] ?? '',
        status: data['status'] ?? '',
        contactInfo: data['contact_info'] ?? '',
        email: data['email'] ?? '',
        commercialRegistration: data['commercial_reg'] ?? '',
        imageUrl: data['image_url'] ?? ''
    );
  }

  // Convert Shop object to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'shop_name': shopName,
      'location': location,
      'status': status,
      'contact_info': contactInfo,
      'email': email,
      'commercial_reg': commercialRegistration,
      'image_url' : imageUrl,
    };
  }
}
