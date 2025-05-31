import 'package:flutter/material.dart';
import 'budgeting_page.dart';
import 'laporan_page.dart';
import 'pencatatan_page.dart'; // Import PencatatanPage yang benar

// ProfilePage sekarang menerima authToken
class ProfilePage extends StatefulWidget {
  final String authToken;

  const ProfilePage({Key? key, required this.authToken}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedMenuIndex = 3; // Index untuk ProfilePage

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
                child: const Center(
                  child: Text(
                    'Halaman Profil',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            // Penting: Teruskan authToken ke halaman berikutnya!
            // Karena `ProfilePage` tidak memiliki akses langsung ke `_allBudgetingCategories`,
            // kita meneruskan list kosong dan `PencatatanPage` akan melakukan fetch sendiri di `initState`.
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
                    tipePemasukan: const [], // Akan di-fetch oleh PencatatanPage
                    tipePengeluaran: const [], // Akan di-fetch oleh PencatatanPage
                    allBudgetingCategories: const [], // Akan di-fetch oleh PencatatanPage
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
                // Sudah di ProfilePage, tidak perlu navigasi ulang
                break;
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
}