import 'dart:math'; // Untuk fungsi max
import 'dart:convert'; // Untuk JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Untuk grafik PieChart
import 'package:http/http.dart' as http; // Untuk permintaan HTTP
import 'budgeting_page.dart'; // Import ini untuk akses BudgetingCategory dan modelnya
import 'pencatatan_page.dart';
import 'profile_page.dart';
import 'package:intl/intl.dart'; // Untuk pemformatan tanggal
import 'package:collection/collection.dart'; // Untuk firstWhereOrNull

class LaporanPage extends StatefulWidget {
  final String authToken;

  const LaporanPage({Key? key, required this.authToken}) : super(key: key);

  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int _selectedMenuIndex = 2;
  String selectedPeriode = 'Bulanan'; // Default to Monthly
  DateTime selectedDate = DateTime.now();
  bool isIncomeSelected = true; // Untuk toggle Pie Chart Pemasukan/Pengeluaran
  bool _isLoading = true;
  final Random random = Random();
  Map<String, Color> kategoriColors = {};

  List<BudgetingCategory> _allBudgetingCategories = []; // Menyimpan semua kategori dari API (untuk mendapatkan limit)
  List<Map<String, dynamic>> _allTransactions = []; // Semua transaksi mentah dari API untuk agregasi di frontend

  double totalIncome = 0.0;
  double totalExpense = 0.0;

  final String _baseUrl = 'http://192.168.56.111:9999'; // Base URL API Anda

  @override
  void initState() {
    super.initState();
    _fetchReportData(); // Ambil data laporan saat inisialisasi
  }

