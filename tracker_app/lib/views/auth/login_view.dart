import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:dio/dio.dart'; 
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/input.dart';
import '../../core/widgets/toast.dart';
import 'auth_background.dart';

// =====================================================================
// 🎨 【高保真官方彩色 Google "G" Logo 绘制组件】
// =====================================================================
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Rect rect = Rect.fromCircle(center: Offset(r, r), radius: r);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.45
      ..strokeCap = StrokeCap.butt;

    // 1. 红色彩条
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.4, 1.25, false, paint);

    // 2. 黄色彩条
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -1.15, 1.2, false, paint);

    // 3. 绿色彩条
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.05, 1.2, false, paint);

    // 4. 蓝色彩条
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 1.25, 1.25, false, paint);

    // 绘制横杠
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(r, r - (r * 0.22), r * 0.95, r * 0.44),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// =====================================================================
// 🎨 【官方经典 Facebook 蓝底白 F 标 Logo 组件】
// =====================================================================
class FacebookLogo extends StatelessWidget {
  final double size;
  const FacebookLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2), 
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.facebook, 
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  Map<String, dynamic> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool("isRemembered") ?? false;
    if (isRemembered) {
      final savedEmail = prefs.getString("rememberedEmail") ?? "";
      final savedPassword = prefs.getString("rememberedPassword") ?? "";
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
        _passwordController.text = savedEmail == "ahpin7762@gmail.com" ? "Pin@776253" : savedPassword;
      });
    }
  }

  /// 启动第三方社交登录授权
  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    final String apiUrl = "${ApiClient().currentBaseUrl}/auth/${provider.toLowerCase()}";
    final Uri url = Uri.parse(apiUrl);

    try {
      // 采用最安全、支持移动端及网页端弹出新标签页的 platformDefault 模式
      await launchUrl(url, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        SunsetToast.show(context, "Failed to start $provider login", type: SunsetToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; _errors.clear(); });
    try {
      final response = await ApiClient().dio.post("/login", data: {
        "email": _emailController.text,
        "password": _passwordController.text,
        "rememberMe": _rememberMe,
      });

      if (response.data != null && response.data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", response.data['access_token']);
        if (_rememberMe) {
          await prefs.setString("rememberedEmail", _emailController.text);
          await prefs.setString("rememberedPassword", _passwordController.text);
          await prefs.setBool("isRemembered", true);
        } else {
          await prefs.remove("rememberedEmail");
          await prefs.remove("rememberedPassword");
          await prefs.setBool("isRemembered", false);
        }
      }
      if (mounted) {
        SunsetToast.show(context, "Login successful", type: SunsetToastType.success);
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.pushReplacementNamed(context, '/dashboard');
        });
      }
    } on DioException catch (e) {
      if (!mounted) return; 
      setState(() => _isLoading = false);
      if (e.response != null && e.response!.statusCode == 422) {
        setState(() => _errors = e.response!.data['errors'] ?? {});
      } else {
        SunsetToast.show(context, e.response?.data['error'] ?? "Login failed", type: SunsetToastType.error);
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
              child: Column(
                children: [
                  Container(
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
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.login, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Text("Login Account", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                                    const Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                    const SizedBox(height: 8),
                                    SunsetInput(
                                      hintText: "ahpin7762@gmail.com",
                                      controller: _emailController,
                                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey, size: 18),
                                    ),
                                    if (_errors['email'] != null)
                                      Padding(padding: const EdgeInsets.only(top: 4), child: Text(_errors['email'][0], style: const TextStyle(color: Colors.red, fontSize: 12))),
                                    const SizedBox(height: 16),
                                    const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                    const SizedBox(height: 8),
                                    SunsetInput(
                                      hintText: "••••••••••",
                                      controller: _passwordController,
                                      obscureText: !_showPassword,
                                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                                      suffixIcon: IconButton(
                                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
                                        onPressed: () => setState(() => _showPassword = !_showPassword),
                                      ),
                                    ),
                                    if (_errors['password'] != null)
                                      Padding(padding: const EdgeInsets.only(top: 4), child: Text(_errors['password'][0], style: const TextStyle(color: Colors.red, fontSize: 12))),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 24, height: 24,
                                              child: Checkbox(value: _rememberMe, activeColor: SunsetColors.primary, onChanged: (val) => setState(() => _rememberMe = val ?? false)),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text("Remember Me", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                                          child: const Text("Forgot Password?", style: TextStyle(color: SunsetColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF84D28),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 2,
                                        ),
                                        onPressed: _isLoading ? null : _handleLogin,
                                        child: _isLoading
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFFEDD5)),
                                ),
                                alignment: Alignment.center,
                                child: Wrap(
                                  children: [
                                    const Text("Don't Have An Account? ", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                                    InkWell(
                                      onTap: () => Navigator.pushNamed(context, '/register'),
                                      child: const Text("Click To Register", style: TextStyle(color: SunsetColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Row(
                                children: [
                                  Expanded(child: Divider(color: Color(0xFFF3F4F6))),
                                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Or", style: TextStyle(color: Colors.grey, fontSize: 13))),
                                  Expanded(child: Divider(color: Color(0xFFF3F4F6))),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16), 
                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: Colors.white,
                                      ),
                                      onPressed: _isLoading ? null : () => _handleSocialLogin("Google"), 
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          GoogleLogo(size: 20), 
                                          SizedBox(width: 10),  
                                          Text("Google", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16), 
                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: Colors.white,
                                      ),
                                      onPressed: _isLoading ? null : () => _handleSocialLogin("Facebook"), 
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FacebookLogo(size: 20), 
                                          SizedBox(width: 10),   
                                          Text("Facebook", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }
}