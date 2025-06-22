import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlertScreen extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const AlertScreen({Key? key, required this.alerts}) : super(key: key);

  String _getDetailMessage(String title, Map<String, dynamic> alert) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final meta = alert['metadata'] ?? {};

    if (title.contains('Defisit')) {
      final deficitAmount = meta['deficit_amount'] ?? 0;
      return 'Pengeluaran Anda melebihi pemasukan bulan ini sebesar ${formatCurrency.format(deficitAmount)}.';
    } else if (title.contains('Pencatatan')) {
      return 'Anda belum mencatat transaksi apapun selama 7 hari terakhir.';
    } else if (title.contains('Pengeluaran')) {
      final category = meta['category'] ?? '';
      final amount = meta['amount'] ?? 0;
      final percentage = meta['percentage'] ?? '0';
      return 'Pengeluaran kategori $category mencapai ${formatCurrency.format(amount)} (${percentage}% dari pendapatan bulanan).';
    } else if (title.contains('Pendapatan')) {
      final decrease = meta['decrease_percentage'] ?? '0';
      return 'Pendapatan Anda menurun $decrease% dibandingkan bulan lalu.';
    } else if (title.contains('Tabungan')) {
      final targetAmount = meta['target_amount'] ?? 0;
      final currentSavings = meta['current_savings'] ?? 0;
      final percentage = meta['percentage'] ?? '0';
      return 'Saat ini baru ${formatCurrency.format(currentSavings)} dari target ${formatCurrency.format(targetAmount)} ($percentage%).';
    }

    return 'Perhatikan notifikasi ini untuk pengelolaan keuangan yang lebih baik.';
  }

  List<Map<String, dynamic>> _buildRecommendations(String title) {
    if (title.contains('Defisit')) {
      return [
        {
          'icon': Icons.receipt_long,
          'text': 'Evaluasi pengeluaran non-esensial Anda',
        },
        {
          'icon': Icons.calculate,
          'text': 'Buat anggaran yang lebih ketat untuk bulan depan',
        },
        {
          'icon': Icons.savings,
          'text': 'Identifikasi area potensial untuk penghematan',
        },
        {
          'icon': Icons.account_balance_wallet,
          'text': 'Prioritaskan pengeluaran penting',
        },
      ];
    } else if (title.contains('Pencatatan')) {
      return [
        {
          'icon': Icons.schedule,
          'text': 'Atur pengingat harian untuk mencatat transaksi',
        },
        {
          'icon': Icons.check_circle_outline,
          'text': 'Catat transaksi segera setelah terjadi',
        },
        {
          'icon': Icons.date_range,
          'text': 'Luangkan waktu khusus untuk mencatat keuangan',
        },
        {
          'icon': Icons.receipt_long,
          'text': 'Simpan bukti transaksi untuk pencatatan akurat',
        },
      ];
    } else if (title.contains('Pengeluaran')) {
      return [
        {
          'icon': Icons.pie_chart,
          'text': 'Analisis pola pengeluaran kategori ini',
        },
        {
          'icon': Icons.trending_down,
          'text': 'Tentukan target pengurangan pengeluaran',
        },
        {
          'icon': Icons.compare_arrows,
          'text': 'Cari alternatif yang lebih hemat',
        },
        {
          'icon': Icons.account_balance_wallet,
          'text': 'Tetapkan batas maksimal pengeluaran',
        },
      ];
    } else if (title.contains('Pendapatan')) {
      return [
        {'icon': Icons.assessment, 'text': 'Analisis sumber pendapatan Anda'},
        {'icon': Icons.work, 'text': 'Cari peluang pendapatan tambahan'},
        {
          'icon': Icons.trending_up,
          'text': 'Tingkatkan keahlian untuk meningkatkan nilai',
        },
        {
          'icon': Icons.savings,
          'text': 'Optimalkan penggunaan pendapatan yang ada',
        },
      ];
    } else if (title.contains('Tabungan')) {
      return [
        {
          'icon': Icons.savings_outlined,
          'text': 'Tetapkan jadwal menabung rutin',
        },
        {
          'icon': Icons.account_balance_wallet,
          'text': 'Sisihkan dana setiap awal bulan',
        },
        {
          'icon': Icons.pie_chart,
          'text': 'Alokasikan minimal 20% pendapatan untuk tabungan',
        },
        {
          'icon': Icons.format_list_numbered,
          'text': 'Buat prioritas pengeluaran & tabungan',
        },
      ];
    }
    return [
      {
        'icon': Icons.insights,
        'text': 'Evaluasi kondisi keuangan secara menyeluruh',
      },
      {
        'icon': Icons.tips_and_updates,
        'text': 'Terapkan tips pengelolaan keuangan yang sehat',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Notifikasi Penting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final color = alert['color'] as Color;
          final title = alert['title'] as String;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert card
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.15), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(alert['icon'], color: color, size: 32),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _getDetailMessage(title, alert),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Recommendations
              ..._buildRecommendations(title).map(
                (rec) => Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(rec['icon'], color: color, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec['text'],
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}
