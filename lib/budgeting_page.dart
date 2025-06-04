import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pencatatan_page.dart';
import 'laporan_page.dart';
import 'profile_page.dart';
import 'package:intl/intl.dart'; 
import 'package:collection/collection.dart'; 

class BudgetingCategory {
  final int id;
  final String category;
  final String type;
  final double? totalBudget; 
  final double? limitAmount; 
  final double? usedAmount; 
  final double? remainingLimit; 
  final double? totalIncomeFromTransactions; 

  BudgetingCategory({
    required this.id,
    required this.category,
    required this.type,
    this.totalBudget,
    this.limitAmount,
    this.usedAmount,
    this.remainingLimit,
    this.totalIncomeFromTransactions, 
  });

  factory BudgetingCategory.fromJson(Map<String, dynamic> json) {
    return BudgetingCategory(
      id: json['id'],
      category: json['category'],
      type: json['type'],
      totalBudget: json['type'] == 'pemasukan'
          ? (json['total_budget'] as num?)?.toDouble()
          : null,
      totalIncomeFromTransactions: json['type'] == 'pemasukan'
          ? (json['total_income_from_transactions'] as num?)?.toDouble()
          : null,
      limitAmount: json['type'] == 'pengeluaran'
          ? (json['limit_amount'] as num?)?.toDouble()
          : null,
      usedAmount: json['type'] == 'pengeluaran'
          ? (json['used_amount'] as num?)?.toDouble()
          : null,
      remainingLimit: json['type'] == 'pengeluaran'
          ? (json['remaining_limit'] as num?)?.toDouble()
          : null,
    );
  }
}

class BudgetingPage extends StatefulWidget {
  final String authToken; 

  const BudgetingPage({super.key, required this.authToken});

  @override
  _BudgetingPageState createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  int _selectedMenuIndex = 0;
  bool isIncomeSelected = true;
  bool _isLoading = true; 

