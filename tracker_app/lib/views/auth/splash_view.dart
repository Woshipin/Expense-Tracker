import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import 'register_view.dart';
import 'forgot_password_view.dart';
import 'reset_password_view.dart';

class SunsetSplashView extends StatefulWidget {
  const SunsetSplashView({super.key});

  @override
  State<SunsetSplashView> createState() => _SunsetSplashViewState();
}

class _SunsetSplashViewState extends State<SunsetSplashView> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 【核心修复】：使用 toString() 获取包含 ?token=xxx 的完整绝对网址，100% 防止漏判
    final currentUrl = Uri.base.toString();

    // 如果是游客页面，直接物理推入栈顶
    if (currentUrl.contains('reset-password')) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResetPasswordView()),
        );
      }
      return;
    }

    if (currentUrl.contains('forgot-password')) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPasswordView()),
        );
      }
      return;
    }

    if (currentUrl.contains('register')) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RegisterView()),
        );
      }
      return;
    }

    // --- 以下是正常的 Token 登录验证逻辑 ---
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null || token.isEmpty) {
      _redirectTo('/login');
      return;
    }

    try {
      final response = await ApiClient().dio.get('/me');
      if (response.statusCode == 200) {
        _redirectTo('/dashboard');
      } else {
        _redirectTo('/login');
      }
    } catch (e) {
      await prefs.remove("auth_token");
      _redirectTo('/login');
    }
  }

  void _redirectTo(String routeName) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SunsetColors.bgStart,
      body: Center(
        child: CircularProgressIndicator(color: SunsetColors.primary),
      ),
    );
  }
}