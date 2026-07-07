import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';

typedef JsonMap = Map<String, dynamic>;

class PagedResult {
  final List<JsonMap> items;
  final int totalPages;

  const PagedResult({required this.items, required this.totalPages});
}

PagedResult parsePaged(dynamic payload) {
  final List<dynamic> rawItems = payload is Map<String, dynamic>
      ? (payload['data'] as List<dynamic>? ?? [])
      : (payload as List<dynamic>? ?? []);
  return PagedResult(
    items: rawItems.map((item) => Map<String, dynamic>.from(item)).toList(),
    totalPages: payload is Map<String, dynamic>
        ? int.tryParse('${payload['last_page'] ?? 1}') ?? 1
        : 1,
  );
}

String fieldText(JsonMap item, String key, [String fallback = '']) {
  final value = item[key];
  if (value == null) return fallback;
  return value.toString();
}

int fieldInt(JsonMap item, String key, [int fallback = 0]) {
  return int.tryParse('${item[key] ?? fallback}') ?? fallback;
}

String nestedText(JsonMap item, String parent, String key, [String fallback = 'N/A']) {
  final nested = item[parent];
  if (nested is Map && nested[key] != null) return nested[key].toString();
  return fallback;
}

Color colorFromHex(String value, [Color fallback = SunsetColors.secondary]) {
  final cleaned = value.replaceAll('#', '').trim();
  final hex = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(hex, radix: 16) ?? fallback.toARGB32());
}

String hexFromColor(Color color) {
  final value = color.toARGB32() & 0x00FFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}

String initials(String value, [String fallback = 'U']) {
  final clean = value.trim();
  if (clean.isEmpty) return fallback;
  
  final str = clean
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .join()
      .toUpperCase();
      
  if (str.isEmpty) return fallback;
  return str.length > 1 ? str.substring(0, 2) : str;
}

String money(dynamic value) {
  final number = double.tryParse('${value ?? 0}') ?? 0;
  return number.toStringAsFixed(2);
}

IconData iconForName(String name) {
  switch (name) {
    case 'Utensils': return Icons.restaurant;
    case 'ShoppingCart': return Icons.shopping_cart_outlined;
    case 'Briefcase': return Icons.business_center_outlined;
    case 'Car': return Icons.directions_car_outlined;
    case 'Home': return Icons.home_outlined;
    case 'Bolt': return Icons.bolt_outlined;
    case 'Clapperboard': return Icons.movie_creation_outlined;
    case 'Heart': return Icons.favorite_border;
    case 'Book': return Icons.menu_book_outlined;
    case 'Plane': return Icons.flight_takeoff_outlined;
    case 'Laptop': return Icons.laptop_mac_outlined;
    case 'TrendingUp': return Icons.trending_up;
    case 'Sparkles': return Icons.auto_awesome;
    case 'Gift': return Icons.card_giftcard_outlined;
    case 'Coffee': return Icons.local_cafe_outlined;
    case 'Wallet': return Icons.account_balance_wallet_outlined;
    case 'Banknote': return Icons.payments_outlined;
    case 'Landmark': return Icons.account_balance_outlined;
    case 'QrCode': return Icons.qr_code_2_outlined;
    case 'DollarSign': return Icons.attach_money;
    case 'Coins': return Icons.monetization_on_outlined;
    case 'Smartphone': return Icons.phone_android_outlined;
    case 'CreditCard': return Icons.credit_card_outlined;
    case 'Tag':
    default: return Icons.sell_outlined;
  }
}

class DebouncedSearchController {
  final TextEditingController controller = TextEditingController();
  Timer? _timer;

  void onChanged(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), callback);
  }

  void dispose() {
    _timer?.cancel();
    controller.dispose();
  }
}

Future<PagedResult> fetchPaged(String endpoint, {required int page, Map<String, dynamic> params = const {}}) async {
  final response = await ApiClient().dio.get(endpoint, queryParameters: {'page': page, ...params});
  return parsePaged(response.data);
}

String dioMessage(DioException e, String fallback) {
  final data = e.response?.data;
  if (data is Map) {
    return (data['message'] ?? data['error'] ?? fallback).toString();
  }
  return fallback;
}

void showApiError(BuildContext context, DioException e, String fallback) {
  SunsetToast.show(context, dioMessage(e, fallback), type: SunsetToastType.error);
}

