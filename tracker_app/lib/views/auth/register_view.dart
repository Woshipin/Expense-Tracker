import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/input.dart';
import '../../core/widgets/toast.dart';
import 'auth_background.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  Map<String, dynamic> _errors = {};

  Future<void> _handleRegister() async {
    setState(() { _isLoading = true; _errors.clear(); });
    try {
      await ApiClient().dio.post("/register", data: {
        "full_name": _nameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
      });
      if (mounted) {
        // 核心修改：先弹 Toast，延迟 1.5 秒跳转
        SunsetToast.show(context, "Registration successful! Redirecting...", type: SunsetToastType.success);
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      if (e.response != null && e.response!.statusCode == 422) {
        setState(() {
          final backendErrors = Map<String, dynamic>.from(e.response!.data['errors']);
          if (backendErrors.containsKey('full_name')) backendErrors['name'] = backendErrors['full_name'];
          _errors = backendErrors;
        });
      } else {
        SunsetToast.show(context, "Server error.", type: SunsetToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEF4444)]),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                            child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Text("Register Account", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 16, color: Colors.blue.shade600),
                                    const SizedBox(width: 8),
                                    const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text("Full Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 6),
                                SunsetInput(hintText: "Enter Your Name", controller: _nameController, prefixIcon: const Icon(Icons.person_outline, color: Colors.grey, size: 18)),
                                if (_errors['name'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_errors['name'][0], style: const TextStyle(color: Colors.red, fontSize: 12))),
                                const SizedBox(height: 12),
                                const Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 6),
                                SunsetInput(hintText: "ahpin7762@gmail.com", controller: _emailController, prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey, size: 18)),
                                if (_errors['email'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_errors['email'][0], style: const TextStyle(color: Colors.red, fontSize: 12))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD1FAE5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lock_outline, size: 16, color: Color(0xFF10B981)),
                                    const SizedBox(width: 8),
                                    const Text("Password Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 6),
                                SunsetInput(
                                  hintText: "••••••••",
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
                                    onPressed: () => setState(() => _showPassword = !_showPassword),
                                  ),
                                ),
                                if (_errors['password'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_errors['password'][0], style: const TextStyle(color: Colors.red, fontSize: 12))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF84D28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("Register", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFEDD5))),
                            alignment: Alignment.center,
                            child: Wrap(
                              children: [
                                const Text("Already Have An Account? ", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                                InkWell(
                                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                                  child: const Text("Click To Login", style: TextStyle(color: SunsetColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}