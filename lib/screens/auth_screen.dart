import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../widgets/gradient_text.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _userType = 'Buyer';
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Background video state
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  int _currentClipIndex = 0;
  late final List<String> _clips;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Expect clips at assets/videos/clip1.mp4 ... clip10.mp4
    _clips = List.generate(10, (i) => 'assets/videos/clip${i + 1}.mp4');
    _initializeVideo(randomStart: true);
  }

  Future<void> _initializeVideo({bool randomStart = false}) async {
    _videoController?.removeListener(_handleVideoEnd);
    await _videoController?.dispose();

    if (randomStart && _clips.isNotEmpty) {
      _currentClipIndex = _random.nextInt(_clips.length);
    }

    final controller = VideoPlayerController.asset(_clips[_currentClipIndex]);
    _videoController = controller;
    try {
      await controller.initialize();
      controller
        ..setLooping(false)
        ..play();
      controller.addListener(_handleVideoEnd);
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (_) {
      // On any error just keep the gradient background.
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  void _handleVideoEnd() {
    final controller = _videoController;
    if (controller == null) return;
    final value = controller.value;
    if (!value.isInitialized) return;
    // When clip finishes (with small tolerance), pick a new random clip.
    if (value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 200) &&
        !value.isPlaying) {
      if (_clips.length > 1) {
        int nextIndex;
        do {
          nextIndex = _random.nextInt(_clips.length);
        } while (nextIndex == _currentClipIndex);
        _currentClipIndex = nextIndex;
      }
      _initializeVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video background
          Positioned.fill(
            child: _isVideoInitialized && _videoController != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : Container(
                    // Fallback to a static background image / gradient if video not ready
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/carousel/carousel1.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),
          // Dark gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Logo
                    SizedBox(
                      height: 60,
                      child: Image.asset(
                        'assets/images/logo/ebaby_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Toggle buttons
                    _buildToggleButtons(),
                    const SizedBox(height: 30),
                    // Auth card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Center(
                                child: GradientText(
                                  isLogin ? 'Welcome Back' : 'Create Account',
                                  colors: const [
                                    Color(0xFF9333EA),
                                    Color(0xFFD97706)
                                  ],
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  isLogin
                                      ? 'Sign in to your account'
                                      : 'Join E-Baby today',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF999999),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF9333EA),
                                        Color(0xFFD97706)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Form fields
                              if (!isLogin) ...[
                                _buildNameFields(),
                                const SizedBox(height: 16),
                              ],
                              _buildEmailField(),
                              const SizedBox(height: 16),
                              if (!isLogin) ...[
                                _buildPhoneField(),
                                const SizedBox(height: 16),
                                _buildAddressFields(),
                                const SizedBox(height: 16),
                              ],
                              _buildPasswordField(),
                              const SizedBox(height: 16),
                              if (!isLogin) ...[
                                _buildConfirmPasswordField(),
                                const SizedBox(height: 16),
                                _buildUserTypeDropdown(),
                                const SizedBox(height: 12),
                                _buildTermsCheckbox(),
                                const SizedBox(height: 16),
                              ],
                              // Submit button
                              _buildSubmitButton(),
                              if (isLogin) ...[
                                const SizedBox(height: 16),
                                _buildForgotPasswordLink(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Login', true),
          _buildToggleButton('Register', false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isLoginMode) {
    final isActive = (isLogin && isLoginMode) || (!isLogin && !isLoginMode);

    return GestureDetector(
      onTap: () {
        if (isLoginMode) {
          setState(() => isLogin = true);
        } else {
          // Navigate to registration screen
          Navigator.pushNamed(context, '/registration');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7C3AED) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: _firstNameController,
            label: 'First Name',
            hint: 'First Name',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: _lastNameController,
            label: 'Last Name',
            hint: 'Last Name',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildTextField(
      controller: _emailController,
      label: 'Email Address',
      hint: 'Enter your email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v!.isEmpty) return 'Required';
        if (!v.contains('@')) return 'Invalid email';
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return _buildTextField(
      controller: _phoneController,
      label: 'Phone Number',
      hint: 'Phone Number',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Placeholder(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Click on map to select location',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: TextEditingController(),
                label: '',
                hint: 'Country',
                enabled: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: TextEditingController(),
                label: '',
                hint: 'Region',
                enabled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: TextEditingController(),
                label: '',
                hint: 'Province',
                enabled: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: TextEditingController(),
                label: '',
                hint: 'City/Municipality',
                enabled: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _addressController,
          label: '',
          hint: 'Street Address, Barangay (click map or type)',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      label: 'Password',
      hint: 'Enter your password',
      icon: Icons.lock_outline,
      obscureText: !_showPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _showPassword ? Icons.visibility : Icons.visibility_off,
          color: const Color(0xFF7C3AED),
        ),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return _buildTextField(
      controller: _confirmPasswordController,
      label: 'Confirm Password',
      hint: 'Confirm your password',
      icon: Icons.lock_outline,
      obscureText: !_showConfirmPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
          color: const Color(0xFF7C3AED),
        ),
        onPressed: () =>
            setState(() => _showConfirmPassword = !_showConfirmPassword),
      ),
      validator: (v) {
        if (v!.isEmpty) return 'Required';
        if (v != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  Widget _buildUserTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _userType,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              items: ['Buyer', 'Seller', 'Rider']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              type == 'Buyer'
                                  ? Icons.person
                                  : type == 'Seller'
                                      ? Icons.store
                                      : Icons.delivery_dining,
                              color: const Color(0xFF7C3AED),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(type),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _userType = value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: true,
          onChanged: (v) {},
          activeColor: const Color(0xFF7C3AED),
        ),
        Expanded(
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'I agree to ',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
                TextSpan(
                  text: 'Terms and Conditions',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLogin ? Icons.login : Icons.person_add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/forgot_password'),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Customer Service',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label.isNotEmpty ? label : null,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF7C3AED), size: 20)
            : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
      ),
      style: const TextStyle(fontSize: 14),
      validator: validator,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      if (isLogin) {
        final result = await authService.login(
          _emailController.text,
          _passwordController.text,
        );
        if (result['success'] == true) {
          // Route based on user type
          final userType = authService.currentUser?.userType.toLowerCase();
          if (userType == 'seller') {
            Navigator.pushReplacementNamed(context, '/seller_dashboard');
          } else if (userType == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else if (userType == 'rider') {
            Navigator.pushReplacementNamed(context, '/rider_dashboard');
          } else {
            // Default to home for buyers
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _showError(result['error'] ?? 'Login failed');
        }
      } else {
        final result = await authService.register({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'phone_number': _phoneController.text,
          'address': _addressController.text,
          'password': _passwordController.text,
          'confirm_password': _confirmPasswordController.text,
          'user_type': _userType,
        });
        if (result['success'] == true) {
          // Route based on registered user type
          final userType = _userType.toLowerCase();
          if (userType == 'seller') {
            Navigator.pushReplacementNamed(context, '/seller_dashboard');
          } else if (userType == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else if (userType == 'rider') {
            Navigator.pushReplacementNamed(context, '/rider_dashboard');
          } else {
            // Default to home for buyers
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _showError(result['error'] ?? 'Registration failed');
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _videoController?.removeListener(_handleVideoEnd);
    _videoController?.dispose();
    super.dispose();
  }
}
