import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool dailyReminder = true;
  bool isLoading = true;
  User? user;
  late NumberFormat formatCurrency;

  @override
  void initState() {
    super.initState();
    formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    _fetchUserData();
  }

  void handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _fetchUserData() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          user = User.fromJson(data['data']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
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
          "Profil Pengguna",
          style: TextStyle(
            color: const Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              // TODO: implement profile editing
            },
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile header
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://api.dicebear.com/7.x/pixel-art/svg?seed=${user?.name ?? "user"}',
                                placeholder:
                                    (context, url) => Text(
                                      user?.name
                                              .substring(0, 1)
                                              .toUpperCase() ??
                                          '',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Text(
                                      user?.name
                                              .substring(0, 1)
                                              .toUpperCase() ??
                                          '',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Halo, ${user?.name ?? ''} 👋",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Financial summary
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                            "Ringkasan Keuangan Bulan Ini",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildFinancialItem(
                            "Total Pemasukan",
                            user?.monthlyStats['income'] ?? 0,
                            Icons.arrow_upward,
                            Colors.green,
                          ),
                          Divider(height: 24),
                          _buildFinancialItem(
                            "Total Pengeluaran",
                            user?.monthlyStats['expense'] ?? 0,
                            Icons.arrow_downward,
                            Colors.red,
                          ),
                          Divider(height: 24),
                          _buildFinancialItem(
                            "Total Tabungan",
                            user?.monthlyStats['savings'] ?? 0,
                            Icons.savings_outlined,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    // Settings section
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                            "Pengaturan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildSettingItem(
                            "Pengingat Harian",
                            Icons.notifications_outlined,
                            Switch(
                              value: dailyReminder,
                              onChanged:
                                  (val) => setState(() => dailyReminder = val),
                              activeColor: Colors.teal,
                            ),
                          ),
                          _buildSettingItem(
                            "Tema Aplikasi",
                            Icons.palette_outlined,
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ),
                          _buildSettingItem(
                            "Bantuan",
                            Icons.help_outline,
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ),
                          Divider(height: 32),
                          GestureDetector(
                            onTap: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: Text("Keluar dari akun? 😢"),
                                      content: Text(
                                        "Kamu yakin ingin logout dari aplikasi?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: Text(
                                            "Batal",
                                            style: TextStyle(
                                              color: const Color.fromARGB(
                                                255,
                                                0,
                                                0,
                                                0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: Text(
                                            "Keluar",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (shouldLogout ?? false) handleLogout();
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.logout, color: Colors.red),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "Keluar",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.red),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildFinancialItem(
    String label,
    dynamic amount, // Accepts both int and String
    IconData icon,
    Color color,
  ) {
    // Convert amount to an integer
    final int value = amount is String ? int.parse(amount) : amount as int;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 4),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: Duration(milliseconds: 800),
                builder: (context, val, _) {
                  return Text(
                    formatCurrency.format(val),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String label, IconData icon, Widget trailing) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600]),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
