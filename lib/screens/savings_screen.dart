import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({Key? key}) : super(key: key);

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final MoneyMaskedTextController _targetController = MoneyMaskedTextController(
    decimalSeparator: '',
    thousandSeparator: '.',
    precision: 0,
    leftSymbol: 'Rp ',
  );

  bool isLoading = true;
  int _target = 0;
  int _saved = 0;
  String? _savingId;
  List<Map<String, dynamic>> _savingHistory = [];
  List<Map<String, dynamic>> _dailyLogs = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentMonthSaving();
    fetchHistory();
    fetchSavingLogs();
  }

  Future<void> fetchSavingLogs() async {
    try {
      final token = await AuthService.getToken();
      final now = DateTime.now();
      final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/savings/logs?month=$monthStr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> logs = json.decode(response.body);
        setState(() {
          _dailyLogs =
              logs
                  .map<Map<String, dynamic>>(
                    (log) => {'date': log['date'], 'amount': log['amount']},
                  )
                  .toList();
        });
      }
    } catch (e) {
      print('Error fetching saving logs: $e');
    }
  }

  Future<void> fetchHistory() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/savings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final currentMonth = DateFormat('yyyy-MM-01').format(DateTime.now());

        setState(() {
          _savingHistory =
              data
                  .map<Map<String, dynamic>>(
                    (s) => {
                      'month': s['month'],
                      'target': s['target_amount'],
                      'saved': s['saved_amount'],
                    },
                  )
                  .where((item) => item['month'] != currentMonth)
                  .toList();
        });
      }
    } catch (e) {
      print('Gagal fetch saving history: $e');
    }
  }

  Future<void> fetchCurrentMonthSaving() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthService.getToken();
      final now = DateTime.now();
      final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/api/v1/savings/monthly?month=$monthStr',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null) {
          setState(() {
            _target = responseData['target_amount'] ?? 0;
            _saved = responseData['saved_amount'] ?? 0;
            _savingId = responseData['id'].toString();
            isLoading = false;
          });
        } else {
          await createNewMonthlySaving();
          await fetchHistory();
        }
      } else {
        await createNewMonthlySaving();
        await fetchHistory();
      }
    } catch (e) {
      print('Error fetching savings: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> createNewMonthlySaving() async {
    try {
      final token = await AuthService.getToken();
      final now = DateTime.now();
      final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-01";

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/savings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode({
          'target_amount': 2000000,
          'saved_amount': 0,
          'month': monthStr,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        setState(() {
          _target = responseData['target_amount'];
          _saved = responseData['saved_amount'];
          _savingId = responseData['id'].toString();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error creating saving: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateTarget() async {
    if (_targetController.numberValue <= 0 || _savingId == null) return;

    try {
      final newTarget = _targetController.numberValue.toInt();
      final token = await AuthService.getToken();

      final response = await http.patch(
        Uri.parse('http://localhost:8000/api/v1/savings/$_savingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode({'target_amount': newTarget}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _target = data['target_amount'];
          _targetController.updateValue(0);
        });
      }
    } catch (e) {
      print('Error updating target: $e');
    }
  }

  Future<void> _addSavings() async {
    showDialog(
      context: context,
      builder: (_) {
        final controller = MoneyMaskedTextController(
          decimalSeparator: '',
          thousandSeparator: '.',
          precision: 0,
          leftSymbol: 'Rp ',
        );
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Tambah Tabungan",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Jumlah (Rp)",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "Batal",
                style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "Simpan",
                style: TextStyle(
                  color: const Color.fromARGB(255, 253, 253, 253),
                ),
              ),
              onPressed: () async {
                final tambah = controller.numberValue.toInt();
                if (tambah > 0 && _savingId != null) {
                  try {
                    final token = await AuthService.getToken();
                    final response = await http.patch(
                      Uri.parse(
                        'http://localhost:8000/api/v1/savings/$_savingId',
                      ),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                      },
                      body: json.encode({'add_amount': tambah}),
                    );

                    if (response.statusCode == 200) {
                      final data = json.decode(response.body);
                      setState(() => _saved = data['saved_amount']);
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    print('Error adding savings: $e');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final percent = (_target == 0) ? 0.0 : (_saved / _target).clamp(0.0, 1.0);

    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          "Target Tabungan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(
          color: const Color.fromARGB(221, 255, 255, 255),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 85),
        child: Column(
          children: [
            // Header with progress
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Target Bulanan",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    currency.format(_target),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percent,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Terkumpul: ${currency.format(_saved)}",
                        style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${(percent * 100).toInt()}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Target edit
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ubah Target",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Target Baru (Rp)",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.check_circle_outline),
                        color: Colors.teal,
                        onPressed: _updateTarget,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions (refactored)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.add_circle_outline,
                      label: "Tambah Tabungan",
                      onTap: _addSavings,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.analytics_outlined,
                      label: "Evaluasi",
                      onTap: () => Navigator.pushNamed(context, '/evaluation'),
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            // Savings history
            if (_savingHistory.isNotEmpty)
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Tabungan Bulan Sebelumnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._savingHistory.map((item) {
                      final formattedMonth = DateFormat(
                        'MMMM yyyy',
                        'id_ID',
                      ).format(DateTime.parse(item['month']));
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.teal,
                        ),
                        title: Text(formattedMonth),
                        subtitle: Text(
                          'Terkumpul: ${currency.format(item['saved'])} / Target: ${currency.format(item['target'])}',
                          style: TextStyle(fontSize: 13),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            if (_dailyLogs.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Menabung Harian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._dailyLogs.map((log) {
                      final tanggal = DateFormat(
                        'dd MMM yyyy',
                        'id_ID',
                      ).format(DateTime.parse(log['date']));
                      final jumlah = NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(log['amount']);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.date_range,
                          color: Colors.teal,
                          size: 20,
                        ),
                        title: Text(tanggal),
                        subtitle: Text("Menabung: $jumlah"),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 65,
        width: 65,
        margin: EdgeInsets.only(bottom: 15),
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/add'),
            backgroundColor: Color(0xFF20BF55),
            elevation: 4,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
