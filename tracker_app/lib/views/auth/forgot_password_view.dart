import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/input.dart';
import '../../core/widgets/toast.dart';
import 'auth_background.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient().dio.post("/forgot-password", data: {"email": _emailController.text});
      setState(() => _isSent = true);
    } on DioException catch (e) {
      SunsetToast.show(context, e.response?.data['message'] ?? "Failed to send reset link.", type: SunsetToastType.error);
    } finally {
      setState(() => _isLoading = false);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 18, color: SunsetColors.dark),
                          SizedBox(width: 8),
                          Text("Back to Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SunsetColors.dark)),
                        ],
                      ),
                    ),
                  ),
                  Container(
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
                              Text("Forgot Password", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text("Enter your email address and we'll send you a link to reset your password.", style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: !_isSent ? Column(
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
                                    const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                    const SizedBox(height: 8),
                                    SunsetInput(hintText: "your@email.com", controller: _emailController, prefixIcon: const Icon(Icons.mail, color: Colors.grey, size: 18)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity, height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF84D28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text("Send Reset Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              )
                            ],
                          ) : Column(
                            children: [
                              const SizedBox(height: 16),
                              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: Icon(Icons.mail, color: Colors.green.shade500, size: 40)),
                              const SizedBox(height: 20),
                              const Text("Check your email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: SunsetColors.dark)),
                              const SizedBox(height: 8),
                              Text("We have sent a password reset link to\n${_emailController.text}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
                              const SizedBox(height: 16),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}