import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'register_screen.dart';
import 'budgeting_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide1, _slide2, _slide3, _slide4;
  late Animation<double> _fade1, _fade2, _fade3, _fade4;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false; 
  bool _isLoading = false; 

  final String _baseUrl = 'http://192.168.56.111:9999'; 

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slide1 = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _slide2 = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _slide3 = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    _slide4 = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );

    _fade1 = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4));
    _fade2 = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6));
    _fade3 = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8));
    _fade4 = CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan password tidak boleh kosong.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login Status code: ${response.statusCode}');
      print('Login Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) { 
        if (data is Map && data.containsKey('access_token')) {
          final token = data['access_token'];
          _showSnackBar('Login berhasil!', Colors.green); 
          print('Login berhasil. Token: $token');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BudgetingPage(authToken: token)),
          );
        } else {
          _showSnackBar('Respons server tidak valid: Kunci "access_token" tidak ditemukan.', Colors.red); // Error message
        }
      } else {
        _showSnackBar(data['message'] ?? 'Login gagal. Silakan coba lagi.', Colors.red); // Error message
      }
    } catch (e) {
      print('Exception: $e');
      _showSnackBar('Gagal menghubungi server. Pastikan alamat IP benar dan server berjalan.', Colors.red); // Error message
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
        duration: const Duration(seconds: 3), 
      ),
    );
  }

  Widget _buildTextField(String hint, bool isPassword, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false, 
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible; 
                  });
                },
              )
            : null,
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF00008B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    const Text(
                      'LADUSING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SlideTransition(
                      position: _slide1,
                      child: FadeTransition(
                        opacity: _fade1,
                        child: _buildTextField('Email', false, _emailController), 
                      ),
                    ),
                    const SizedBox(height: 16),
                    SlideTransition(
                      position: _slide2,
                      child: FadeTransition(
                        opacity: _fade2,
                        child: _buildTextField('Password', true, _passwordController), 
                      ),
                    ),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: _slide3,
                      child: FadeTransition(
                        opacity: _fade3,
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Login'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SlideTransition(
                      position: _slide4,
                      child: FadeTransition(
                        opacity: _fade4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: Image.asset('assets/icons8-google-480.png', height: 20),
                              label: const Text('Google'),
                              onPressed: () {
                                _showSnackBar('Login with Google not implemented.', Colors.grey);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: Image.asset('assets/icons8-facebook-480.png', height: 20),
                              label: const Text('Facebook'),
                              onPressed: () {
                                _showSnackBar('Login with Facebook not implemented.', Colors.grey);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())); // Ensure RegisterScreen is const
                        },
                        child: RichText(
                          text: const TextSpan( 
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.white70),
                            children: [
                              TextSpan( 
                                text: "Register Now",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}