// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

enum ApiMode { production, local, auto }

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  
  // 🌟 1. 模式开关：默认 auto (自动探测)，优先锁定 Render 生产环境
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

  // 🌟 候选队列：首先 Deploy URL -> 其次 Localhost -> 最后局域网节点
  List<String> get _candidateUrls {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final localhost = isAndroid ? androidEmulatorUrl : localUrl;

    return [
      productionUrl,                                  // 1. 首选部署地址 Render
      localhost,                                      // 2. 本地电脑/模拟器 127.0.0.1 / 10.0.2.2
      "http://192.168.0.152.nip.io:8000/api",         // 3. 局域网节点
      "http://192.168.0.132.nip.io:8000/api",
      "http://10.200.242.154.nip.io:8000/api",
    ];
  }

  /// 🌟 智能自适应雷达探测 (与 Next.js 优先级 100% 对齐)
  Future<String> findWorkingUrl() async {
    if (apiMode == ApiMode.production) {
      currentBaseUrl = productionUrl;
      dio.options.baseUrl = currentBaseUrl;
      return currentBaseUrl;
    }

    if (apiMode == ApiMode.local) {
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      currentBaseUrl = isAndroid ? androidEmulatorUrl : localUrl;
      dio.options.baseUrl = currentBaseUrl;
      return currentBaseUrl;
    }

    if (isDetected) {
      return currentBaseUrl;
    }

    // 给首选 Render 节点 3.5 秒建立连接时间
    final tempDio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 3500), 
    ));

    // 顺序探测：Render 线上 -> Localhost -> 局域网候选 IP
    for (String url in _candidateUrls) {
      try {
        debugPrint("[雷达探测] 🚀 正在连接 API: $url ...");
        await tempDio.get('$url/me'); 

        currentBaseUrl = url;
        dio.options.baseUrl = currentBaseUrl;
        isDetected = true;
        debugPrint("✅ [连接成功] 成功锁定可用 API 节点: $currentBaseUrl");
        return currentBaseUrl;
      } catch (e) {
        // 未登录返回的 401/403 均视为网络通畅
        if (e is DioException && e.response != null) {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            currentBaseUrl = url;
            dio.options.baseUrl = currentBaseUrl;
            isDetected = true;
            debugPrint("✅ [连接成功] 节点响应正常并锁定: $currentBaseUrl");
            return currentBaseUrl;
          }
        }
        debugPrint("❌ [连接失败] 节点不可达: $url");
        continue;
      }
    }

    // 终极回退到线上 Render URL
    currentBaseUrl = productionUrl;
    dio.options.baseUrl = currentBaseUrl;
    isDetected = true;
    debugPrint("⚠️ [探测结束] 回退到默认 Render 线上 API: $currentBaseUrl");
    return currentBaseUrl;
  }
}