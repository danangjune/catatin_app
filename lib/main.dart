import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/evaluation_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(CatatInApp());
}

class CatatInApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CatatIn',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => DashboardScreen(),
        '/add': (context) => AddTransactionScreen(),
        '/savings': (context) => SavingsScreen(),
        '/evaluation': (context) => EvaluationScreen(),
        '/history': (context) => HistoryScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
