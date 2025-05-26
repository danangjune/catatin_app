import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/transactions'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];

        setState(() {
          // Convert backend data format to match our UI format
          transactions =
              data
                  .map(
                    (tx) => {
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
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedType == 'Semua') return transactions;
    return transactions.where((t) => t['type'] == selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            color: const Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF20BF55)),
                ),
              )
              : RefreshIndicator(
                onRefresh: fetchTransactions,
                child: Column(
                  children: [
                    // Filter Section
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.grey[600]),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedType,
                                isExpanded: true,
                                items:
                                    ['Semua', 'Pemasukan', 'Pengeluaran'].map((
                                      type,
                                    ) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => selectedType = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Summary Section
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

                    // Transactions List
                    Expanded(
                      child:
                          filteredTransactions.isEmpty
                              ? Center(
                                child: Text(
                                  'Tidak ada transaksi',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: filteredTransactions.length,
                                itemBuilder: (context, index) {
                                  final tx = filteredTransactions[index];
                                  final numberFormat = NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  );
                                  final date = DateFormat(
                                    'dd MMM yyyy',
                                  ).format(DateTime.parse(tx['date']));

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (tx['type'] == 'Pemasukan'
                                                  ? Colors.green
                                                  : Colors.red)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          tx['type'] == 'Pemasukan'
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color:
                                              tx['type'] == 'Pemasukan'
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                      title: Text(
                                        tx['description'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tx['category'],
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            date,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        numberFormat.format(tx['amount']),
                                        style: TextStyle(
                                          color:
                                              tx['type'] == 'Pemasukan'
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
    );
  }
}
