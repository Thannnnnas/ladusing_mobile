import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // State for password visibility
  bool _isConfirmPasswordVisible = false; // State for confirm password visibility

  final String _baseUrl = 'http://192.168.56.111:9999'; // Base URL API Anda

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure ? (isPassword ? !_isPasswordVisible : !_isConfirmPasswordVisible) : false,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword || obscure 
            ? IconButton(
                icon: Icon(
                  isPassword && _isPasswordVisible || !isPassword && _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    if (isPassword) {
                      _isPasswordVisible = !_isPasswordVisible;
                    } else { 
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }
                  });
                },
              )
            : null,
      ),
      style: const TextStyle(color: Colors.white),
    );
  }


  Future<void> _registerUser() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields.', Colors.red);
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.', Colors.red);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters long.', Colors.red);
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showSnackBar('Please enter a valid email address.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$_baseUrl/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      print('Register Status code: ${response.statusCode}');
      print('Register Response body: ${response.body}');

      if (response.statusCode == 200 ||  response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _showSnackBar(responseData['message'] ?? 'Registration successful!', Colors.green);
        Navigator.pop(context);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? 'Registration failed. Please try again.', Colors.red);
      }
    } catch (e) {
      print('Exception during registration: $e');
      _showSnackBar('Failed to connect to the server. Please check your internet connection or API URL.', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF00008B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'LADUSING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'sign up',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField('Username *', _usernameController),
                const SizedBox(height: 16),
                _buildTextField('Email Address *', _emailController),
                const SizedBox(height: 16),
                _buildTextField('Password *', _passwordController, obscure: true, isPassword: true), // Pass isPassword: true
                const SizedBox(height: 16),
                _buildTextField('Confirm Password *', _confirmPasswordController, obscure: true), // No isPassword: true, it will use obscure
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Register'),
                      ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child:  RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: "Login here",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}