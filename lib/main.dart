import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const RandevuGo());
}

class Api {
  // Android emulatoru icin.
  // Gercek telefon / iOS icin adres degisecek.
  static const base = 'http://127.0.0.1:5000';

  static Future<dynamic> get(
    String path, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$base$path'),
      headers: {
        if (token != null)
          'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data.toString());
    }

    return data;
  }

  static Future<dynamic> login(
    String role,
    String identifier,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$base/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': role,
        'identifier': identifier,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data.toString());
    }

    return data;
  }
}

class RandevuGo extends StatelessWidget {
  const RandevuGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RandevuGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B87),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final identifier = TextEditingController();
  final password = TextEditingController();

  String role = 'customer';
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    identifier.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await Api.login(
        role,
        identifier.text.trim(),
        password.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            role: role,
            token: data['access_token'] as String,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RandevuGo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Icon(
                Icons.calendar_month,
                size: 72,
                color: Color(0xFF176B87),
              ),
              const SizedBox(height: 16),
              const Text(
                'RandevuGo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Hesap turu',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'customer',
                    child: Text('Musteri'),
                  ),
                  DropdownMenuItem(
                    value: 'business',
                    child: Text('Isletme'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => role = value);
                  }
                },
              ),
              TextField(
                controller: identifier,
                decoration: const InputDecoration(
                  labelText: 'E-posta / telefon / kullanici adi',
                ),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Parola',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading ? null : signIn,
                child: Text(
                  loading ? 'Baglaniyor...' : 'Giris yap',
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String role;
  final String token;

  const HomePage({
    super.key,
    required this.role,
    required this.token,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String result = 'Veriler yukleniyor...';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final path = widget.role == 'customer'
        ? '/api/v1/customer/appointments'
        : '/api/v1/business/appointments';

    try {
      final data = await Api.get(
        path,
        token: widget.token,
      );

      if (mounted) {
        setState(() {
          result = const JsonEncoder.withIndent(
            '  ',
          ).convert(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => result = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.role == 'customer'
              ? 'Randevularim'
              : 'Isletme Paneli',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: load,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(result),
      ),
    );
  }
}
