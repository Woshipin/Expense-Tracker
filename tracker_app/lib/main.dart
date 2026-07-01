import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; 
import 'core/constants/colors.dart';
import 'core/api/api_client.dart'; 
import 'views/auth/splash_view.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/forgot_password_view.dart';
import 'views/auth/reset_password_view.dart';
import 'views/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 去除 Web 端的 URL 哈希 `#` 号，让网址变成标准的路径
  usePathUrlStrategy(); 
  
  // 在 APP 启动前，自动测试并绑定可用的后端 IP
  await ApiClient().findWorkingUrl(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunset Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primaryColor: SunsetColors.primary,
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
      ),
      // 【核心修复】：使用 onGenerateRoute 代替 routes，完美支持带 ?token=xxx 参数的 Web 路由跳转
      onGenerateRoute: (settings) {
        // 解析传入的完整网址（例如：/reset-password?token=abc&email=123）
        final Uri uri = Uri.parse(settings.name ?? '/');
        
        // 仅仅根据 path（路径）进行匹配，自动忽略后面的 Query 参数
        switch (uri.path) {
          case '/':
            return MaterialPageRoute(builder: (context) => const SunsetSplashView(), settings: settings);
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginView(), settings: settings);
          case '/register':
            return MaterialPageRoute(builder: (context) => const RegisterView(), settings: settings);
          case '/forgot-password':
            return MaterialPageRoute(builder: (context) => const ForgotPasswordView(), settings: settings);
          case '/reset-password':
            return MaterialPageRoute(builder: (context) => const ResetPasswordView(), settings: settings);
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => const MainLayout(), settings: settings);
          default:
            return MaterialPageRoute(builder: (context) => const SunsetSplashView(), settings: settings);
        }
      },
    );
  }
}