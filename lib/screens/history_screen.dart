import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedType = 'Semua';
  bool isLoading = true;
  List<Map<String, dynamic>> transactions = [];

  Widget _buildSummaryItem(
    String label,
    int amount,
    IconData icon,
    Color color,
  ) {
    final numberFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          numberFormat.format(amount),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];

        setState(() {
          transactions =
              data
                  .map(
                    (tx) => {
                      'id': tx['id'],
                      'type':
                          tx['type'] == 'income' ? 'Pemasukan' : 'Pengeluaran',
                      'amount': tx['amount'],
                      'category': tx['category'],
                      'description': tx['description'],
                      'date': tx['date'],
                    },
                  )
                  .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil data transaksi');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Hapus Transaksi'),
            content: Text('Yakin ingin menghapus transaksi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Hapus'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final token = await AuthService.getToken();
      final res = await http.delete(
        Uri.parse('http://localhost:8000/api/v1/transactions/${tx['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Transaksi dihapus")));
        fetchTransactions();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menghapus")));
      }
    }
  }

  Future<void> _confirmEdit(Map<String, dynamic> tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Edit Transaksi'),
            content: Text('Ingin mengedit transaksi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal'),
              ),
              ElevatedButton(
                child: Text('Edit'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      Navigator.pushNamed(context, '/edit', arguments: tx);
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'makan':
      case 'makan & minum':
        return Icons.restaurant;
      case 'transportasi':
        return Icons.directions_car;
      case 'hiburan':
        return Icons.movie;
      case 'belanja':
        return Icons.shopping_cart;
      case 'gaji':
      case 'bonus':
        return Icons.attach_money;
      case 'tak terduga':
        return Icons.warning_amber_rounded;
      case 'hadiah':
        return Icons.card_giftcard;
      default:
        return Icons.receipt_long;
    }
  }

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedType == 'Semua') return transactions;
    return transactions.where((t) => t['type'] == selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF20BF55), Color(0xFF01BAEF)],
            ),
          ),
        ),
        title: Text(
          "Riwayat Transaksi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchTransactions,
                child: Column(
                  children: [
                    // Filter dropdown
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        items:
                            ['Semua', 'Pemasukan', 'Pengeluaran']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => selectedType = val!),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.filter_list),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Summary
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            "Pemasukan",
                            filteredTransactions
                                .where((t) => t['type'] == 'Pemasukan')
                                .fold(
                                  0,
                                  (sum, tx) => sum + (tx['amount'] as int),
                                ),
                            Icons.arrow_downward,
                            Colors.green,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildSummaryItem(
                            "Pengeluaran",
                            filteredTransactions
                                .where((t) => t['type'] == 'Pengeluaran')
                                .fold(
                                  0,
                                  (sum, tx) => sum + (tx['amount'] as int),
                                ),
                            Icons.arrow_upward,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),

                    // List Transaksi
                    Expanded(
                      child:
                          filteredTransactions.isEmpty
                              ? Center(child: Text('Tidak ada transaksi'))
                              : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: filteredTransactions.length,
                                itemBuilder: (context, index) {
                                  final tx = filteredTransactions[index];
                                  final color =
                                      tx['type'] == 'Pemasukan'
                                          ? Colors.green
                                          : Colors.red;
                                  return Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => _confirmEdit(tx),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                _getIconForCategory(
                                                  tx['category'],
                                                ),
                                                color: color,
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx['description'],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.grey[100],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          tx['category'],
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        DateFormat(
                                                          'dd MMM yyyy',
                                                        ).format(
                                                          DateTime.parse(
                                                            tx['date'],
                                                          ),
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  numberFormat.format(
                                                    tx['amount'],
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: color,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red.shade300,
                                                    size: 18,
                                                  ),
                                                  onPressed:
                                                      () => _confirmDelete(tx),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: Container(
        height: 65,
        width: 65,
        margin: EdgeInsets.only(bottom: 15),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/add'),
          backgroundColor: Color(0xFF20BF55),
          elevation: 4,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(currentIndex: 3),
    );
  }
}
