import 'package:fair_deals_app/screens/shop/PaymentScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';


class SubscriptionScreen extends StatefulWidget {
  final String shopId;
  SubscriptionScreen({required this.shopId});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _hasActiveSubscription = false;
  String _activePlanDuration = "";
  DateTime _endDate = DateTime.now();

  final List<Map<String, dynamic>> _plans = [
    {"duration": "1 Month", "price": 3.5},
    {"duration": "3 Months", "price": 10.0},
    {"duration": "1 Year", "price": 30.0},
  ];

  @override
  void initState() {
    super.initState();
    _checkActiveSubscription();
  }

  Future<void> _checkActiveSubscription() async {
    try {
      var subscriptionDoc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(widget.shopId)
          .get();

      if (subscriptionDoc.exists) {
        var data = subscriptionDoc.data() as Map<String, dynamic>;
        DateTime endDate = (data['endDate'] as Timestamp).toDate();
        if (endDate.isAfter(DateTime.now())) {
          setState(() {
            _hasActiveSubscription = true;
            _activePlanDuration = data['duration'];
            _endDate = endDate;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error checking subscription: $e");
      }
    }
  }

  void _selectPlan(BuildContext context, String duration, double price) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(shopId: widget.shopId, duration: duration, price: price),
      ),
    );
  }

  void _showRenewOrChangePlanDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Renew or Change Plan'),
          content: Text('Do you want to renew your current plan or select a new one?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Proceed with renewing the current plan
                _selectPlan(context, _activePlanDuration, _getPlanPrice(_activePlanDuration));
              },
              child: Text('Renew Current Plan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Proceed with selecting a new plan
                _showPlanSelectionDialog();
              },
              child: Text('Select New Plan'),
            ),
          ],
        );
      },
    );
  }

  void _showPlanSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose a New Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _plans.map((plan) {
              return ListTile(
                title: Text(plan["duration"]),
                subtitle: Text('\$${plan["price"]}'),
                onTap: () {
                  Navigator.pop(context);
                  _selectPlan(context, plan["duration"], plan["price"]);
                },
              );
            }).toList(),
          ),
        );
      },
    );
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
            // Custom Top App Bar with Back Button
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
                    "Choose a Plan",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _hasActiveSubscription
                    ? _buildActiveSubscriptionCard()
                    : _buildAvailablePlans(),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Active Subscription Card
  Widget _buildActiveSubscriptionCard() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text(
              'You have an active plan!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Duration: $_activePlanDuration',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'Expires on: ${_endDate.toLocal()}',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showRenewOrChangePlanDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('Renew or Change Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

// Available Subscription Plans
  Widget _buildAvailablePlans() {
    return ListView.builder(
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        var plan = _plans[index];
        return Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Icon(Icons.subscriptions, color: Colors.white),
            title: Text(plan["duration"], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text('\$${plan["price"]}', style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
            trailing: ElevatedButton(
              onPressed: () => _selectPlan(context, plan["duration"], plan["price"]), // Add `context` as the first argument
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  double _getPlanPrice(String duration) {
    switch (duration) {
      case '1 Month':
        return 3.5;
      case '3 Months':
        return 10.0;
      case '1 Year':
        return 30.0;
      default:
        return 0.0;
    }
  }
}










