import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/input.dart';
import '../../core/widgets/toast.dart';
import 'auth_background.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _handleReset(String token, String email) async {
    if (_isLoading) return; 
    
    setState(() => _isLoading = true);
    
    try {
      print("Requesting password reset with token: $token, email: $email");
      
      await ApiClient().dio.post("/reset-password", data: {
        "token": token,
        "email": email,
        "password": _passwordController.text,
        "password_confirmation": _confirmPasswordController.text,
      });
      
      setState(() => _isSuccess = true);
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.data}");
      SunsetToast.show(
        context, 
        e.response?.data['message'] ?? "Failed to reset password.", 
        type: SunsetToastType.error
      );
    } catch (e) {
      print("Unknown Error occurred: $e");
      SunsetToast.show(
        context, 
        "An unexpected error occurred. Please try again.", 
        type: SunsetToastType.error
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final token = uri.queryParameters['token'] ?? '';
    final email = uri.queryParameters['email'] ?? '';

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
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEF4444)]),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Create New Password", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("Please enter your new password below.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: !_isSuccess ? Column(
                        children: [
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
                                const Text("New Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 8),
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
                                const SizedBox(height: 16),
                                const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 8),
                                SunsetInput(
                                  hintText: "••••••••",
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
                                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF84D28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: _isLoading ? null : () => _handleReset(token, email),
                              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("Reset Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          )
                        ],
                      ) : const Column(
                        children: [
                          SizedBox(height: 16),
                          Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
                          SizedBox(height: 16),
                          Text("Password Updated!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: SunsetColors.dark)),
                          SizedBox(height: 8),
                          Text("Redirecting you to login page...", style: TextStyle(color: Colors.grey, fontSize: 14)),
                          SizedBox(height: 16),
                        ],
                      ),
                    )
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