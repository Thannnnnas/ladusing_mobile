import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'budgeting_page.dart'; 
import 'laporan_page.dart';
import 'profile_page.dart';
import 'package:intl/intl.dart'; 
import 'package:collection/collection.dart'; 

class PencatatanPage extends StatefulWidget {
  final String authToken;
  final List<String> tipePemasukan;
  final List<String> tipePengeluaran;
  final List<BudgetingCategory> allBudgetingCategories; 

  const PencatatanPage({
    super.key,
    required this.authToken,
    this.tipePemasukan = const [],
    this.tipePengeluaran = const [],
    required this.allBudgetingCategories, 
  });

  @override
  _PencatatanPageState createState() => _PencatatanPageState();
}

class _PencatatanPageState extends State<PencatatanPage> {
  int _selectedMenuIndex = 1;
  bool isIncomeSelected = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> transaksiRecords = [];
  String _selectedMonthForTransactions = DateFormat('MMMM yyyy', 'id').format(DateTime.now());

  final DateTime _currentSelectedDateInDialog = DateTime.now();

  final String _baseUrl = 'http://192.168.56.111:9999';

  final List<String> _availableMonthsForTransactions = [];

  @override
  void initState() {
    super.initState();
    _generateAvailableMonths();
    _fetchTransactions();
  }

  void _generateAvailableMonths() {
    DateTime now = DateTime.now();
    _availableMonthsForTransactions.clear(); 
    for (int i = -6; i <= 12; i++) {
      DateTime month = DateTime(now.year, now.month + i, 1);
      _availableMonthsForTransactions.add(DateFormat('MMMM yyyy', 'id').format(month)); 
    }
    if (!_availableMonthsForTransactions.contains(_selectedMonthForTransactions)) {
      _selectedMonthForTransactions = DateFormat('MMMM yyyy', 'id').format(now);
      if (!_availableMonthsForTransactions.contains(_selectedMonthForTransactions) && _availableMonthsForTransactions.isNotEmpty) {
        _selectedMonthForTransactions = _availableMonthsForTransactions.first; 
      }
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      transaksiRecords.clear();
    });

    DateTime parsedMonth = DateFormat('MMMM yyyy', 'id').parse(_selectedMonthForTransactions);
    String monthYearApiFormat = DateFormat('yyyy-MM').format(parsedMonth);

