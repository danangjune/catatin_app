import 'package:flutter/material.dart';
import 'alert_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:catatin_app/utils/score_calculator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Map<String, dynamic>> alerts = [];
  List<dynamic> transactions = [];
  bool isLoading = true;
  int pemasukan = 0;
  int pengeluaran = 0;
  double evaluationScore = 0.0;
  String evaluationCategory = "Memuat...";
  bool isEvaluationLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
    fetchEvaluation();
  }

  Future<void> fetchEvaluation() async {
    try {
      final now = DateTime.now();
      final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/api/v1/transactions/evaluation?month=$monthStr',
        ),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'];

        // 1. Rasio pemasukan/pengeluaran
        final income = data['total_income'] ?? 0;
        final expense = data['total_expense'] ?? 0;
        final ratio = income > 0 ? expense / income : 0;

        // Hitung scores dengan cara yang sama seperti di EvaluationScreen
        final scores = {
          'income_ratio': _calculateIncomeRatio(ratio),
          'saving_consistency': _calculateSavingConsistency(
            data['saving_consistency'] ?? 0,
          ),
          'unexpected_expense': _calculateUnexpectedExpense(
            income > 0 ? (data['unexpected_expense'] ?? 0) / income : 0,
          ),
          'record_frequency': _calculateRecordFrequency(
            data['record_days'] ?? 0,
          ),
          'saving_percentage': _calculateSavingPercentage(
            income > 0 ? ((data['saving_consistency'] ?? 0) / 4) * 20 : 0,
          ),
        };

        // Calculate weighted score
        final rawScore = ScoreCalculator.calculateFinalScore(scores);

        setState(() {
          evaluationScore = rawScore;
          evaluationCategory = _getCategory(rawScore);
          isEvaluationLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching evaluation: $e');
      setState(() => isEvaluationLoading = false);
    }
  }

  // Update scoring methods to match EvaluationScreen
  double _calculateIncomeRatio(double ratio) {
    if (ratio <= 0.5) return 5; // Pengeluaran <= 50% pemasukan
    if (ratio <= 0.7) return 4; // Pengeluaran <= 70% pemasukan
    if (ratio <= 0.9) return 3; // Pengeluaran <= 90% pemasukan
    if (ratio <= 1.0) return 2; // Pengeluaran <= 100% pemasukan
    return 1; // Pengeluaran > 100% pemasukan
  }

  double _calculateSavingConsistency(int consistency) {
    if (consistency >= 4) return 5; // Menabung >= 4 minggu
    if (consistency >= 3) return 4; // Menabung 3 minggu
    if (consistency >= 2) return 3; // Menabung 2 minggu
    if (consistency >= 1) return 2; // Menabung 1 minggu
    return 1; // Tidak menabung
  }

  double _calculateUnexpectedExpense(double ratio) {
    if (ratio <= 0.05) return 5; // Pengeluaran tak terduga <= 5% pemasukan
    if (ratio <= 0.10) return 4; // <= 10%
    if (ratio <= 0.15) return 3; // <= 15%
    if (ratio <= 0.20) return 2; // <= 20%
    return 1; // > 20%
  }

  double _calculateRecordFrequency(int days) {
    if (days >= 25) return 5; // Mencatat >= 25 hari
    if (days >= 20) return 4; // >= 20 hari
    if (days >= 15) return 3; // >= 15 hari
    if (days >= 10) return 2; // >= 10 hari
    return 1; // < 10 hari
  }

  double _calculateSavingPercentage(double percentage) {
    if (percentage >= 20) return 5; // >= 20%
    if (percentage >= 10) return 4; // 10-20%
    if (percentage > 0) return 2; // < 10% tapi > 0
    return 1; // 0%
  }

  String _getCategory(double score) {
    if (score >= 4.1) return "Baik 😊";
    if (score >= 3.1) return "Cukup 😐";
    return "Buruk 😟";
  }

  Color _getCategoryColor(double score) {
    if (score >= 4.1) return Colors.green;
    if (score >= 3.1) return Colors.orange;
    return Colors.red;
  }

  String _getRecommendation(double score) {
    if (score <= 3.0) {
      return "Mulai catat transaksi rutin dan kurangi pengeluaran tak terduga.";
    }
    if (score <= 4.0) {
      return "Pertahankan pencatatan rutin dan tingkatkan tabungan.";
    }
    return "Pertahankan kebiasaan baik ini. Keuangan Anda sehat!";
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/transactions'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          transactions = responseData['data'];

          // Hitung total pemasukan dan pengeluaran
          pemasukan = transactions
              .where((t) => t['type'] == 'income')
              .fold(0, (sum, t) => sum + (t['amount'] as int));

          pengeluaran = transactions
              .where((t) => t['type'] == 'expense')
              .fold(0, (sum, t) => sum + (t['amount'] as int));

          // Generate alerts berdasarkan data transaksi
          generateAlerts();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void generateAlerts() {
    alerts.clear();
    final now = DateTime.now();
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // 1. Cek Defisit
    if (pengeluaran > pemasukan) {
      alerts.add({
        'icon': Icons.warning_amber,
        'title': '⚠️ Waspada Defisit!',
        'color': Colors.orange,
        'description': 'Pengeluaran melebihi pemasukan bulan ini',
        'severity': 'high',
        'metadata': {
          'deficit_amount': pengeluaran - pemasukan,
          'expenses': pengeluaran,
          'income': pemasukan,
        },
      });
    }

    // 2. Cek Transaksi 7 Hari Terakhir
    final lastWeekDate = now.subtract(Duration(days: 7));
    final hasRecentTransactions = transactions.any(
      (t) => DateTime.parse(t['date']).isAfter(lastWeekDate),
    );

    if (!hasRecentTransactions) {
      alerts.add({
        'icon': Icons.edit_calendar,
        'title': '📝 Pencatatan Tidak Aktif',
        'color': Colors.blue,
        'description': 'Belum ada pencatatan transaksi dalam 7 hari terakhir',
        'severity': 'medium',
        'metadata': {
          'last_transaction_date':
              transactions.isNotEmpty ? transactions.first['date'] : null,
        },
      });
    }

    // 3. Cek Kategori Pengeluaran Tinggi
    final categoryTotals = {};
    for (var tx in transactions.where((t) => t['type'] == 'expense')) {
      final category = tx['category'] ?? 'Lainnya';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + tx['amount'];
    }

    categoryTotals.forEach((category, total) {
      if (total > (pemasukan * 0.4)) {
        final percentage = ((total / pemasukan) * 100).toStringAsFixed(1);
        alerts.add({
          'icon': Icons.pie_chart,
          'title': '📊 Pengeluaran $category Tinggi',
          'color': Colors.red,
          'description':
              'Pengeluaran kategori ini melebihi 40% dari pendapatan',
          'severity': 'high',
          'metadata': {
            'category': category,
            'amount': total,
            'percentage': percentage,
          },
        });
      }
    });

    // 4. Cek Tren Pemasukan
    final thisMonthIncome = transactions
        .where(
          (t) =>
              t['type'] == 'income' &&
              DateTime.parse(t['date']).month == now.month,
        )
        .fold(0, (sum, t) => sum + (t['amount'] as int));

    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthIncome = transactions
        .where(
          (t) =>
              t['type'] == 'income' &&
              DateTime.parse(t['date']).month == lastMonth.month,
        )
        .fold(0, (sum, t) => sum + (t['amount'] as int));

    if (thisMonthIncome < lastMonthIncome && lastMonthIncome > 0) {
      final decrease = ((lastMonthIncome - thisMonthIncome) /
              lastMonthIncome *
              100)
          .toStringAsFixed(1);
      alerts.add({
        'icon': Icons.trending_down,
        'title': '📉 Pendapatan Menurun',
        'color': Colors.red,
        'description': 'Penurunan pendapatan dari bulan lalu',
        'severity': 'high',
        'metadata': {
          'current_income': thisMonthIncome,
          'last_income': lastMonthIncome,
          'decrease_percentage': decrease,
        },
      });
    }

    // 5. Cek Target Tabungan
    final targetSavings = pemasukan * 0.2; // target 20% dari pendapatan
    final currentSavings = transactions
        .where(
          (t) =>
              t['type'] == 'savings' &&
              DateTime.parse(t['date']).month == now.month,
        )
        .fold(0, (sum, t) => sum + (t['amount'] as int));

    if (currentSavings < targetSavings) {
      final percentage = ((currentSavings / targetSavings) * 100)
          .toStringAsFixed(1);
      alerts.add({
        'icon': Icons.savings,
        'title': '💰 Target Menabung Belum Tercapai',
        'color': Colors.blue,
        'description': 'Target menabung bulan ini belum tercapai',
        'severity': 'medium',
        'metadata': {
          'target_amount': targetSavings,
          'current_savings': currentSavings,
          'percentage': percentage,
        },
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sisa = pemasukan - pengeluaran;
    final skorPersen = (evaluationScore * 20).toInt();
    final warnaKategori = _getCategoryColor(evaluationScore);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF20BF55), // Fresh modern green
                Color(0xFF01BAEF), // Modern blue
              ],
            ),
          ),
        ),
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CatatIn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Selamat Pagi, User! 👋',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (alerts.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${alerts.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                if (alerts.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AlertScreen(
                            alert: alerts[0],
                          ), // Bisa disesuaikan untuk menampilkan semua alert
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.person_outline_rounded, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section dengan gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.08),
                      spreadRadius: 8,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rangkuman Bulan Ini",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Mei 2025",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (sisa >= 0 ? Colors.green : Colors.red)
                                    .withOpacity(0.8),
                                (sisa >= 0
                                    ? Colors.green.shade300
                                    : Colors.red.shade300),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (sisa >= 0 ? Colors.green : Colors.red)
                                    .withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                sisa >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                sisa >= 0 ? "Surplus" : "Defisit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(
                              0xFF20BF55,
                            ), // Fresh modern green (sama dengan AppBar)
                            Color(
                              0xFF01BAEF,
                            ), // Modern blue (sama dengan AppBar)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF20BF55).withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCurrency.format(sisa),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween, // Ubah ke mainAxisAlignment
                            children: [
                              // Hapus Text yang menampilkan sisa untuk kedua kalinya
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "${((pemasukan - pengeluaran) / pemasukan * 100).toStringAsFixed(1)}%",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "dari pemasukan",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            "Pemasukan",
                            pemasukan,
                            Icons.arrow_upward,
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildBalanceCard(
                            "Pengeluaran",
                            pengeluaran,
                            Icons.arrow_downward,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Alerts Section
              if (alerts.isNotEmpty)
                Container(
                  margin: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Notifikasi Penting",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "${alerts.length} notifikasi",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ...alerts
                          .map(
                            (alert) => Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    alert['color'].withOpacity(0.15),
                                    Colors.white,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: alert['color'].withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                AlertScreen(alert: alert),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: alert['color'].withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: alert['color'].withOpacity(
                                                0.5,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            alert['icon'],
                                            color: alert['color'],
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                alert['title'],
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Ketuk untuk detail",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: alert['color'].withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: alert['color'],
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),

              // Financial Score Card
              Padding(
                padding: EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        warnaKategori.withOpacity(0.9),
                        warnaKategori.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: warnaKategori.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child:
                      isEvaluationLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Skor Keuangan",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "$skorPersen",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(bottom: 6),
                                            child: Text(
                                              "/100",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        evaluationScore >= 4.1
                                            ? Icons.sentiment_very_satisfied
                                            : evaluationScore >= 3.1
                                            ? Icons.sentiment_satisfied
                                            : Icons.sentiment_dissatisfied,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Kategori: $evaluationCategory",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Rekomendasi",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _getRecommendation(evaluationScore),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
              ),

              // Quick Actions Grid
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Menu Cepat",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio:
                          0.85, // Sesuaikan agar tidak terlalu kotak
                      padding: EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildQuickButton(
                          context,
                          Icons.add_circle_outlined,
                          "Tambah",
                          '/add',
                        ),
                        _buildQuickButton(
                          context,
                          Icons.savings_outlined,
                          "Tabungan",
                          '/savings',
                        ),
                        _buildQuickButton(
                          context,
                          Icons.analytics_outlined,
                          "Evaluasi",
                          '/evaluation',
                        ),
                        _buildQuickButton(
                          context,
                          Icons.history,
                          "Riwayat",
                          '/history',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update _buildBalanceInfo
  Widget _buildBalanceInfo(
    String title,
    int amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            formatCurrency.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Update _buildBalanceCard
  Widget _buildBalanceCard(
    String title,
    int amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            formatCurrency.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.pushNamed(context, route);
          if (result == true) {
            await fetchTransactions();
            await fetchEvaluation();
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: EdgeInsets.all(4),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.teal.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade300, Colors.teal.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
