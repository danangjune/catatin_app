import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedType = 'Pemasukan';
  String _selectedCategory = 'Makan';
  DateTime _selectedDate = DateTime.now();

  final Map<String, List<String>> _categoryMap = {
    'Pemasukan': [
      'Gaji',
      'Bonus',
      'Investasi',
      'Penjualan',
      'Hadiah',
      'Lainnya',
    ],
    'Pengeluaran': [
      'Tak Terduga',
      'Makan & Minum',
      'Transportasi',
      'Belanja',
      'Hiburan',
      'Tagihan',
      'Kesehatan',
      'Pendidikan',
      'Lainnya',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Set kategori default sesuai tipe transaksi
    _selectedCategory = _categoryMap[_selectedType]![0];
  }

  // Update kategori saat tipe transaksi berubah
  void _updateType(String newType) {
    setState(() {
      _selectedType = newType;
      // Update selected category when type changes
      _selectedCategory = _categoryMap[newType]![0];
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse('http://localhost:8000/api/v1/transactions');

      // Mapping tipe
      final String backendType =
          _selectedType == 'Pemasukan' ? 'income' : 'expense';

      final body = {
        'type': backendType,
        'category':
            _selectedCategory
                .toLowerCase(), // optional: lowercase biar konsisten
        'amount': _amountController.text,
        'description': _descController.text,
        'date': _selectedDate.toIso8601String().substring(0, 10), // yyyy-mm-dd
      };

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaksi berhasil ditambahkan')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${responseData['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
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
          "Tambah Transaksi",
          style: TextStyle(
            color: const Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Type Selector
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _updateType('Pemasukan'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _selectedType == 'Pemasukan'
                                ? Colors.green.shade50
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _selectedType == 'Pemasukan'
                                  ? Colors.green
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color:
                                _selectedType == 'Pemasukan'
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pemasukan',
                            style: TextStyle(
                              color:
                                  _selectedType == 'Pemasukan'
                                      ? Colors.green
                                      : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _updateType('Pengeluaran'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _selectedType == 'Pengeluaran'
                                ? Colors.red.shade50
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _selectedType == 'Pengeluaran'
                                  ? Colors.red
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color:
                                _selectedType == 'Pengeluaran'
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pengeluaran',
                            style: TextStyle(
                              color:
                                  _selectedType == 'Pengeluaran'
                                      ? Colors.red
                                      : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Field
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                _selectedType == 'Pemasukan'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixText: "Rp ",
                            prefixStyle: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  _selectedType == 'Pemasukan'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            hintText: "0",
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          validator:
                              (value) => value!.isEmpty ? "Wajib diisi" : null,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Category Field
                      Text(
                        "Kategori",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(border: InputBorder.none),
                          items:
                              _categoryMap[_selectedType]!
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => _selectedCategory = value!),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Date Picker
                      Text(
                        "Tanggal",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 12),
                              Text(
                                DateFormat(
                                  'dd MMMM yyyy',
                                ).format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Description Field
                      Text(
                        "Keterangan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Tambahkan keterangan...",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Simpan Transaksi",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
