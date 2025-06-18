import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../widgets/bottom_nav.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({Key? key}) : super(key: key);

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final TextEditingController _targetController = TextEditingController();
  bool isLoading = true;
  int _target = 0;
  int _saved = 0;
  String? _savingId;

  @override
  void initState() {
    super.initState();
    fetchCurrentMonthSaving();
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
        }
      } else {
        await createNewMonthlySaving();
      }
    } catch (e) {
      print('Error fetching savings: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil data tabungan')));
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

      print('Create response: ${response.statusCode}');
      print('Create body: ${response.body}');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat data tabungan baru')),
      );
    }
  }

  Future<void> _updateTarget() async {
    if (_targetController.text.isEmpty || _savingId == null) return;

    try {
      final newTarget = int.tryParse(_targetController.text);
      if (newTarget == null) return;

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
          _targetController.clear();
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
        final controller = TextEditingController();
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
              child: Text("Batal", style: TextStyle(color: Colors.grey)),
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
              child: Text("Simpan"),
              onPressed: () async {
                final tambah = int.tryParse(controller.text);
                if (tambah != null && _savingId != null) {
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
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double progress = (_saved / _target).clamp(0.0, 1.0);

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
          style: TextStyle(
            color: const Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: 85.0), // Add padding for bottom nav
          child: Column(
            children: [
              // Header Card with Progress
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
                      "Rp ${_target.toString()}",
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
                          widthFactor: progress,
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
                          "Terkumpul: Rp $_saved",
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
                            "${(progress * 100).toInt()}%",
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

              // Update Target Section
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
                      offset: Offset(0, 2),
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
                        enabledBorder: OutlineInputBorder(
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

              // Quick Actions
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
                        icon: Icons.history,
                        label: "Riwayat",
                        onTap: () {
                          Navigator.pushNamed(context, '/history');
                        },
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
      ), // Use index 1 for savings
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