// 🌟🌟 核心修复区域：PageScaffold 🌟🌟
class PageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;

  const PageScaffold({super.key, required this.title, required this.subtitle, this.action, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SunsetColors.bgStart,
      body: SafeArea(
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
          // 🌟 修复点：用 Align 代替 Center，用 SizedBox 强制撑满可用宽度，用 stretch 强制子组件拉伸
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: SizedBox(
                width: double.infinity, // 强制达到最大可用宽度
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // 强制所有子组件横向填满
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 640;
                        final headerText = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: SunsetColors.dark, fontSize: 26, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            Text(subtitle, style: const TextStyle(color: Color(0x992D2520), fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        );
                        if (action == null) return headerText;
                        return Flex(
                          direction: wide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(flex: wide ? 1 : 0, child: headerText),
                            SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 14),
                            action!,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const PrimaryActionButton({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: SunsetColors.secondary,
        foregroundColor: Colors.white,
        elevation: 7,
        shadowColor: SunsetColors.secondary.withValues(alpha: 0.22),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final dynamic status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status.toString() == '1';
    return Chip(
      label: Text(active ? 'Active' : 'Inactive'),
      labelStyle: TextStyle(color: active ? const Color(0xFF059669) : Colors.red, fontSize: 11, fontWeight: FontWeight.w900),
      backgroundColor: active ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final dynamic role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final text = switch (role.toString()) {
      '0' => 'SuperAdmin', '1' => 'Admin', '2' => 'Premium User', '3' => 'Basic User', _ => 'Unknown',
    };
    final color = switch (role.toString()) {
      '0' => const Color(0xFF9333EA), '1' => const Color(0xFF4F46E5), '2' => const Color(0xFFD97706), _ => const Color(0xFF64748B),
    };
    return Chip(
      label: Text(text),
      labelStyle: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class ProviderBadge extends StatelessWidget {
  final dynamic provider;
  const ProviderBadge({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final value = provider?.toString();
    final text = value == null || value.isEmpty ? 'Standard' : value[0].toUpperCase() + value.substring(1);
    final color = value == 'google' ? Colors.red : value == 'facebook' ? Colors.blue : const Color(0xFF2563EB);
    return Chip(
      label: Text(text),
      labelStyle: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      backgroundColor: color.withValues(alpha: 0.09),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

InputDecoration sunsetFieldDecoration(String hint, {IconData? icon, Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 19, color: const Color(0x662D2520)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    isDense: true, // 🌟 修复边框裁切的关键
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.28)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SunsetColors.primary, width: 1.5),
    ),
  );
}

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPage;
  const PaginationBar({super.key, required this.currentPage, required this.totalPages, required this.onPage});

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade100)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            Text('Page $currentPage of $totalPages', style: const TextStyle(color: Color(0x992D2520), fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 14),
            _pageIcon(Icons.chevron_left, currentPage > 1, () => onPage(currentPage - 1)),
            const SizedBox(width: 8),
            ...List.generate(totalPages, (index) {
              final page = index + 1;
              final selected = page == currentPage;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onPage(page),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36, height: 36, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? SunsetColors.primary.withValues(alpha: 0.10) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? SunsetColors.primary.withValues(alpha: 0.30) : Colors.grey.shade200),
                    ),
                    child: Text('$page', style: TextStyle(color: selected ? SunsetColors.primary : const Color(0x992D2520), fontWeight: FontWeight.w900)),
                  ),
                ),
              );
            }),
            _pageIcon(Icons.chevron_right, currentPage < totalPages, () => onPage(currentPage + 1)),
          ],
        ),
      ),
    );
  }

  Widget _pageIcon(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 36, height: 36, alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Icon(icon, size: 18, color: SunsetColors.dark),
        ),
      ),
    );
  }
}

class ActionButtons extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ActionButtons({super.key, required this.onView, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.visibility_outlined, Colors.blue, onView),
          _button(Icons.edit_outlined, const Color(0xFF10B981), onEdit),
          _button(Icons.delete_outline, Colors.red, onDelete),
        ],
      ),
    );
  }

  Widget _button(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: color.withValues(alpha: 0.82))),
    );
  }
}

// 🌟 修复确认删除弹窗
Future<bool> confirmDeleteDialog(BuildContext context, {required String title, required String name, required IconData icon}) async {
  final isMobile = MediaQuery.of(context).size.width < 600;
  
  final result = await showDialog<bool>(
    context: context,
    barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
    builder: (context) => Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: isMobile ? double.infinity : 460, // 🌟 自适应宽度
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85), // 🌟 限制最高高度
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🌟 根据内容收缩
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(title, style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            Flexible(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This action cannot be undone.', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFEE2E2))),
                      child: Row(
                        children: [
                          Icon(icon, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(child: Text(name, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}