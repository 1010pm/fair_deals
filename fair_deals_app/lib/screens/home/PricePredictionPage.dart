import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PricePredictionWizard extends StatefulWidget {
  @override
  _PricePredictionWizardState createState() => _PricePredictionWizardState();
}

class _PricePredictionWizardState extends State<PricePredictionWizard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ramController = TextEditingController();
  final TextEditingController _storageController = TextEditingController();
  final TextEditingController _screenSizeController = TextEditingController();
  final TextEditingController _cameraController = TextEditingController();
  final TextEditingController _batteryController = TextEditingController();

  int _currentStep = 0;
  bool isLoading = false;

  // Default selections
  String selectedBrand = "Samsung";
  String selectedCPU = "Snapdragon 8 Gen 1";
  String selectedScreenType = "OLED";

  String priceAfter3Months = "-";
  String priceAfter6Months = "-";
  String priceAfter9Months = "-";
  String priceAfter12Months = "-";

  final List<String> brands = ["Apple", "Samsung", "Google", "Xiaomi", "Huawei", "OnePlus"];
  final List<String> cpus = [
    "A15 Bionic", "A16 Bionic", "Dimensity 8000", "Dimensity 8100", "Exynos 2100",
    "Exynos 990", "Google Tensor", "Google Tensor G2", "Kirin 9000", "Kirin 990",
    "Snapdragon 732G", "Snapdragon 778G", "Snapdragon 8 Gen 1", "Snapdragon 8 Gen 2",
    "Snapdragon 8+ Gen 1", "Snapdragon 865", "Snapdragon 870", "Snapdragon 888"
  ];
  final List<String> screenTypes = ["LCD", "OLED"];

  final String apiUrl = "http://10.0.2.2:8000/predict_device_price";

  @override
  void dispose() {
    _priceController.dispose();
    _ramController.dispose();
    _storageController.dispose();
    _screenSizeController.dispose();
    _cameraController.dispose();
    _batteryController.dispose();
    super.dispose();
  }

  Future<void> _predictPrice() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "RAM_GB": int.parse(_ramController.text),
          "Storage_GB": int.parse(_storageController.text),
          "Screen_Size_inches": double.parse(_screenSizeController.text),
          "Camera_MP": int.parse(_cameraController.text),
          "Battery_mAh": int.parse(_batteryController.text),
          "Current_Price_USD": double.parse(_priceController.text),
          "Brand": selectedBrand,
          "CPU": selectedCPU,
          "Screen_Type": selectedScreenType
        }),
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          priceAfter3Months = data['3_months'].toStringAsFixed(2);
          priceAfter6Months = data['6_months'].toStringAsFixed(2);
          priceAfter9Months = data['9_months'].toStringAsFixed(2);
          priceAfter12Months = data['12_months'].toStringAsFixed(2);
          _currentStep = 1;
        });
      } else {
        _showErrorDialog("Server returned an error. Please try again later.");
      }
    } catch (e) {
      _showErrorDialog("Connection error: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error", style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _formKey.currentState?.reset();
      selectedBrand = "Samsung";
      selectedCPU = "Snapdragon 8 Gen 1";
      selectedScreenType = "OLED";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmallScreen = constraints.maxWidth < 600;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade400],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_currentStep == 1)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => setState(() => _currentStep = 0),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 32,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - kToolbarHeight,
                        ),
                        child: IntrinsicHeight(
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: _currentStep == 0
                                ? _buildInputStep(isSmallScreen)
                                : _buildResultsStep(isSmallScreen),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputStep(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepHeader(
            title: "Device Specifications",
            subtitle: "Enter your device details to predict future prices",
            icon: Icons.phone_android,
          ),
          SizedBox(height: 24),
          Container(
            constraints: BoxConstraints(maxWidth: 800),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  children: [
                    _buildDropdown("Brand", brands, selectedBrand, (val) => setState(() => selectedBrand = val!)),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    isSmallScreen
                        ? Column(
                      children: [
                        _buildNumberField(_priceController, "Current Price OMR", "1000"),
                        SizedBox(height: 16),
                        _buildNumberField(_ramController, "RAM (GB)", "8"),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(child: _buildNumberField(_priceController, "Current Price OMR", "1000")),
                        SizedBox(width: 16),
                        Expanded(child: _buildNumberField(_ramController, "RAM (GB)", "8")),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    isSmallScreen
                        ? Column(
                      children: [
                        _buildNumberField(_storageController, "Storage (GB)", "128"),
                        SizedBox(height: 16),
                        _buildNumberField(_screenSizeController, "Screen (inches)", "6.5"),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(child: _buildNumberField(_storageController, "Storage (GB)", "128")),
                        SizedBox(width: 16),
                        Expanded(child: _buildNumberField(_screenSizeController, "Screen (inches)", "6.5")),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    isSmallScreen
                        ? Column(
                      children: [
                        _buildNumberField(_cameraController, "Camera (MP)", "12"),
                        SizedBox(height: 16),
                        _buildNumberField(_batteryController, "Battery (mAh)", "4000"),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(child: _buildNumberField(_cameraController, "Camera (MP)", "12")),
                        SizedBox(width: 16),
                        Expanded(child: _buildNumberField(_batteryController, "Battery (mAh)", "4000")),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    _buildDropdown("Processor", cpus, selectedCPU, (val) => setState(() => selectedCPU = val!)),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    _buildDropdown("Screen Type", screenTypes, selectedScreenType, (val) => setState(() => selectedScreenType = val!)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Container(
            constraints: BoxConstraints(maxWidth: 500),
            child: ElevatedButton(
              onPressed: isLoading ? null : _predictPrice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                elevation: 4,
                minimumSize: Size(double.infinity, 0),
              ),
              child: isLoading
                  ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("PREDICT PRICES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 12),
                  Icon(Icons.trending_up, size: 24),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResultsStep(bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepHeader(
          title: "Prediction Results",
          subtitle: "Estimated future prices for your device",
          icon: Icons.analytics,
        ),
        SizedBox(height: 24),
        Container(
          constraints: BoxConstraints(maxWidth: 800),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                children: [
                  _buildResultItem("Current Price", "OMR ${_priceController.text}", Icons.price_check),
                  Divider(height: isSmallScreen ? 16 : 24),
                  _buildResultItem("3 Months", "OMR $priceAfter3Months", Icons.calendar_today),
                  Divider(height: isSmallScreen ? 16 : 24),
                  _buildResultItem("6 Months", "OMR $priceAfter6Months", Icons.calendar_view_month),
                  Divider(height: isSmallScreen ? 16 : 24),
                  _buildResultItem("9 Months", "OMR $priceAfter9Months", Icons.date_range),
                  Divider(height: isSmallScreen ? 16 : 24),
                  _buildResultItem("12 Months", "OMR $priceAfter12Months", Icons.calendar_view_day),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              Text(
                "Note: These are estimates based on current market trends and historical data.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isSmallScreen ? 13 : 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                  elevation: 2,
                  minimumSize: Size(double.infinity, 0),
                ),
                child: Text(
                  "PREDICT ANOTHER DEVICE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStepHeader({required String title, required String subtitle, required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 36, color: Colors.white),
        ),
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a value';
        if (double.tryParse(value) == null) return 'Please enter a valid number';
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedItem, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedItem,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: Colors.white,
      style: TextStyle(color: Colors.black87, fontSize: 16),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: TextStyle(color: Colors.black87)),
      )).toList(),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue.shade800, size: 22),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }
}