    final url = Uri.parse('$_baseUrl/transactions?month=$monthYearApiFormat');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      print('Pencatatan - Transaksi Status code: ${response.statusCode}');
      print('Pencatatan - Transaksi Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        if (decodedData is List) {
          List<Map<String, dynamic>> fetchedTransactions = [];
          for (var item in decodedData) {
            if (item is Map<String, dynamic>) {
              final int? budgetingId = (item['budgeting_id'] as num?)?.toInt();
              BudgetingCategory? budgetCat;

              if (budgetingId != null) {
                budgetCat = widget.allBudgetingCategories.firstWhereOrNull(
                    (cat) => cat.id == budgetingId);
              }

              fetchedTransactions.add({
                'id': item['id'],
                'transaction_date': DateTime.tryParse(item['transaction_date'] ?? '') ?? DateTime.now(),
                'category': budgetCat?.category ?? item['category'] ?? 'Tidak Diketahui',
                'amount': (item['amount'] as num?)?.toInt() ?? 0,
                'type': item['type'],
                'isIncome': item['type'] == 'pemasukan',
              });
            }
          }
          setState(() {
            transaksiRecords = fetchedTransactions;
          });
        } else {
          _showErrorDialog('Gagal memuat transaksi: Format respons tidak sesuai (bukan list).');
        }
      } else {
        _showErrorDialog('Gagal memuat transaksi: Status ${response.statusCode}. Pesan: ${jsonDecode(response.body)['message'] ?? 'Tidak ada pesan.'}');
      }
    } catch (e) {
      print('Exception fetching transactions: $e');
      _showErrorDialog('Gagal menghubungi server untuk memuat transaksi. Pastikan IP benar.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTransactionToApi(int budgetingId, DateTime transactionDate, String type, int amount) async {
    final url = Uri.parse('$_baseUrl/transactions');

    Map<String, dynamic> body = {
      'budgeting_id': budgetingId,
      'transaction_date': DateFormat('yyyy-MM-dd').format(transactionDate),
      'type': type,
      'amount': amount,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode(body),
      );

      print('Add Transaction Status code: ${response.statusCode}');
      print('Add Transaction Response body: ${response.body}');

      if (response.statusCode == 200) {
        _fetchTransactions();
      } else {
        _showErrorDialog('Gagal menambahkan transaksi: Status ${response.statusCode}. Pesan: ${jsonDecode(response.body)['message'] ?? 'Tidak ada pesan.'}');
      }
    } catch (e) {
      print('Exception adding transaction: $e');
      _showErrorDialog('Gagal menghubungi server untuk menambahkan transaksi. Pastikan IP benar.');
    }
  }

  void _showAddTransactionDialog() {
    TextEditingController amountController = TextEditingController();
    BudgetingCategory? selectedBudgetingCategory;
    DateTime dialogSelectedDate = _currentSelectedDateInDialog;

    List<BudgetingCategory> availableCategories = isIncomeSelected
        ? widget.allBudgetingCategories.where((cat) => cat.type == 'pemasukan').toList()
        : widget.allBudgetingCategories.where((cat) => cat.type == 'pengeluaran').toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Tambah ${isIncomeSelected ? 'Pemasukan' : 'Pengeluaran'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: dialogSelectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != dialogSelectedDate) {
                        setDialogState(() {
                          dialogSelectedDate = picked;
                        });
                      }
                    },
                    child: Text("Pilih Tanggal: ${DateFormat('dd-MM-yyyy').format(dialogSelectedDate)}"),
                  ),
                  DropdownButton<BudgetingCategory>(
                    value: selectedBudgetingCategory,
                    hint: const Text('Pilih Kategori'),
                    isExpanded: true,
                    items: availableCategories.map((category) => DropdownMenuItem<BudgetingCategory>(
                              value: category,
                              child: Text(category.category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedBudgetingCategory = value;
                      });
                    },
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Masukkan Nominal"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedBudgetingCategory == null || amountController.text.isEmpty) {
                      _showErrorDialog('Kategori dan Nominal tidak boleh kosong.');
                      return;
                    }

                    int? amount = int.tryParse(amountController.text);
                    if (amount == null) {
                      _showErrorDialog('Nominal harus berupa angka valid.');
                      return;
                    }

                    if (selectedBudgetingCategory!.type == 'pengeluaran') {
                      final double currentRemainingLimit = selectedBudgetingCategory!.remainingLimit ?? 0.0;
                      if (amount > currentRemainingLimit) {
                        _showErrorDialog('Pengeluaran melebihi sisa limit Anda (${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(currentRemainingLimit)}).');
                        return;
                      }
                    }

                    _addTransactionToApi(
                      selectedBudgetingCategory!.id,
                      dialogSelectedDate,
                      selectedBudgetingCategory!.type,
                      amount,
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
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
    final List<Map<String, dynamic>> filteredTransactions = transaksiRecords
        .where((t) => t['isIncome'] == isIncomeSelected)
        .toList();

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
                      value: _selectedMonthForTransactions,
                      underline: const SizedBox(),
                      
                      items: _availableMonthsForTransactions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value), 
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonthForTransactions = value!;
                        });
                        _fetchTransactions();
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
                          : filteredTransactions.isEmpty
                              ? Center(
                                  child: Text(
                                    isIncomeSelected
                                        ? 'Tidak ada transaksi pemasukan untuk bulan ini.'
                                        : 'Tidak ada transaksi pengeluaran untuk bulan ini.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : SingleChildScrollView( 
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Tanggal')),
                                      DataColumn(label: Text('Kategori')),
                                      DataColumn(label: Text('Nominal')),
                                    ],
                                    rows: filteredTransactions.map((transaksi) {
                                      return DataRow(cells: [
                                        DataCell(Text(DateFormat('dd MMMM yyyy', 'id').format(transaksi['transaction_date']))), // Format tanggal yang benar
                                        DataCell(Text(transaksi['category'])),
                                        DataCell(Text('Rp ${NumberFormat.decimalPattern().format(transaksi['amount'])}')),
                                      ]);
                                    }).toList(),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A90E2),
        onPressed: _showAddTransactionDialog,
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
            List<String> incomeCategoryNames = widget.allBudgetingCategories.where((c) => c.type == 'pemasukan').map((c) => c.category).toList();
            List<String> expenseCategoryNames = widget.allBudgetingCategories.where((c) => c.type == 'pengeluaran').map((c) => c.category).toList();

            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BudgetingPage(authToken: widget.authToken)),
                );
                break;
              case 1:
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