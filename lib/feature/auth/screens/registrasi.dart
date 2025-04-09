import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import '../../../service/api_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:file_selector/file_selector.dart';

void main() {
  runApp(
    MaterialApp(
      home: RegisterScreen(),
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
    ),
  );
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  List<Map<String, dynamic>> _units = [];
  String? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  void _pickDocument(Function(XFile?) callback) async {
    final typeGroup = XTypeGroup(
      label: 'documents',
      extensions: ['pdf', 'doc', 'docx'],
      uniformTypeIdentifiers: [
        'com.adobe.pdf',
        'org.openxmlformats.wordprocessingml.document',
        'com.microsoft.word.doc',
      ],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      callback(file);
    }
  }

  String _getUnitNameById(String? id) {
    if (id == null || id.isEmpty) return "";

    final unit = _units.firstWhere(
      (unit) => unit['id'].toString() == id,
      orElse: () => {'unit_name': ''},
    );

    return unit['unit_name'].toString();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    }
  }

  Future<void> _fetchUnits() async {
    List<Map<String, dynamic>> units = await ApiService.getUnit();
    print("Fetched units: $units"); // Debugging
    setState(() {
      _units = units;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _prevStep,
        ),
        title: Text(
          "Register",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            StepProgressIndicator(
              totalSteps: 3,
              currentStep: _currentStep,
              size: 6,
              selectedColor: Colors.green,
              unselectedColor: Colors.grey[300]!,
              roundedEdges: Radius.circular(10),
            ),
            SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [_stepOne(), _stepTwo(), _stepThree()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker({
    required XFile? file,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Document"),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onPick,
          icon: Icon(Icons.upload_file),
          label: Text(file != null ? 'File: ${file.name}' : 'Choose File'),
        ),
      ],
    );
  }

  XFile? _documentStepOne; // Pastikan ini ada di state

  Widget _stepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Personal Information",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        _buildTextField("Full Name"),
        _buildTextField(
          "Email Address",
          keyboardType: TextInputType.emailAddress,
        ),
        _buildTextField("Phone Number", keyboardType: TextInputType.phone),

        _buildFilePicker(
          file: _documentStepOne,
          onPick: () {
            _pickDocument((file) {
              setState(() {
                _documentStepOne = file;
              });
            });
          },
        ),
        SizedBox(height: 24),
        _buildNextButton(),
      ],
    );
  }

  Widget _stepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Employee Information",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        _buildTextField("Employee ID"),

        SizedBox(height: 8),
        // Enhanced TypeAhead dropdown
        TypeAheadFormField<Map<String, dynamic>>(
          textFieldConfiguration: TextFieldConfiguration(
            decoration: InputDecoration(
              labelText: 'Select Department',
              hintText: 'Search or select department',
              prefixIcon: Icon(Icons.business),
              suffixIcon: Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Match your other fields
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14, // Match your other fields
              ),
            ),
            controller: TextEditingController(
              text: _getUnitNameById(_selectedUnit),
            ),
          ),
          suggestionsCallback: (pattern) {
            return _units
                .where(
                  (unit) => unit['unit_name'].toString().toLowerCase().contains(
                    pattern.toLowerCase(),
                  ),
                )
                .toList();
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                suggestion['unit_name'].toString(),
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(Icons.domain, color: Colors.green),
              ),
            );
          },
          onSuggestionSelected: (suggestion) {
            setState(() {
              _selectedUnit = suggestion['id'].toString();
            });
          },
          suggestionsBoxDecoration: SuggestionsBoxDecoration(
            borderRadius: BorderRadius.circular(12),
            elevation: 8.0,
            shadowColor: Colors.black26,
            constraints: BoxConstraints(maxHeight: 300),
          ),
          hideSuggestionsOnKeyboardHide: false,
          noItemsFoundBuilder:
              (context) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Text(
                      'No departments found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
          loadingBuilder:
              (context) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading departments...'),
                  ],
                ),
              ),
        ),

        SizedBox(height: 24),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _stepThree() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: Colors.green, size: 80),
        SizedBox(height: 16),
        Text(
          "Registration Completed!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Aksi setelah registrasi selesai
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Finish",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Next",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _prevStep,
          child: Text(
            "Back",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Next",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