  // Fungsi untuk mengambil data yang dibutuhkan LaporanPage (kategori & transaksi mentah)
  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _allBudgetingCategories.clear();
      _allTransactions.clear(); // Bersihkan transaksi mentah
      totalIncome = 0.0;
      totalExpense = 0.0;
    });

    // Sesuaikan parameter bulan untuk API, karena API /budgeting?month hanya mendukung YYYY-MM
    String monthYearForBudgeting = DateFormat('yyyy-MM').format(selectedDate);
    final urlBudgeting = Uri.parse('$_baseUrl/budgeting?month=$monthYearForBudgeting');

    try {
      final responseBudgeting = await http.get(
        urlBudgeting,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );
      if (responseBudgeting.statusCode == 200) {
        final dynamic decodedDataBudgeting = jsonDecode(responseBudgeting.body);
        if (decodedDataBudgeting is List) {
          List<BudgetingCategory> tempCategories = [];
          for (var item in decodedDataBudgeting) {
            if (item is Map<String, dynamic> && item.containsKey('id') && item.containsKey('category') && item.containsKey('type')) {
              try {
                tempCategories.add(BudgetingCategory.fromJson(item));
              } catch (e) {
                print('Error parsing BudgetingCategory from JSON: $e, Item: $item');
              }
            } else {
              print('Skipping malformed budgeting category item: $item');
            }
          }
          _allBudgetingCategories = tempCategories;
        } else {
          print('Warning: Budgeting API response format unexpected.');
        }
      } else {
        print('Error fetching budgeting categories: Status ${responseBudgeting.statusCode}.');
      }
    } catch (e) {
      print('Exception fetching budgeting categories: $e');
      _showErrorDialog('Gagal menghubungi server untuk memuat kategori budgeting.');
    }

    // Ambil data transaksi mentah untuk periode yang dipilih
    // Karena API /transactions hanya menerima 'month', kita akan selalu kirim month.
    String monthYearForTransactions = DateFormat('yyyy-MM').format(selectedDate);
    final urlTransactions = Uri.parse('$_baseUrl/transactions?month=$monthYearForTransactions');

    try {
      final responseTransactions = await http.get(
        urlTransactions,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      print('Laporan - Transactions Status code: ${responseTransactions.statusCode}');
      print('Laporan - Transactions Response body: ${responseTransactions.body}');

      if (responseTransactions.statusCode == 200) {
        final dynamic decodedDataTransactions = jsonDecode(responseTransactions.body);
        if (decodedDataTransactions is List) {
          List<Map<String, dynamic>> fetchedTransactions = [];
          for (var item in decodedDataTransactions) {
            // Perbaiki null check untuk memastikan semua kunci yang dibutuhkan ada dan bukan null
            if (item is Map<String, dynamic> &&
                item.containsKey('id') &&
                item.containsKey('transaction_date') &&
                item.containsKey('category') &&
                item.containsKey('amount') &&
                item.containsKey('type')) {
              fetchedTransactions.add({
                'id': item['id'],
                'transaction_date': DateTime.tryParse(item['transaction_date'] as String? ?? '') ?? DateTime.now(), // Handle null transaction_date
                'category': item['category'] as String? ?? 'Unknown Category', // Add null check and default
                'amount': (item['amount'] as num?)?.toDouble() ?? 0.0, // Ensure double, handle null
                'type': item['type'] as String? ?? 'unknown', // Add null check and default
              });
            } else {
              print('Skipping malformed transaction item: $item');
            }
          }
          _allTransactions = fetchedTransactions;

          // Agregasi total pemasukan dan pengeluaran dari transaksi mentah yang diambil
          double currentTotalIncome = 0.0;
          double currentTotalExpense = 0.0;

          // Agregasi berdasarkan `selectedPeriode` dari _allTransactions
          // Ini adalah logika untuk memfilter transaksi mentah berdasarkan periode di frontend
          List<Map<String, dynamic>> filteredTransactionsByPeriod = [];
          if (selectedPeriode == 'Harian') {
            filteredTransactionsByPeriod = _allTransactions.where((t) =>
                DateFormat('yyyy-MM-dd').format(DateTime.tryParse(t['transaction_date'] ?? '') ?? DateTime.now()) == DateFormat('yyyy-MM-dd').format(selectedDate)
            ).toList();
          } else if (selectedPeriode == 'Mingguan') {
            DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday));
            DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
            filteredTransactionsByPeriod = _allTransactions.where((t) {
              DateTime transactionDate = DateTime.tryParse(t['transaction_date'] ?? '') ?? DateTime.now();
              return transactionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && transactionDate.isBefore(endOfWeek.add(const Duration(days: 1)));
            }).toList();
          } else if (selectedPeriode == 'Bulanan') {
            // Jika bulanan, kita sudah ambil semua transaksi di bulan itu
            filteredTransactionsByPeriod = _allTransactions;
          } else if (selectedPeriode == 'Tahunan') {
            filteredTransactionsByPeriod = _allTransactions.where((t) =>
                (DateTime.tryParse(t['transaction_date'] ?? '') ?? DateTime.now()).year == selectedDate.year
            ).toList();
          }

          // Hitung total dari filteredTransactionsByPeriod
          for (var item in filteredTransactionsByPeriod) {
            double amount = (item['amount'] as double?) ?? 0.0; // Use as double? to handle potential null from map
            String type = (item['type'] as String?) ?? 'unknown'; // Ensure type is handled as string, default 'unknown'
            if (type == 'pemasukan') {
              currentTotalIncome += amount;
            } else if (type == 'pengeluaran') {
              currentTotalExpense += amount;
            }
          }

          totalIncome = currentTotalIncome;
          totalExpense = currentTotalExpense;

        } else {
          _showErrorDialog('Laporan - Format respons transaksi tidak sesuai: bukan list.');
        }
      } else {
        _showErrorDialog('Laporan - Gagal memuat transaksi laporan: Status ${responseTransactions.statusCode}. Pesan: ${jsonDecode(responseTransactions.body)['message'] ?? 'Tidak ada pesan.'}');
      }
    } catch (e) {
      print('Exception fetching transactions for report: $e');
      _showErrorDialog('Laporan - Gagal menghubungi server untuk memuat transaksi laporan.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk memilih tanggal
  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchReportData(); // Refresh data saat tanggal berubah
    }
  }

  // Mendapatkan warna unik untuk setiap kategori
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

  // Fungsi untuk menampilkan dialog error
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
    // Data untuk Pie Chart dan Tabel (berdasarkan isIncomeSelected)
    List<PieChartSectionData> pieChartSections = [];
    List<Map<String, dynamic>> tableRecords = []; // Data untuk tabel
    double currentPieTotal = 0.0;

    // Agregasi data transaksi mentah untuk Pie Chart dan Tabel berdasarkan selectedPeriode
    // Filter _allTransactions berdasarkan selectedPeriode sebelum agregasi
    List<Map<String, dynamic>> transactionsForCurrentPeriod = [];
    if (selectedPeriode == 'Harian') {
      transactionsForCurrentPeriod = _allTransactions.where((t) =>
          DateFormat('yyyy-MM-dd').format(DateTime.tryParse(t['transaction_date'] ?? '') ?? DateTime.now()) == DateFormat('yyyy-MM-dd').format(selectedDate)
      ).toList();
    } else if (selectedPeriode == 'Mingguan') {
      DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday)); // Minggu adalah hari pertama
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sabtu adalah hari terakhir
      transactionsForCurrentPeriod = _allTransactions.where((t) {
        DateTime transactionDate = DateTime.tryParse(t['transaction_date'] ?? '') ?? DateTime.now();
        return transactionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && transactionDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else if (selectedPeriode == 'Bulanan') {
      transactionsForCurrentPeriod = _allTransactions; // _allTransactions sudah difilter per bulan
    } else if (selectedPeriode == 'Tahunan') {
      transactionsForCurrentPeriod = _allTransactions.where((t) =>
          (DateTime.tryParse(t['transaction_date'] ?? '') ?? DateTime.now()).year == selectedDate.year
      ).toList();
    }

    Map<String, double> aggregatedDataForDisplay = {};
    transactionsForCurrentPeriod.forEach((transaction) {
      String type = (transaction['type'] as String?) ?? 'unknown'; // Tambahkan null check
      String category = (transaction['category'] as String?) ?? 'Unknown Category'; // Tambahkan null check
      double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

      if ((isIncomeSelected && type == 'pemasukan') || (!isIncomeSelected && type == 'pengeluaran')) {
        aggregatedDataForDisplay.update(category, (value) => value + amount, ifAbsent: () => amount);
      }
    });

    currentPieTotal = isIncomeSelected ? totalIncome : totalExpense; // Total ini sudah dihitung berdasarkan filtered _allTransactions

    aggregatedDataForDisplay.forEach((category, amount) {
      BudgetingCategory? budgetCat = _allBudgetingCategories.firstWhereOrNull(
          (cat) => cat.category == category && cat.type == (isIncomeSelected ? 'pemasukan' : 'pengeluaran'));

      if (amount > 0) {
        pieChartSections.add(
          PieChartSectionData(
            value: amount,
            title: '${category}\n${((amount / currentPieTotal) * 100).toStringAsFixed(1)}%',
            color: getKategoriColor(category),
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      }

      if (isIncomeSelected) {
        tableRecords.add({
          'kategori': category,
          'total': amount,
          'persentase_total': currentPieTotal > 0 ? (amount / currentPieTotal) * 100 : 0.0,
        });
      } else { // Pengeluaran
        double limit = budgetCat?.limitAmount ?? 0.0; // Ambil limit dari data budgeting
        tableRecords.add({
          'kategori': category,
          'total': amount,
          'persentase_total': currentPieTotal > 0 ? (amount / currentPieTotal) * 100 : 0.0,
          'limit': limit,
          'persentase_limit': limit > 0 ? (amount / limit) * 100 : 0.0,
        });
      }
    });

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
                                _fetchReportData(); // Refresh data saat periode berubah
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _pickDate,
                            child: Text('Tanggal: ${DateFormat('dd-MM-yyyy').format(selectedDate)}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 20),
                    // Pie Chart Pemasukan/Pengeluaran
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : pieChartSections.isEmpty && (totalIncome == 0 && totalExpense == 0)
                            ? const Center(child: Text('Tidak ada data untuk Pie Chart periode ini.'))
                            : SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: pieChartSections,
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                              ),
                    const SizedBox(height: 20),
                    // Tabel Data
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : tableRecords.isEmpty
                              ? Center(
                                  child: Text(
                                    isIncomeSelected
                                        ? 'Tidak ada data pemasukan dalam tabel untuk periode ini.'
                                        : 'Tidak ada data pengeluaran dalam tabel untuk periode ini.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal, // Agar tabel bisa di-scroll horizontal
                                  child: DataTable(
                                    columns: isIncomeSelected
                                        ? const [
                                            DataColumn(label: Text('Kategori')),
                                            DataColumn(label: Text('% Total')),
                                            DataColumn(label: Text('Total/Kategori')),
                                          ]
                                        : const [
                                            DataColumn(label: Text('Kategori')),
                                            DataColumn(label: Text('% Total')),
                                            DataColumn(label: Text('Total/Kategori')),
                                            DataColumn(label: Text('% Limit')),
                                            DataColumn(label: Text('Limit')),
                                          ],
                                    rows: tableRecords.map((record) {
                                      return DataRow(cells: [
                                        DataCell(Text(record['kategori'].toString())),
                                        DataCell(Text('${record['persentase_total'].toStringAsFixed(1)}%')),
                                        DataCell(Text('Rp ${NumberFormat.decimalPattern().format(record['total'])}')),
                                        if (!isIncomeSelected) ...[
                                          DataCell(Text('${record['persentase_limit'].toStringAsFixed(1)}%')),
                                          DataCell(Text('Rp ${NumberFormat.decimalPattern().format(record['limit'])}')),
                                        ],
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
            List<String> incomeCategoryNames = _allBudgetingCategories.where((c) => c.type == 'pemasukan').map((c) => c.category).toList();
            List<String> expenseCategoryNames = _allBudgetingCategories.where((c) => c.type == 'pengeluaran').map((c) => c.category).toList();

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
                    tipePemasukan: incomeCategoryNames,
                    tipePengeluaran: expenseCategoryNames,
                    allBudgetingCategories: _allBudgetingCategories,
                  )),
                );
                break;
              case 2:
                // Sudah di LaporanPage, tidak perlu navigasi ulang
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