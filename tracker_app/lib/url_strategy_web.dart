import 'package:flutter_web_plugins/url_strategy.dart';

void configureUrlStrategy() {
  // 仅在 Web 端去除 URL 哈希 `#` 号
  usePathUrlStrategy();
}