// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

enum ApiMode { production, local, auto }

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  
  // 🌟 1. 模式选择：设为 auto (自动探测)，优先锁定 Render 生产环境
  static const ApiMode apiMode = ApiMode.auto;

  // 🌟 2. 生产环境 Render API 地址
  static const String productionUrl = "https://expense-tracker-system-pe3l.onrender.com/api";
  static const String localUrl = "http://127.0.0.1:8000/api";
  static const String androidEmulatorUrl = "http://10.0.2.2:8000/api";

  String currentBaseUrl = productionUrl;
  bool isDetected = false;

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

  // 🌟 探测优先级队列：首选 Render 部署地址 -> 其次 Localhost -> 最后局域网节点
  List<String> get _candidateUrls {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final localhost = isAndroid ? androidEmulatorUrl : localUrl;

    return [
      productionUrl,                                  // 1. 首选 Render 线上部署地址
      localhost,                                      // 2. 本地电脑/模拟器 127.0.0.1 / 10.0.2.2
      "http://192.168.0.152.nip.io:8000/api",         // 3. 局域网节点
      "http://192.168.0.132.nip.io:8000/api",
      "http://10.200.242.154.nip.io:8000/api",
    ];
  }

  /// 🌟 智能自适应雷达探测
  Future<String> findWorkingUrl() async {
    // 强制生产环境模式
    if (apiMode == ApiMode.production) {
      currentBaseUrl = productionUrl;
      dio.options.baseUrl = currentBaseUrl;
      return currentBaseUrl;
    }

    // 强制本地环境模式
    if (apiMode == ApiMode.local) {
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      currentBaseUrl = isAndroid ? androidEmulatorUrl : localUrl;
      dio.options.baseUrl = currentBaseUrl;
      return currentBaseUrl;
    }

    if (isDetected) {
      return currentBaseUrl;
    }

    // 给 Render 线上冷启动留出 5 秒建立连接时间
    final tempDio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 5000), 
    ));

    for (String url in _candidateUrls) {
      try {
        debugPrint("[雷达探测] 🚀 正在探测 API: $url ...");
        
        // 🌟 改进 1：改用无鉴权的 /test-connection 轻量级路由探测，避免 500 或 401 干扰
        await tempDio.get('$url/test-connection'); 

        currentBaseUrl = url;
        dio.options.baseUrl = currentBaseUrl;
        isDetected = true;
        debugPrint("✅ [连接成功] 成功瞬间锁定 API: $currentBaseUrl");
        return currentBaseUrl;
      } catch (e) {
        // 🌟 改进 2：只要服务端有任何 HTTP 响应（代表服务器网络是通的且活着）
        if (e is DioException && e.response != null) {
          currentBaseUrl = url;
          dio.options.baseUrl = currentBaseUrl;
          isDetected = true;
          debugPrint("✅ [连接成功] 线上服务器网络通畅，已秒级锁定: $currentBaseUrl (Status Code: ${e.response?.statusCode})");
          return currentBaseUrl;
        }
        debugPrint("❌ [网络不可达/拒绝连接] 节点跳过: $url");
        continue;
      }
    }

    // 终极回退 Render 线上地址
    currentBaseUrl = productionUrl;
    dio.options.baseUrl = currentBaseUrl;
    isDetected = true;
    debugPrint("⚠️ [探测结束] 锁定 Render 线上 API: $currentBaseUrl");
    return currentBaseUrl;
  }
}