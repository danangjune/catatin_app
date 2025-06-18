import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../widgets/bottom_nav.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final MoneyMaskedTextController _amountController = MoneyMaskedTextController(
    decimalSeparator: '', // Tidak pakai desimal
    thousandSeparator: '.', // Pemisah ribuan pakai titik
    precision: 0, // Tidak pakai angka di belakang koma
    leftSymbol: 'Rp ', // Tambah simbol Rupiah
  );
  final TextEditingController _descController = TextEditingController();

  String _selectedType = 'Pemasukan';
  String _selectedCategory = 'Gaji';
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

    _amountController.text = '0';
    _selectedCategory = _categoryMap[_selectedType]![0];
  }

  void _updateType(String newType) {
    setState(() {
      _selectedType = newType;
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

      final String backendType =
          _selectedType == 'Pemasukan' ? 'income' : 'expense';

      // Ambil angka asli tanpa format
      final rawAmount = _amountController.numberValue.toInt();

      final body = {
        'type': backendType,
        'category': _selectedCategory.toLowerCase(),
        'amount': rawAmount,
        'description': _descController.text,
        'date': _selectedDate.toIso8601String().substring(0, 10),
      };

      try {
        final token = await AuthService.getToken();

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _updateType('Pemasukan'),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
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
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
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
                padding: EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountField(),
                      SizedBox(height: 24),
                      _buildDropdownField(
                        "Kategori",
                        _categoryMap[_selectedType]!,
                        _selectedCategory,
                        (val) => setState(() => _selectedCategory = val),
                      ),
                      SizedBox(height: 24),
                      _buildDatePicker(),
                      SizedBox(height: 24),
                      _buildTextField(
                        "Keterangan",
                        _descController,
                        hint: "Tambahkan keterangan...",
                      ),
                      SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 65,
        width: 65,
        margin: EdgeInsets.only(bottom: 15),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/add'),
          backgroundColor: Color(0xFF20BF55),
          elevation: 4,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(currentIndex: -1),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          color: _selectedType == 'Pemasukan' ? Colors.green : Colors.red,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Rp 0",
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        validator:
            (value) =>
                _amountController.numberValue == 0 ? "Wajib diisi" : null,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String value,
    void Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            value: value,
            decoration: InputDecoration(border: InputBorder.none),
            items:
                items
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
            onChanged: (val) => onChanged(val!),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600),
                SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF20BF55),
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
    );
  }
}
