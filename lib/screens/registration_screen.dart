import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Step 1: Personal Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _userType = 'Buyer';
  
  // Step 2: Address
  final _streetAddressController = TextEditingController();
  final _countryController = TextEditingController(text: 'Philippines');
  final _regionController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  String _country = 'Philippines';
  String _region = '';
  String _province = '';
  String _city = '';
  String _selectedAddress = 'Tap on map to select location';
  LatLng _selectedLocation = LatLng(14.5995, 120.9842); // Manila default
  final MapController _mapController = MapController();
  
  // Step 3: Documents
  XFile? _idDocument;
  XFile? _birDocument;
  final ImagePicker _picker = ImagePicker();
  
  // Step 4: OTP
  final _otpController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _streetAddressController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _otpController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_currentStep == 3 ? 'Verify' : 'Next'),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Personal Info'),
            content: _buildPersonalInfoStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Address'),
            content: _buildAddressStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Documents'),
            content: _buildDocumentsStep(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Verify OTP'),
            content: _buildOTPStep(),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter first name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter last name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter email';
              if (!value!.contains('@')) return 'Please enter valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number (10 digits)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter phone number';
              if (value!.length != 10) return 'Phone must be 10 digits';
              if (!RegExp(r'^\d+$').hasMatch(value)) return 'Only digits allowed';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter password';
              if (value!.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please confirm password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _userType,
            decoration: const InputDecoration(
              labelText: 'User Type',
              border: OutlineInputBorder(),
            ),
            items: ['Buyer', 'Seller', 'Rider']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _userType = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Your Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fill in your address details below',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        
        // Street Address (Optional)
        TextFormField(
          controller: _streetAddressController,
          decoration: const InputDecoration(
            labelText: 'Street Address (Optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g., 123 Main St, Barangay Example',
            prefixIcon: Icon(Icons.home),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        
        // Region
        TextFormField(
          controller: _regionController,
          decoration: const InputDecoration(
            labelText: 'Region *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Region IV-A (CALABARZON), NCR',
            prefixIcon: Icon(Icons.map),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your region';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _region = value;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Province
        TextFormField(
          controller: _provinceController,
          decoration: const InputDecoration(
            labelText: 'Province *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Laguna, Cavite, Rizal',
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your province';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _province = value;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // City
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City/Municipality *',
            border: OutlineInputBorder(),
            hintText: 'e.g., Quezon City, Makati, Cebu City',
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your city';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _city = value;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Country (read-only)
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
            labelText: 'Country',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.flag),
          ),
          readOnly: true,
        ),
        const SizedBox(height: 24),
        
        // Optional: Pick on Map button
        OutlinedButton.icon(
          onPressed: _showMapPicker,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Pick Location on Map (Optional)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedAddress,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pick Your Location',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap on the map to select your location',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                
                // Map
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _selectedLocation,
                          zoom: 13.0,
                          onTap: (tapPosition, point) {
                            setModalState(() {
                              _selectedLocation = point;
                            });
                            setState(() {
                              _selectedLocation = point;
                            });
                            _getAddressFromCoordinates(point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.e_baby',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Selected location info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF7C3AED), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Confirm button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location selected!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text(
                        'Confirm Location',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Required Documents',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'ID Document (Required for all users)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildDocumentUpload(
          label: 'Upload ID',
          file: _idDocument,
          onTap: () => _pickDocument(isID: true),
        ),
        const SizedBox(height: 24),
        if (_userType == 'Seller') ...[
          const Text(
            'BIR Document (Required for Sellers)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildDocumentUpload(
            label: 'Upload BIR',
            file: _birDocument,
            onTap: () => _pickDocument(isID: false),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: file == null
            ? Row(
                children: [
                  const Icon(Icons.upload_file, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          file.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: onTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(file.path),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOTPStep() {
    return Column(
      children: [
        if (!_otpSent) ...[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email Verification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We will send a 6-digit code to your email to verify your account',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            _emailController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
        ] else ...[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Enter Verification Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We sent a 6-digit code to your email.\nEnter it below to complete your registration.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          // 6 Individual OTP Input Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 50,
                  height: 60,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    onChanged: (value) {
                      if (value.length == 1) {
                        if (index < 5) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else {
                          _otpFocusNodes[index].unfocus();
                        }
                      }
                      _updateOTPFromBoxes();
                    },
                    onTap: () {
                      _otpControllers[index].selection = TextSelection.fromPosition(
                        TextPosition(offset: _otpControllers[index].text.length),
                      );
                    },
                    onFieldSubmitted: (value) {
                      if (index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      }
                    },
                    textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                    ),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Didn't receive the code?",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resendOTP,
                  icon: const Icon(Icons.refresh, color: Color(0xFF7C3AED)),
                  label: const Text(
                    'Resend Code',
                    style: TextStyle(color: Color(0xFF7C3AED)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _updateOTPFromBoxes() {
    String otp = '';
    for (var controller in _otpControllers) {
      otp += controller.text;
    }
    _otpController.text = otp;
  }

  Future<void> _getAddressFromCoordinates(LatLng point) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?'
          'lat=${point.latitude}&lon=${point.longitude}&format=json';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'E-Baby Mobile App'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        // Build full address string
        final List<String> addressParts = [];
        if (address['road'] != null) addressParts.add(address['road']);
        if (address['suburb'] != null) addressParts.add(address['suburb']);
        if (address['city'] != null) addressParts.add(address['city']);
        else if (address['town'] != null) addressParts.add(address['town']);
        else if (address['village'] != null) addressParts.add(address['village']);
        if (address['province'] != null) addressParts.add(address['province']);
        else if (address['state'] != null) addressParts.add(address['state']);
        
        final fullAddress = addressParts.isNotEmpty 
            ? addressParts.join(', ') 
            : 'Location: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
        
        setState(() {
          _selectedAddress = fullAddress;
          _region = address['state'] ?? '';
          _province = address['province'] ?? address['state'] ?? '';
          _city = address['city'] ??
              address['town'] ??
              address['village'] ??
              '';
          
          // Update controllers
          _regionController.text = _region;
          _provinceController.text = _province;
          _cityController.text = _city;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Location: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
    }
  }

  Future<void> _pickDocument({required bool isID}) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isID) {
            _idDocument = image;
          } else {
            _birDocument = image;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _onStepContinue() async {
    if (_currentStep == 0) {
      // Validate form
      if (!_formKey.currentState!.validate()) {
        return;
      }
      
      // Check if email already exists
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final emailExists = await authService.checkEmailExists(_emailController.text.trim());
        
        if (emailExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This email is already registered. Please use a different email or login.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        setState(() {
          _isLoading = false;
          _currentStep++;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error checking email: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } else if (_currentStep == 1) {
      // Validate address fields from controllers (street address is optional)
      if (_regionController.text.isEmpty ||
          _provinceController.text.isEmpty ||
          _cityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in Region, Province, and City'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Update state variables from controllers
      setState(() {
        _region = _regionController.text;
        _province = _provinceController.text;
        _city = _cityController.text;
      });
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (_idDocument == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your ID document'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_userType == 'Seller' && _birDocument == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your BIR document'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Send OTP
      await _sendOTP();
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      if (!_otpSent) {
        await _sendOTP();
      } else {
        await _verifyOTPAndRegister();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Build address
      final addressParts = [
        if (_streetAddressController.text.isNotEmpty) _streetAddressController.text,
        _city,
        _province,
        _region,
        _country,
      ];
      final fullAddress = addressParts.join(', ');

      final result = await authService.register({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'address': fullAddress,
        'country': _country,
        'region': _region,
        'province': _province,
        'city': _city,
        'street_address': _streetAddressController.text,
        'password': _passwordController.text,
        'confirm_password': _confirmPasswordController.text,
        'user_type': _userType,
      });

      if (result['success']) {
        setState(() => _otpSent = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email! Please check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    // Clear all OTP boxes
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpController.clear();
    
    setState(() => _otpSent = false);
    await _sendOTP();
  }

  Future<void> _verifyOTPAndRegister() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload documents to Cloudinary first
      String? documentIdUrl;
      String? birUrl;

      if (_idDocument != null) {
        print('Uploading ID document to Cloudinary...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading ID document...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        try {
          final File idFile = File(_idDocument!.path);
          documentIdUrl = await CloudinaryService.uploadProfilePic(
            idFile,
            'id_${_emailController.text}',
          );
          print('ID document uploaded: $documentIdUrl');
        } catch (e) {
          print('Error uploading ID document: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload ID document: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (_birDocument != null && _userType == 'Seller') {
        print('Uploading BIR document to Cloudinary...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading BIR document...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        try {
          final File birFile = File(_birDocument!.path);
          birUrl = await CloudinaryService.uploadProfilePic(
            birFile,
            'bir_${_emailController.text}',
          );
          print('BIR document uploaded: $birUrl');
        } catch (e) {
          print('Error uploading BIR document: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload BIR document: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Now verify OTP with document URLs
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.verifyOTPWithDocuments(
        _emailController.text,
        _otpController.text,
        documentIdUrl ?? '',
        birUrl ?? '',
      );

      if (result['success']) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Registration Submitted!'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your account is pending admin approval.'),
                SizedBox(height: 8),
                Text('You will receive an email once your account is approved.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to auth screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
