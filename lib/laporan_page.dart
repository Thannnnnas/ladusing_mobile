import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'budgeting_page.dart';
import 'pencatatan_page.dart';
import 'profile_page.dart';

class LaporanPage extends StatefulWidget {
  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int _selectedMenuIndex = 2;
  String selectedPeriode = 'Harian';
  DateTime selectedDate = DateTime.now();
  bool isIncomeSelected = true;
  final Random random = Random();
  Map<String, Color> kategoriColors = {};

  List<Map<String, dynamic>> transaksiRecords = [
    {'type': 'Gaji', 'amount': 5000000, 'isIncome': true, 'limit': 6000000},
    {'type': 'Bonus', 'amount': 1000000, 'isIncome': true, 'limit': 1200000},
    {'type': 'Makan', 'amount': 1000000, 'isIncome': false, 'limit': 1500000},
    {'type': 'Transportasi', 'amount': 500000, 'isIncome': false, 'limit': 1000000},
  ];

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Color getKategoriColor(String kategori) {
    if (!kategoriColors.containsKey(kategori)) {
      kategoriColors[kategori] = Color.fromARGB(
        255,
        random.nextInt(156) + 100,
        random.nextInt(156) + 100,
        random.nextInt(156) + 100,
      );
    }
    return kategoriColors[kategori]!;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRecords = transaksiRecords
        .where((record) => record['isIncome'] == isIncomeSelected)
        .toList();

    int total = filteredRecords.fold(0, (sum, item) => sum + (item['amount'] as int));

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
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedPeriode,
                              underline: const SizedBox(),
                              items: ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'].map((e) {
                                return DropdownMenuItem(value: e, child: Text(e));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPeriode = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _pickDate,
                            child: Text('Mulai: ${selectedDate.toLocal()}'.split(' ')[0]),
                          ),
                        ],
                      ),
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
                        const SizedBox(width: 16),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView(
                          children: [
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: filteredRecords.isEmpty
                                  ? const Center(child: Text('Belum ada data'))
                                  : PieChart(
                                      PieChartData(
                                        sections: filteredRecords.map((record) {
                                          double percent = total == 0
                                              ? 0
                                              : (record['amount'] / total) * 100;
                                          return PieChartSectionData(
                                            value: record['amount'].toDouble(),
                                            title: '${percent.toStringAsFixed(1)}%',
                                            color: getKategoriColor(record['type']),
                                            radius: 60,
                                            titleStyle: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList(),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 30,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            filteredRecords.isEmpty
                                ? const SizedBox()
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('No')),
                                        DataColumn(label: Text('Kategori')),
                                        DataColumn(label: Text('% Total')),
                                        DataColumn(label: Text('Total/Kategori')),
                                        DataColumn(label: Text('% Limit')),
                                        DataColumn(label: Text('Limit')),
                                      ],
                                      rows: List.generate(filteredRecords.length, (index) {
                                        var record = filteredRecords[index];
                                        double percentTotal = total == 0
                                            ? 0
                                            : (record['amount'] / total) * 100;
                                        double percentLimit = (record['amount'] / record['limit']) * 100;
                                        return DataRow(cells: [
                                          DataCell(Text('${index + 1}')),
                                          DataCell(Text(record['type'])),
                                          DataCell(Text('${percentTotal.toStringAsFixed(1)}%')),
                                          DataCell(Text('Rp ${record['amount']}')),
                                          DataCell(Text('${percentLimit.toStringAsFixed(1)}%')),
                                          DataCell(Text('Rp ${record['limit']}')),
                                        ]);
                                      }),
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
          ],
        ),
      ),
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
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PencatatanPage(
                  tipePemasukan: ['Gaji', 'Bonus'],
                  tipePengeluaran: ['Makan', 'Transportasi'],
                )));
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
