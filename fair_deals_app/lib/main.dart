import 'package:fair_deals_app/screens/auth/customer_register.dart';
import 'package:fair_deals_app/screens/home/MainScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Add this

// Screens imports
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/shop/AddProductScreen.dart';
import 'screens/admin/feedback_details_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/category_screen.dart';
import 'screens/shop/shop_manage_products_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/shop_details_screen.dart';
import 'screens/shop/feedback_screen.dart';
import 'screens/shop/shop_settings_screen.dart';
import 'screens/admin/view_reports_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/manage_shops_screen.dart';
import 'screens/shop/shop_dashboard_screen.dart'; // 👈 Add this if not yet added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  // SECURITY NOTE: For production, move Firebase config to environment variables
  // For web, explicit options are required. For mobile, uses native config files.
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          // TODO: Move to environment variables for production
          apiKey: "AIzaSyBNXsGbaCNlwTuDQz--FPfp0v1AbjyClb4",
          authDomain: "fair-deals-app-f02f8.firebaseapp.com",
          databaseURL: "https://fair-deals-app-f02f8-default-rtdb.firebaseio.com",
          projectId: "fair-deals-app-f02f8",
          storageBucket: "fair-deals-app-f02f8.firebasestorage.app",
          messagingSenderId: "110913586535",
          appId: "1:110913586535:web:ccbb6b0d7e0f9110bb1bc2",
          measurementId: "G-5EWQQS7HEX",
        ),
      );
    } else {
      // Mobile platforms use google-services.json (Android) and GoogleService-Info.plist (iOS)
      await Firebase.initializeApp();
    }
  } catch (e) {
    // If already initialized, continue
    if (kDebugMode) {
      debugPrint('Firebase initialization: $e');
    }
  }

  // Check login state
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  final role = prefs.getString('role');

  Widget initialScreen;

  if (userId != null && role != null) {
    if (role == 'shop') {
      initialScreen = ShopDashboardScreen(
        navigatorKey: GlobalKey<NavigatorState>(),
        shopId: userId,
      );
    } else if (role == 'admin') {
      initialScreen = AdminDashboardScreen(
        navigatorKey: GlobalKey<NavigatorState>(),
        shopId: userId,
      );
    } else {
      initialScreen = MainScreen(); // fallback
    }
  } else {
    initialScreen = MainScreen();
  }

  runApp(FairDealsApp(initialScreen: initialScreen));
}

class FairDealsApp extends StatelessWidget {
  final Widget initialScreen;

  FairDealsApp({required this.initialScreen});

  final GlobalKey<NavigatorState> _mainNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _adminDashboardNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fair Deals',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: initialScreen, // 👈 Use dynamic screen here
      routes: {
        '/MainScreen': (context) => MainScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/shop_settings': (context) => ShopSettingsScreen(shopId: ''),
        '/shop_details': (context) => ShopDetailsScreen(shopId: ''),
        '/feedback_details': (context) => FeedbackDetailsScreen(),
        '/feedback': (context) => FeedbackScreen(shopId: ''),
        '/admin_dashboard': (context) => AdminDashboardScreen(
          navigatorKey: _adminDashboardNavigatorKey,
          shopId: '',
        ),
        '/view_reports': (context) => ViewReportsScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/manage_shops': (context) => ManageShopsScreen(),
        '/add_product': (context) => AddProductScreen(shopId: ''),
        '/shop_manage_products_screen': (context) =>
            ShopManageProductsScreen(shopEmail: ''),
        '/CategoryScreen': (context) => CategoryScreen(),
        '/customer_RegisterScreen': (context)=> customer_RegisterScreen(),
      },
      navigatorKey: _mainNavigatorKey,
    );
  }
}
