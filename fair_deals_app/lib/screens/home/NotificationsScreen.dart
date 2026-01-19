import 'package:fair_deals_app/screens/home/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double topPadding = MediaQuery.of(context).padding.top + 10; // Adjust dynamically based on status bar

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF384959), Color(0xFF88BDF2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // 🔹 Back Arrow & Title in Same Row
                Padding(
                  padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 🔙 Back Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Go back to the previous screen instead of replacing it
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2), // Light transparent background
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                      ),


                      SizedBox(width: 70), // Space between arrow & title

                      // 📌 Title
                      Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,

                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30), // Space below the title

                // 🔹 Notifications List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No notifications yet.",
                            style: TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                        );
                      }

                      var notifications = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          var notification = notifications[index];
                          var data = notification.data() as Map<String, dynamic>;

                          return _buildNotificationCard(context, data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


// 🔹 Reusable Notification Card (Fixed)
  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> data) {  // Accept `context`
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 4,
        color: Colors.white.withOpacity(0.15), // Transparent effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(Icons.notifications, color: Colors.white),
          title: Text(
            "${data['shopName']} - ${data['productName']}",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Text(
            "Offer: ${data['offer']} %",
            style: TextStyle(color: Colors.white70),
          ),
          trailing: Text(
            _formatTimestamp(data['timestamp']),
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          onTap: () async {
            var querySnapshot = await FirebaseFirestore.instance
                .collection('products')
                .where(FieldPath.documentId, isEqualTo: data['productId'])
                .get();

            if (!context.mounted) return;
            
            if (querySnapshot.docs.isNotEmpty) {
              QueryDocumentSnapshot productDoc = querySnapshot.docs.first;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: productDoc),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Product details not found.")),
              );
            }
          },
        ),
      ),
    );
  }



  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown date";
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
}
