import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'favorites_screen.dart' show FavoritesScreen;

class CustomerProfileScreen extends StatefulWidget {
  final String userId;

  const CustomerProfileScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _CustomerProfileScreenState createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DocumentSnapshot> _getUserData() {
    return _firestore.collection('users').doc(widget.userId).get();
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/MainScreen');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF4A6B8A),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60.0,
                    backgroundImage: NetworkImage(
                      userData["profilePicture"]?.toString() ??
                          "https://www.w3schools.com/w3images/avatar2.png",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Username
                  Text(
                    userData["username"] ?? "Unknown User",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF384959),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData["email"] ?? "",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  // Phone
                  if (userData["phone"] != null)
                    Text(
                      "📞 ${userData["phone"]}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                  const SizedBox(height: 32),

                  // Buttons
                  _buildProfileActionCard(
                    title: "Favorites",
                    icon: Icons.favorite,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoritesScreen(userId: widget.userId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildProfileActionCard(
                    title: "Logout",
                    icon: Icons.logout,
                    onTap: () => _handleLogout(context),
                    color: Colors.redAccent,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF384959),
    Color iconColor = const Color(0xFF384959),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
