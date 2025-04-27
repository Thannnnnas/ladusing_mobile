import 'package:flutter/material.dart';
import 'budgeting_page.dart';
import 'laporan_page.dart';
import 'profile_page.dart';

class PencatatanPage extends StatefulWidget {
  final List<String> tipePemasukan;
  final List<String> tipePengeluaran;

  const PencatatanPage({required this.tipePemasukan, required this.tipePengeluaran});

  @override
  _PencatatanPageState createState() => _PencatatanPageState();
}

class _PencatatanPageState extends State<PencatatanPage> {
  int _selectedMenuIndex = 1;
  bool isIncomeSelected = true;
  List<Map<String, dynamic>> transaksiRecords = [];
  String selectedMonth = 'April 2025'; 

  void _showAddTransactionDialog() {
    TextEditingController amountController = TextEditingController();
    String? selectedType;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah ${isIncomeSelected ? 'Pemasukan' : 'Pengeluaran'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text("Pilih Tanggal: ${selectedDate.toLocal()}".split(' ')[0]),
            ),
            DropdownButton<String>(
              value: selectedType,
              hint: Text('Pilih Tipe'),
              isExpanded: true,
              items: (isIncomeSelected ? widget.tipePemasukan : widget.tipePengeluaran)
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                });
              },
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Masukkan Nominal"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedType != null && amountController.text.isNotEmpty) {
                transaksiRecords.add({
                  'date': selectedDate,
                  'type': selectedType,
                  'amount': int.parse(amountController.text),
                  'isIncome': isIncomeSelected,
                });
                Navigator.pop(context);
                setState(() {});
              }
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
                        padding: const EdgeInsets.all(16),
                        itemCount: transaksiRecords.length,
                        itemBuilder: (context, index) {
                          var transaksi = transaksiRecords[index];
                          if (transaksi['isIncome'] != isIncomeSelected) {
                            return const SizedBox.shrink();
                          }
                          return ListTile(
                            title: Text('${transaksi['type']} - Rp ${transaksi['amount']}'),
                            subtitle: Text('${transaksi['date'].toLocal()}'.split(' ')[0]),
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
        backgroundColor: const Color(0xFF4A90E2),
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A90E2),
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
                      tipePemasukan: widget.tipePemasukan,
                      tipePengeluaran: widget.tipePengeluaran,
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