  List<BudgetingCategory> _allBudgetingCategories = [];
  List<BudgetingCategory> incomeCategories = []; 
  List<BudgetingCategory> expenseCategories = []; 

  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now()); 
  final List<String> _availableMonths = []; 

  final String _baseUrl = 'http://192.168.56.111:9999'; 

  @override
  void initState() {
    super.initState();
    _generateAvailableMonths(); 
    _fetchBudgetingData(); 
  }

  void _generateAvailableMonths() {
    DateTime now = DateTime.now();
    for (int i = -6; i <= 12; i++) { 
      DateTime month = DateTime(now.year, now.month + i, 1);
      _availableMonths.add(DateFormat('yyyy-MM').format(month));
    }
    if (!_availableMonths.contains(_selectedMonth)) {
      _selectedMonth = DateFormat('yyyy-MM').format(now);
    }
  }

  Future<void> _fetchBudgetingData() async {
    setState(() {
      _isLoading = true; 
    });

    final url = Uri.parse('$_baseUrl/budgeting?month=$_selectedMonth');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}', 
        },
      );

      print('Budgeting Status code: ${response.statusCode}');
      print('Budgeting Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        if (decodedData is List) {
          List<BudgetingCategory> fetchedCategories = [];
          for (var item in decodedData) {
            if (item is Map<String, dynamic>) {
              fetchedCategories.add(BudgetingCategory.fromJson(item));
            }
          }
          setState(() {
            _allBudgetingCategories = fetchedCategories;
            incomeCategories = _allBudgetingCategories.where((c) => c.type == 'pemasukan').toList();
            expenseCategories = _allBudgetingCategories.where((c) => c.type == 'pengeluaran').toList();
          });
        } else {
          _showErrorDialog('Format respons API budgeting tidak sesuai: bukan list. Pesan: ${decodedData['message'] ?? 'Tidak ada pesan spesifik.'}');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog('Gagal memuat budget: Status ${response.statusCode}. Pesan: ${errorData['message'] ?? 'Tidak ada pesan.'}');
      }
    } catch (e) {
      print('Exception fetching budgeting data: $e');
      _showErrorDialog('Gagal menghubungi server untuk memuat budget. Pastikan alamat IP benar atau API berjalan.');
    } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  Future<void> _addBudgetingTypeToApi(String category, String type, {double? limitAmount}) async {
    final url = Uri.parse('$_baseUrl/budgeting');
    final month = _selectedMonth; 

    Map<String, dynamic> body = {
      'month': "$month-01", 
      'category': category,
      'type': type,
    };

    if (type == 'pengeluaran' && limitAmount != null) {
      body['limit_amount'] = limitAmount;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode(body),
      );

      print('Add Budgeting Type Status code: ${response.statusCode}');
      print('Add Budgeting Type Response body: ${response.body}');

      if (response.statusCode == 200) { 
        final dynamic decodedResponse = jsonDecode(response.body);

        if (decodedResponse is Map && decodedResponse.containsKey('data')) {
          print('New budget item added successfully: ${decodedResponse['data']}');
          _fetchBudgetingData(); 
        } else {
          _showErrorDialog('Budget berhasil ditambahkan, namun format respons tidak terduga. Pesan: ${decodedResponse['message'] ?? 'Tidak ada pesan.'}');
          _fetchBudgetingData(); 
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog('Gagal menambahkan $type: Status ${response.statusCode}. Pesan: ${errorData['message'] ?? 'Tidak ada pesan.'}');
      }
    } catch (e) {
      print('Exception adding budgeting type: $e');
      _showErrorDialog('Gagal menghubungi server untuk menambahkan tipe budget. Pastikan alamat IP benar atau API berjalan.');
    }
  }

  void _showAddTypeDialog() {
    TextEditingController typeController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah ${isIncomeSelected ? 'Pemasukan' : 'Pengeluaran'} Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(hintText: "Nama Kategori (mis. Gaji, Makan)"),
            ),
            if (!isIncomeSelected) 
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "Limit Angka (mis. 1000000)"),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeController.text.isEmpty) {
                _showErrorDialog('Nama kategori tidak boleh kosong.');
                return;
              }

              String categoryType = isIncomeSelected ? 'pemasukan' : 'pengeluaran';
              double? limitAmount;
              if (!isIncomeSelected) {
                if (amountController.text.isNotEmpty) {
                  limitAmount = double.tryParse(amountController.text);
                  if (limitAmount == null) {
                    _showErrorDialog('Limit Angka harus berupa angka valid.');
                    return;
                  }
                } else {
                  _showErrorDialog('Limit Angka harus diisi untuk pengeluaran.');
                  return;
                }
              }
              _addBudgetingTypeToApi(typeController.text, categoryType, limitAmount: limitAmount);
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    List<BudgetingCategory> displayedCategories = isIncomeSelected ? incomeCategories : expenseCategories;

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
                    DropdownButton<String>(
                      value: _selectedMonth,
                      underline: const SizedBox(),
                      items: _availableMonths.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(value))),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });
                        _fetchBudgetingData(); 
                      },
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
                              color: isIncomeSelected ? const Color(0xFF4A90E2) : Colors.grey,
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
                              color: !isIncomeSelected ? const Color(0xFF4A90E2) : Colors.grey,
                              fontWeight: !isIncomeSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator()) 
                          : displayedCategories.isEmpty
                              ? Center(
                                  child: Text(
                                    isIncomeSelected
                                        ? 'Belum ada kategori pemasukan untuk bulan ini.'
                                        : 'Belum ada kategori pengeluaran untuk bulan ini.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: displayedCategories.length,
                                  itemBuilder: (context, index) {
                                    var category = displayedCategories[index];

                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              category.category,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF00008B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (category.type == 'pemasukan') ...[
                                              Text(
                                                'Terima Aktual: Rp ${NumberFormat.decimalPattern().format(category.totalIncomeFromTransactions ?? 0)}', // <-- Menggunakan data dari API (Opsi A)
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                              if (category.totalBudget != null && category.totalBudget! > 0)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: LinearProgressIndicator(
                                                    value: (category.totalIncomeFromTransactions ?? 0) / category.totalBudget!,
                                                    backgroundColor: Colors.grey[300],
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      (category.totalIncomeFromTransactions ?? 0) / category.totalBudget! >= 1.0
                                                          ? Colors.green
                                                          : Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                            if (category.type == 'pengeluaran') ...[
                                              Text(
                                                'Limit: Rp ${NumberFormat.decimalPattern().format(category.limitAmount ?? 0)}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                'Terpakai: Rp ${NumberFormat.decimalPattern().format(category.usedAmount ?? 0)}',
                                                style: TextStyle(fontSize: 14, color: Colors.red[700]),
                                              ),
                                              Text(
                                                'Sisa: Rp ${NumberFormat.decimalPattern().format(category.remainingLimit ?? 0)}',
                                                style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                                              ),
                                              if (category.limitAmount != null && category.limitAmount! > 0)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: LinearProgressIndicator(
                                                    value: (category.usedAmount ?? 0) / category.limitAmount!,
                                                    backgroundColor: Colors.grey[300],
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      (category.usedAmount ?? 0) / category.limitAmount! > 0.8
                                                          ? Colors.red
                                                          : (category.usedAmount ?? 0) / category.limitAmount! > 0.5
                                                              ? Colors.orange
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
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
        onPressed: _showAddTypeDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedMenuIndex,
        onTap: (index) {
          if (index != _selectedMenuIndex) {
            setState(() {
              _selectedMenuIndex = index;
            });
            List<String> incomeCategoryNames = incomeCategories.map((c) => c.category).toList();
            List<String> expenseCategoryNames = expenseCategories.map((c) => c.category).toList();

            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PencatatanPage(
                      authToken: widget.authToken,
                      tipePemasukan: incomeCategoryNames,
                      tipePengeluaran: expenseCategoryNames,
                      allBudgetingCategories: _allBudgetingCategories,
                    ),
                  ),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LaporanPage(authToken: widget.authToken)),
                );
                break;
              case 3:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage(authToken: widget.authToken)),
                );
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