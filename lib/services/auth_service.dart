import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000';
  static const String loginUrl = '$baseUrl/api/login';

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return true;
    } else {
      print('Login failed: ${response.body}');
      return false;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token == null) return;

    await http.post(
      Uri.parse('$baseUrl/api/logout'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return true;
    } else {
      print('Register failed: ${response.body}');
      return false;
    }
  }

  // Helper for authenticated requests
  static Future<http.Response> authenticatedGet(String endpoint) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}
