import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:another_flushbar/flushbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final api = ApiService();
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void handleRegister() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final success = await api.register(
      nameController.text,
      emailController.text,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (success) {
      Flushbar(
        message: 'Registrasi berhasil! Silakan login.',
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(15),
        backgroundGradient: const LinearGradient(
          colors: [Colors.green, Colors.lightGreen],
        ),
      ).show(context);
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      Flushbar(
        message: 'Registrasi gagal',
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        borderRadius: BorderRadius.circular(8),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(15),
        backgroundGradient: const LinearGradient(
          colors: [Colors.red, Colors.redAccent],
        ),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF5F2EC); // krem terang
    final cardColor = const Color(0xFFFFF3E0); // kartu warna beige
    final accentColor = const Color(0xFF6D4C41); // coklat tua
    final fieldColor = const Color(0xFFFFFBF2); // putih kekuningan

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.coffee_outlined, size: 60, color: accentColor),
                  const SizedBox(height: 12),
                  Text(
                    'Daftar Akun',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bergabunglah dan nikmati kopi terbaik 🍵',
                    style: TextStyle(fontSize: 14, color: accentColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // NAMA
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: TextStyle(color: accentColor),
                      prefixIcon: Icon(Icons.person, color: accentColor),
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // EMAIL
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: accentColor),
                      prefixIcon: Icon(Icons.email, color: accentColor),
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email wajib diisi';
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: accentColor),
                      prefixIcon: Icon(Icons.lock, color: accentColor),
                      filled: true,
                      fillColor: fieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (value.length < 4) {
                        return 'Password minimal 4 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // BUTTON
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            key: ValueKey(1),
                            color: Colors.brown,
                          )
                        : SizedBox(
                            width: double.infinity,
                            key: const ValueKey(2),
                            child: ElevatedButton(
                              onPressed: handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Daftar'),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: Text(
                      'Sudah punya akun? Login',
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
