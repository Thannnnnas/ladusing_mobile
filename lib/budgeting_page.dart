import 'package:flutter/material.dart';
import 'pencatatan_page.dart';
import 'laporan_page.dart';
import 'profile_page.dart';

class BudgetingPage extends StatefulWidget {
  @override
  _BudgetingPageState createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  int _selectedMenuIndex = 0;
  bool isIncomeSelected = true;
  List<Map<String, dynamic>> incomeRecords = [
    {'type': 'Gaji', 'amount': 5000000},
    {'type': 'Bonus', 'amount': 1000000},
  ];
  List<Map<String, dynamic>> expenseRecords = [
    {'type': 'Makan', 'amount': 1000000},
    {'type': 'Transportasi', 'amount': 500000},
  ];

  void _addBudgetingType(String type) {
    setState(() {
      if (isIncomeSelected) {
        incomeRecords.add({'type': type, 'amount': 0});
      } else {
        expenseRecords.add({'type': type, 'amount': 0});
      }
    });
  }

  void _showAddTypeDialog() {
    TextEditingController typeController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah ${isIncomeSelected ? 'Pemasukan' : 'Pengeluaran'}'),
        content: TextField(
          controller: typeController,
          decoration: InputDecoration(hintText: "Masukkan tipe"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeController.text.isNotEmpty) {
                _addBudgetingType(typeController.text);
              }
              Navigator.pop(context);
            },
            child: Text('Tambah'),
          ),
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
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      value: 'April 2025',
                      underline: SizedBox(),
                      items: ['April 2025', 'Mei 2025', 'Juni 2025'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isIncomeSelected = true;
                            });
                          },
                          child: Text(
                            'Pemasukan',
                            style: TextStyle(
                              color: isIncomeSelected ? Color(0xFF4A90E2) : Colors.grey,
                              fontWeight: isIncomeSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isIncomeSelected = false;
                            });
                          },
                          child: Text(
                            'Pengeluaran',
                            style: TextStyle(
                              color: !isIncomeSelected ? Color(0xFF4A90E2) : Colors.grey,
                              fontWeight: !isIncomeSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: isIncomeSelected ? incomeRecords.length : expenseRecords.length,
                        itemBuilder: (context, index) {
                          var record = isIncomeSelected ? incomeRecords[index] : expenseRecords[index];
                          return ListTile(
                            title: Text(record['type']),
                            trailing: Text('Rp ${record['amount']}'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF4A90E2),
        onPressed: _showAddTypeDialog,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedMenuIndex,
        onTap: (index) {
          if (index != _selectedMenuIndex) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BudgetingPage()));
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PencatatanPage(
                      tipePemasukan: incomeRecords.map((e) => e['type'].toString()).toList(),
                      tipePengeluaran: expenseRecords.map((e) => e['type'].toString()).toList(),
                    ),
                  ),
                );
                break;
              case 2:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LaporanPage()));
                break;
              case 3:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilePage()));
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
