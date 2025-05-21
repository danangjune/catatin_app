import 'package:flutter/material.dart';

class AlertScreen extends StatelessWidget {
  final Map<String, dynamic> alert;

  const AlertScreen({Key? key, required this.alert}) : super(key: key);

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
          'Detail Notifikasi',
          style: TextStyle(
            color: const Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [alert['color'].withOpacity(0.15), Colors.white],
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
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: alert['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: alert['color'].withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        alert['icon'],
                        color: alert['color'],
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _getDetailMessage(alert['title']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Rekomendasi Tindakan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              ..._buildRecommendations(alert['title']).map(
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
                          color: alert['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          rec['icon'],
                          color: alert['color'],
                          size: 20,
                        ),
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
            ],
          ),
        ),
      ),
    );
  }

  String _getDetailMessage(String title) {
    // Sesuaikan pesan detail berdasarkan jenis alert
    if (title.contains('defisit')) {
      return 'Pengeluaran Anda melebihi pemasukan bulan ini. Hal ini dapat mempengaruhi kesehatan keuangan Anda dalam jangka panjang.';
    } else if (title.contains('transaksi')) {
      return 'Anda belum mencatat transaksi apapun selama 7 hari terakhir. Pencatatan rutin penting untuk monitoring keuangan yang efektif.';
    } else if (title.contains('tabung')) {
      return 'Anda belum menyisihkan dana untuk tabungan bulan ini. Menabung secara rutin penting untuk kesiapan finansial masa depan.';
    } else if (title.contains('menurun')) {
      return 'Pendapatan Anda mengalami penurunan dibandingkan bulan sebelumnya. Mari evaluasi sumber pendapatan Anda.';
    }
    return '';
  }

  List<Map<String, dynamic>> _buildRecommendations(String title) {
    if (title.contains('defisit')) {
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
      ];
    }
    // Tambahkan rekomendasi untuk jenis alert lainnya
    return [];
  }
}
