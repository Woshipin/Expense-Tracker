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

  // 【核心修改】：为了对接后端的 Google/Facebook 授权，将局域网 IP 全部对齐为 .nip.io 域名
  final List<String> _candidateUrls = [
    "http://127.0.0.1:8000/api",                     // 1. 电脑模拟器本地
    "http://192.168.0.152.nip.io:8000/api",          // 2. 新山 Wi-Fi (对齐 .nip.io)
    "http://192.168.0.132.nip.io:8000/api",          // 3. Ah Wi-Fi (对齐 .nip.io)
    "http://10.200.242.154.nip.io:8000/api",         // 4. 手机个人热点 (对齐 .nip.io)
  ];

  /// 异步自动雷达探测函数
  Future<void> findWorkingUrl() async {
    final tempDio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 1500), // 1.5秒快速超时
    ));

    for (String url in _candidateUrls) {
      try {
        debugPrint("[雷达探测] 正在连接 API: $url ...");
        
        // 探测 /me 路径
        await tempDio.get('$url/me'); 
        
        currentBaseUrl = url;
        dio.options.baseUrl = currentBaseUrl;
        debugPrint("✅ [连接成功] 已成功锁定并绑定 API: $currentBaseUrl");
        return; 
      } catch (e) {
        // 允许未登录状态的 401/403 视为物理连通
        if (e is DioException && e.response != null) {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            currentBaseUrl = url;
            dio.options.baseUrl = currentBaseUrl;
            debugPrint("✅ [连接成功] 已锁定 API: $currentBaseUrl (跨域及网络通畅，状态码: ${e.response?.statusCode})");
            return;
          }
        }
        
        debugPrint("❌ [连接失败] 节点不可达: $url");
        continue;
      }
    }
    debugPrint("⚠️ [探测结束] 所有局域网节点均不可达，使用默认备用: $currentBaseUrl");
  }
}