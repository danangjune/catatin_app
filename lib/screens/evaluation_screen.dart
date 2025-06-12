import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:catatin_app/utils/score_calculator.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({Key? key}) : super(key: key);

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  bool isLoading = true;
  Map<String, double> scores = {
    'income_ratio': 0,
    'saving_consistency': 0,
    'unexpected_expense': 0,
    'record_frequency': 0,
    'saving_percentage': 0,
  };

  @override
  void initState() {
    super.initState();
    calculateScores();
  }

  Future<void> calculateScores() async {
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

        // Explicitly cast numeric values to double
        final income =
            (num.tryParse(data['total_income'].toString()) ?? 0).toDouble();
        final expense =
            (num.tryParse(data['total_expense'].toString()) ?? 0).toDouble();
        final savingConsistency = (data['saving_consistency'] as num).toInt();
        final unexpectedExpense =
            (num.tryParse(data['unexpected_expense'].toString()) ?? 0)
                .toDouble();
        final recordDays = (data['record_days'] as num).toInt();
        final savingPercentage =
            (num.tryParse(data['saving_percentage'].toString()) ?? 0)
                .toDouble();

        // Calculate scores with proper double values
        final ratio = income > 0 ? expense / income : 0.0;
        scores['income_ratio'] = _calculateIncomeRatio(ratio);
        scores['saving_consistency'] = _calculateSavingConsistency(
          savingConsistency,
        );

        final unexpectedRatio = income > 0 ? unexpectedExpense / income : 0.0;
        scores['unexpected_expense'] = _calculateUnexpectedExpense(
          unexpectedRatio,
        );
        scores['record_frequency'] = _calculateRecordFrequency(recordDays);
        scores['saving_percentage'] = _calculateSavingPercentage(
          savingPercentage,
        );

        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error calculating scores: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data evaluasi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isLoading = false);
    }
  }

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
    if (percentage >= 20) return 5; // Menabung >= 20% pemasukan
    if (percentage >= 15) return 4; // >= 15%
    if (percentage >= 10) return 3; // >= 10%
    if (percentage >= 5) return 2; // >= 5%
    return 1; // < 5%
  }

  double calculateSAWScore() {
    return ScoreCalculator.calculateFinalScore(scores);
  }

  String getCategory(double score) {
    if (score >= 4.1) return "Baik";
    if (score >= 3.1) return "Cukup";
    return "Buruk";
  }

  String getRecommendation(double score) {
    if (score <= 3.0)
      return "💡 Coba mulai menabung rutin dan kurangi pengeluaran tak terduga.";
    if (score <= 4.0)
      return "👍 Keuangan kamu cukup baik, tapi masih bisa ditingkatkan. Pertahankan pencatatan rutin!";
    return "🎉 Keuangan kamu sehat dan stabil! Pertahankan kebiasaan baik ini.";
  }

  @override
  Widget build(BuildContext context) {
    final scoreRaw = calculateSAWScore();
    final scoreFinal = (scoreRaw * 20).toInt();
    final category = getCategory(scoreRaw);
    final recommendation = getRecommendation(scoreRaw);

    Color getCategoryColor() {
      if (scoreRaw >= 4.1) return Colors.green;
      if (scoreRaw >= 3.1) return Colors.orange;
      return Colors.red;
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
          "Evaluasi Keuangan",
          style: TextStyle(
            color: const Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Score Card
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      getCategoryColor().withOpacity(0.8),
                      getCategoryColor(),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: getCategoryColor().withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Skor Keuangan Kamu",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$scoreFinal",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "/100",
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Recommendation Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
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
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          "Rekomendasi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Criteria Details
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
                      "Detail Kriteria",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildKriteria(
                      "Rasio Pemasukan vs Pengeluaran",
                      scores['income_ratio']!,
                    ),
                    _buildKriteria(
                      "Konsistensi Menabung",
                      scores['saving_consistency']!,
                    ),
                    _buildKriteria(
                      "Pengeluaran Tak Terduga",
                      scores['unexpected_expense']!,
                    ),
                    _buildKriteria(
                      "Frekuensi Pencatatan",
                      scores['record_frequency']!,
                    ),
                    _buildKriteria(
                      "Persentase Tabungan dari Pemasukan",
                      scores['saving_percentage']!,
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

  Widget _buildKriteria(String label, double nilai) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(nilai).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${nilai.toStringAsFixed(1)}/5",
                  style: TextStyle(
                    color: _getScoreColor(nilai),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: nilai / 5,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(_getScoreColor(nilai)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.orange;
    return Colors.red;
  }
}
