import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ViewReportsScreen extends StatefulWidget {
  @override
  _ViewReportsScreenState createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  int feedbacksCount = 0;
  int productsCount = 0;
  int subscriptionsCount = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _getCounts();
  }

  Future<void> _getCounts() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      int feedbacks = await _getCollectionCount(firestore, 'feedbacks');
      int products = await _getCollectionCount(firestore, 'products');
      int subscriptions = await _getCollectionCount(firestore, 'subscriptions');

      if (mounted) {
        setState(() {
          feedbacksCount = feedbacks;
          productsCount = products;
          subscriptionsCount = subscriptions;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load data: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  Future<int> _getCollectionCount(FirebaseFirestore firestore, String collectionName) async {
    try {
      final QuerySnapshot snapshot = await firestore.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching $collectionName count: $e");
      }
      return 0;
    }
  }

  Stream<int> getShopsCount() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'shop')
        .snapshots()
        .map((snapshot) => snapshot.size)
        .handleError((error) {
      if (kDebugMode) {
        debugPrint("Error fetching shops count: $error");
      }
      return 0;
    });
  }

  Future<void> _exportAllReportsToPDF() async {
    final pdf = pw.Document();

    final feedbacks = await FirebaseFirestore.instance.collection('feedbacks').get();
    final products = await FirebaseFirestore.instance.collection('products').get();
    final shops = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'shop')
        .get();
    final subscriptions = await FirebaseFirestore.instance.collection('subscriptions').get();

    pw.Widget buildSection(String title, List<QueryDocumentSnapshot> docs) {
      if (docs.isEmpty) {
        return pw.Text('$title: No data available.\n');
      }

      final headers = (docs.first.data() as Map<String, dynamic>).keys.toList();
      final rows = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return headers.map((key) => data[key]?.toString() ?? '').toList();
      }).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(headers: headers, data: rows),
          pw.SizedBox(height: 16),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Center(
            child: pw.Text('All Reports', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 16),
          buildSection('Feedbacks', feedbacks.docs),
          buildSection('Products', products.docs),
          buildSection('Shops', shops.docs),
          buildSection('Subscriptions', subscriptions.docs),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> _exportToCSV(String collectionName, String title) async {
    try {
      bool hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) return;

      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(collectionName).get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No data to export for $title')),
        );
        return;
      }

      List<List<dynamic>> csvData = [];
      final firstDoc = snapshot.docs.first.data() as Map<String, dynamic>;
      csvData.add(firstDoc.keys.toList());

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        csvData.add(data.values.toList());
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getExternalStorageDirectory();
      final path = '${directory?.path}/$title-${DateTime.now().toIso8601String()}.csv';
      final file = File(path);

      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title exported to $path')),
      );

      OpenFile.open(path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export $title: ${e.toString()}')),
      );
    }
  }

  Future<bool> _requestStoragePermission(BuildContext context) async {
    var status = await Permission.storage.status;
    if (status.isGranted) return true;

    status = await Permission.storage.request();
    if (status.isGranted) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Storage permission is required to export files.')),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("View Reports"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF384959), Color(0xFF88BDF2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                      _buildReportCard(
                        "Feedbacks",
                        feedbacksCount,
                        Icons.feedback,
                        const Color(0xFF6AB9A7),
                        onTap: () => _showCollectionDetails('feedbacks', 'Feedbacks'),
                        onExport: () => _exportToCSV('feedbacks', 'Feedbacks'),
                      ),
                      _buildReportCard(
                        "Products",
                        productsCount,
                        Icons.shopping_cart,
                        const Color(0xFF88BDF2),
                        onTap: () => _showCollectionDetails('products', 'Products'),
                        onExport: () => _exportToCSV('products', 'Products'),
                      ),
                      StreamBuilder<int>(
                        stream: getShopsCount(),
                        builder: (context, snapshot) {
                          int shopsCount = snapshot.hasData ? snapshot.data! : 0;
                          return _buildReportCard(
                            "Total Shops",
                            shopsCount,
                            Icons.store,
                            const Color(0xFF384959),
                            onTap: () => _showCollectionDetails('users', 'Shops'),
                            onExport: () => _exportToCSV('users', 'Shops'),
                          );
                        },
                      ),
                      _buildReportCard(
                        "Subscriptions",
                        subscriptionsCount,
                        Icons.subscriptions,
                        const Color(0xFF6AB9A7),
                        onTap: () => _showCollectionDetails('subscriptions', 'Subscriptions'),
                        onExport: () => _exportToCSV('subscriptions', 'Subscriptions'),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Export Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.feedback),
                title: Text('Export Feedbacks (CSV)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCSV('feedbacks', 'Feedbacks');
                },
              ),
              ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text('Export Products (CSV)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCSV('products', 'Products');
                },
              ),
              ListTile(
                leading: Icon(Icons.store),
                title: Text('Export Shops (CSV)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCSV('users', 'Shops');
                },
              ),
              ListTile(
                leading: Icon(Icons.subscriptions),
                title: Text('Export Subscriptions (CSV)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCSV('subscriptions', 'Subscriptions');
                },
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Export All as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAllReportsToPDF();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportCard(
      String title,
      int count,
      IconData icon,
      Color color, {
        required VoidCallback onTap,
        required VoidCallback onExport,
      }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: TextStyle(color: Colors.white)),
        subtitle: Text('$count records', style: TextStyle(color: Colors.white)),
        trailing: IconButton(
          icon: Icon(Icons.download, color: Colors.white),
          onPressed: onExport,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showCollectionDetails(String collectionName, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6AB9A7))),
      ),
    );

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection(collectionName).get().timeout(Duration(seconds: 10));
      Navigator.of(context).pop();

      if (snapshot.docs.isEmpty) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No $title Found'),
            content: Text('There are currently no $title in the database.'),
            actions: [
              TextButton(
                child: Text('OK', style: TextStyle(color: Color(0xFF384959))),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionDetailsScreen(
            title: title,
            documents: snapshot.docs,
            collectionName: collectionName,
          ),
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error Loading $title'),
          content: Text('An error occurred: ${e.toString()}'),
          actions: [
            TextButton(
              child: Text('Retry', style: TextStyle(color: Color(0xFF384959))),
              onPressed: () {
                Navigator.of(context).pop();
                _showCollectionDetails(collectionName, title);
              },
            ),
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }
}

class CollectionDetailsScreen extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot> documents;
  final String collectionName;

  CollectionDetailsScreen({
    required this.title,
    required this.documents,
    required this.collectionName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title Details'),
      ),
      body: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          var document = documents[index];
          return ListTile(
            title: Text(document.id),
            subtitle: Text(document.data().toString()),
          );
        },
      ),
    );
  }
}
