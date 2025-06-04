import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'budgeting_page.dart';
import 'laporan_page.dart';
import 'pencatatan_page.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  final String authToken;

  const ProfilePage({super.key, required this.authToken});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final int _selectedMenuIndex = 3;
  bool _isLoading = true;
  String? _username;
  String? _email;
  String? _createdAt;

  final String _baseUrl = 'http://192.168.56.111:9999';

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$_baseUrl/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      print('Profile Status code: ${response.statusCode}');
      print('Profile Response body: ${response.body}');

      final dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('Error decoding profile response body: $e');
        _showErrorDialog('Gagal memproses respons server. Respons bukan format JSON yang valid.');
        setState(() { _isLoading = false; });
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          _username = data['username'];
          _email = data['email'];
          _createdAt = data['created_at'];
        });
      } else {
        _showErrorDialog('Gagal memuat profil: Status ${response.statusCode}. Pesan: ${data['message'] ?? 'Tidak ada pesan.'}');
      }
    } catch (e) {
      print('Exception fetching profile: $e');
      _showErrorDialog('Gagal menghubungi server untuk memuat profil. Pastikan IP benar.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmNewPassword = _confirmNewPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty) {
      _showErrorDialog('Semua field password harus diisi.');
      return;
    }
    if (newPassword != confirmNewPassword) {
      _showErrorDialog('Password baru dan konfirmasi password tidak cocok.');
      return;
    }
    if (newPassword.length < 6) {
      _showErrorDialog('Password baru minimal 6 karakter.');
      return;
    }

    final url = Uri.parse('$_baseUrl/profile/change_password');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      print('Change Password Status code: ${response.statusCode}');
      print('Change Password Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSuccessDialog(responseData['message'] ?? 'Password berhasil diubah.');
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
      } else {
        _showErrorDialog(responseData['message'] ?? 'Gagal mengubah password. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception changing password: $e');
      _showErrorDialog('Gagal menghubungi server untuk mengubah password. Pastikan IP benar.');
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama'),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru'),
            ),
            TextField(
              controller: _confirmNewPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _oldPasswordController.clear();
              _newPasswordController.clear();
              _confirmNewPasswordController.clear();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _changePassword();
            },
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
  }

  void _logout() {

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sukses'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'LADUSING',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Profil',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00008B)),
                            ),
                            const SizedBox(height: 20),
                            _buildProfileInfoRow('Username:', _username ?? 'Memuat...'),
                            const SizedBox(height: 10),
                            _buildProfileInfoRow('Email:', _email ?? 'Memuat...'),
                            if (_createdAt != null) ...[
                              const SizedBox(height: 10),
                              _buildProfileInfoRow('Bergabung Sejak:', DateFormat('dd MMMM yyyy', 'id').format(DateTime.parse(_createdAt!))),
                            ],
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _showChangePasswordDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Ganti Password', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 16), // Spasi antara tombol
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _logout, // Tombol Logout
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red, // Warna merah untuk logout
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Logout', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedMenuIndex,
        onTap: (index) {
          if (index != _selectedMenuIndex) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BudgetingPage(authToken: widget.authToken)),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PencatatanPage(
                    authToken: widget.authToken,
                    tipePemasukan: const [],
                    tipePengeluaran: const [],
                    allBudgetingCategories: const [],
                  )),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LaporanPage(authToken: widget.authToken)),
                );
                break;
              case 3:
                break; // Sudah di ProfilePage, tidak perlu navigasi ulang
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Budgeting'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Pencatatan'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}