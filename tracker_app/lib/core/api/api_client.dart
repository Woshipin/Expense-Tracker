// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  
  // 🌟 1. 默认生产环境线上 Render URL (作为初始及最后的备份兜底)
  String currentBaseUrl = "https://expense-tracker-system-pe3l.onrender.com/api";
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

  // 本地局域网开发候选 IP 队列
  final List<String> _localCandidateUrls = [
    "http://127.0.0.1:8000/api",                     // 电脑模拟器本地
    "http://192.168.0.132.nip.io:8000/api",          // Ah Wi-Fi
    "http://192.168.0.152.nip.io:8000/api",          // 新山 Wi-Fi
    "http://10.200.242.154.nip.io:8000/api",         // 手机个人热点
  ];

  // 🌟 2. 生产环境真实的线上 Render API 接口地址
  final String _productionUrl = "https://expense-tracker-system-pe3l.onrender.com/api";

  /// 智能自适应雷达探测
  Future<void> findWorkingUrl() async {
    if (isDetected) {
      return;
    }

    // 给生产环境稍长的连接时间（4秒），防止 Render 第一次唤醒超时
    final tempDio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 4000), 
    ));

    // =====================================================================
    // 步骤一：【首要判定】优先测试线上 Render 生产环境 API
    // =====================================================================
    try {
      debugPrint("[雷达探测] 🚀 正在优先测试线上 Render API: $_productionUrl ...");
      await tempDio.get('$_productionUrl/me'); 
      
      currentBaseUrl = _productionUrl;
      dio.options.baseUrl = currentBaseUrl;
      isDetected = true;
      debugPrint("✅ [连接成功] 线上 Render API 可用，已瞬间锁定: $currentBaseUrl");
      return;
    } catch (e) {
      // 允许未登录状态的 401 或 403 视为网络畅通并锁定
      if (e is DioException && e.response != null) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          currentBaseUrl = _productionUrl;
          dio.options.baseUrl = currentBaseUrl;
          isDetected = true;
          debugPrint("✅ [连接成功] 线上 Render API 校验通过并锁定: $currentBaseUrl");
          return;
        }
      }
      debugPrint("❌ [连接失败] 线上 Render API 暂时不可达，原因: $e");
      debugPrint("开始尝试本地局域网节点...");
    }

    // =====================================================================
    // 步骤二：【备用方案】线上不通时，逐个探测本地局域网
    // =====================================================================
    for (String url in _localCandidateUrls) {
      try {
        debugPrint("[雷达探测] 正在连接本地 API: $url ...");
        await tempDio.get('$url/me'); 
        
        currentBaseUrl = url;
        dio.options.baseUrl = currentBaseUrl;
        isDetected = true;
        debugPrint("✅ [连接成功] 已锁定本地 API: $currentBaseUrl");
        return; 
      } catch (e) {
        if (e is DioException && e.response != null) {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            currentBaseUrl = url;
            dio.options.baseUrl = currentBaseUrl;
            isDetected = true;
            debugPrint("✅ [连接成功] 已锁定本地 API: $currentBaseUrl");
            return;
          }
        }
        debugPrint("❌ [连接失败] 本地节点不可达: $url");
        continue;
      }
    }

    // 终极回退
    currentBaseUrl = _productionUrl;
    dio.options.baseUrl = currentBaseUrl;
    isDetected = true;
    debugPrint("⚠️ [探测结束] 所有节点均不可达，已自动回归 Render 线上备用: $currentBaseUrl");
  }
}