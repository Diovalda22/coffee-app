import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final api = ApiService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  void handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final success = await api.login(
      emailController.text,
      passwordController.text,
    );
    setState(() => isLoading = false);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getInt('role');

      if (!context.mounted) return;

      if (role == 1) {
        Navigator.pushReplacementNamed(context, '/home'); // User
      } else if (role == 2) {
        Navigator.pushReplacementNamed(context, '/admin'); // Admin
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Role tidak dikenali')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login gagal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF5F2EC); // lebih cerah
    final cardColor = const Color(0xFFFFF3E0); // krem terang
    final accentColor = const Color(0xFF6D4C41); // coklat tua
    final fieldBgColor = const Color(0xFFFFFBF2); // putih kekuningan

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.coffee, size: 60, color: accentColor),
                  const SizedBox(height: 12),
                  Text(
                    'Login ke Akunmu',
                    style: TextStyle(
                      fontSize: 22,
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: accentColor),
                      prefixIcon: Icon(Icons.email, color: accentColor),
                      filled: true,
                      fillColor: fieldBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    validator: (value) {
                      if (value == null || value.length < 4) {
                        return 'Password minimal 4 karakter';
                      }
                      return null;
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: accentColor),
                      prefixIcon: Icon(Icons.lock, color: accentColor),
                      filled: true,
                      fillColor: fieldBgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.brown)
                      : ElevatedButton(
                          onPressed: handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text(
                      'Belum punya akun? Daftar',
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
