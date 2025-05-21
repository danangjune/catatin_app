import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedType = 'Semua';

  List<Map<String, dynamic>> allTransactions = [
    {
      'type': 'Pemasukan',
      'amount': 1500000,
      'category': 'Gaji',
      'description': 'Gaji Bulanan',
      'date': '2025-05-01',
    },
    {
      'type': 'Pengeluaran',
      'amount': 50000,
      'category': 'Makan',
      'description': 'Makan siang',
      'date': '2025-05-02',
    },
    {
      'type': 'Pengeluaran',
      'amount': 100000,
      'category': 'Transportasi',
      'description': 'Isi bensin',
      'date': '2025-05-03',
    },
    {
      'type': 'Pemasukan',
      'amount': 250000,
      'category': 'Freelance',
      'description': 'Proyek desain',
      'date': '2025-05-05',
    },
  ];

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedType == 'Semua') return allTransactions;
    return allTransactions.where((t) => t['type'] == selectedType).toList();
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
      body: Column(
        children: [
          // Filter Section
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          ['Semua', 'Pemasukan', 'Pengeluaran'].map((type) {
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
                        if (val != null) setState(() => selectedType = val);
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
                      .fold(0, (sum, tx) => sum + tx['amount'] as int),
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
                      .fold(0, (sum, tx) => sum + (tx['amount'] as int)),
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
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
                        borderRadius: BorderRadius.circular(8),
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
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx['category'],
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          tx['date'],
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Text(
                      "Rp ${tx['amount']}",
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
    );
  }

  Widget _buildSummaryItem(
    String label,
    int amount,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
        SizedBox(height: 8),
        Text(
          "Rp $amount",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
