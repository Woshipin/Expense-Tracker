import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  
  // 默认兜底 URL（如果所有探测都失败了，最后使用它）
  String currentBaseUrl = "http://127.0.0.1:8000/api";

  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: currentBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("auth_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
    ));
  }

  // 【核心修改】：已将你指定的 4 个 API 路径严格按照左到右的优先级加入探测列表
  final List<String> _candidateUrls = [
    "http://127.0.0.1:8000/api",      // 1. 本地（用于电脑模拟器开发）
    "http://192.168.0.152:8000/api",  // 2. 新山 Wi-Fi
    "http://192.168.0.132:8000/api",  // 3. Ah Wi-Fi
    "http://10.200.242.154:8000/api",  // 4. 手机个人热点
  ];

  /// 异步自动雷达探测函数
  Future<void> findWorkingUrl() async {
    final tempDio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 1500), // 1.5秒快速超时，防止等待过久
    ));

    for (String url in _candidateUrls) {
      try {
        debugPrint("[雷达探测] 正在连接 API: $url ...");
        
        // 探测时直接去请求确切存在的 /me 路径，这会触发 Laravel cors.php 的放行
        await tempDio.get('$url/me'); 
        
        // 如果请求没有抛出异常，说明网络畅通且有登录 Session
        currentBaseUrl = url;
        dio.options.baseUrl = currentBaseUrl;
        debugPrint("✅ [连接成功] 已成功锁定并绑定 API: $currentBaseUrl");
        return; 
      } catch (e) {
        // 当我们没有携带 Token 访问 /me 时，后端会安全返回 401。
        // 只要能返回 401，就说明物理网络是通畅的，且跨域被完美允许！
        if (e is DioException && e.response != null) {
          currentBaseUrl = url;
          dio.options.baseUrl = currentBaseUrl;
          debugPrint("✅ [连接成功] 已锁定 API: $currentBaseUrl (已验证网络及跨域通畅，状态码: ${e.response?.statusCode})");
          return;
        }
        
        debugPrint("❌ [连接失败] 节点不可达或被拦截: $url");
        continue;
      }
    }
    debugPrint("⚠️ [探测结束] 所有局域网节点均不可达，将使用默认备用 IP: $currentBaseUrl");
  }
}