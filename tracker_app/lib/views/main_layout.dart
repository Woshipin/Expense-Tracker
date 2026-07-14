// lib/views/main_layout.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/constants/colors.dart';
import '../core/widgets/toast.dart';

import 'categories/category_view.dart';
import 'dashboard/dashboard_view.dart';
import 'payment_methods/payment_methods_view.dart';
import 'profile/profile_view.dart';
import 'expenses/expenses_view.dart';
import 'users/users_view.dart';
import 'types/types_view.dart';
import 'income/income_view.dart';

// 引入子页面
import 'ai_insights/ai_insights_view.dart';
import 'budgets/budget_view.dart';
import 'calendar/calendar_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isSettingsExpanded = false;
  bool _isSidebarOpen = true; // 控制电脑端侧边栏展开/收起
  
  Map<String, dynamic>? _currentUser;
  bool _isLoadingUser = true;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardView(),              // 0: Dashboard
      const AiInsightsView(),             // 1: AI Insights
      const UsersView(),                  // 2: Users
      const CalendarView(),               // 3: Calendar
      const ExpenseListView.expenses(),   // 4: Expenses
      const IncomeView(),                 // 5: Income
      const BudgetView(),                 // 6: Budget
      const ProfileView(),                // 7: Profile
      const TypesView(),                  // 8: Types
      const CategoryView(),               // 9: Categories
      const PaymentMethodsView(),         // 10: Payment Methods
    ];
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await ApiClient().dio.get('/me');
      if (!mounted) return;
      setState(() {
        _currentUser = response.data;
        _isLoadingUser = false;
      });
    } catch (e) {
      debugPrint("Fetch User Profile Error: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  String _getRoleName(int roleId) {
    switch (roleId) {
      case 0: return 'SUPER ADMIN';
      case 1: return 'ADMIN';
      case 2: return 'PREMIUM';
      case 3: return 'BASIC';
      default: return 'USER';
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Confirm Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out of your account?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient().dio.post('/logout');
    } catch (e) {
      debugPrint("Logout API Error: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (mounted) {
      SunsetToast.show(context, "Logged out successfully.", type: SunsetToastType.success);
      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    }
  }

  // 电脑端侧边栏切换按钮组件
  Widget _buildToggleButton({required bool isOpen}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _isSidebarOpen = !isOpen),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white, 
            shape: BoxShape.circle,
            border: Border.all(
              color: SunsetColors.primary, 
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isOpen ? Icons.chevron_left : Icons.chevron_right, 
            size: 16, 
            color: SunsetColors.dark,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: SunsetColors.bgStart,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: SunsetColors.primary),
              SizedBox(height: 20),
              Text(
                "Syncing Sunset Tracker...",
                style: TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      );
    }

    final String userName = _currentUser?['full_name'] ?? 'User';
    final int roleId = int.tryParse(_currentUser?['role']?.toString() ?? '3') ?? 3;
    final String userRole = _getRoleName(roleId);

    final bool canSeeUsers = roleId == 0 || roleId == 1;
    final bool canSeeAiInsights = roleId == 0 || roleId == 1 || roleId == 2;

    if (_currentIndex >= 7 && !_isSettingsExpanded) {
      _isSettingsExpanded = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 650;

        if (isWideScreen) {
          return Scaffold(
            backgroundColor: SunsetColors.bgStart,
            body: Row(
              children: [
                // ---------------- 电脑端侧边栏 (Sidebar Desktop) ----------------
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isSidebarOpen ? 260 : 85, 
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEE8DB), Color(0xFFFFFaf5)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border(right: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        child: _isSidebarOpen
                            ? Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(12)),
                                    alignment: Alignment.center,
                                    child: const Text("+", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SunsetColors.dark)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Sunset", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: SunsetColors.dark, height: 1.1)),
                                        Text("EXPENSE TRACKER", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                                      ],
                                    ),
                                  ),
                                  _buildToggleButton(isOpen: true),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(12)),
                                    alignment: Alignment.center,
                                    child: const Text("+", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SunsetColors.dark)),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildToggleButton(isOpen: false),
                                ],
                              ),
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: _isSidebarOpen ? 16.0 : 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SunsetColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: SunsetColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_isSidebarOpen) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: SunsetColors.dark), overflow: TextOverflow.ellipsis),
                                      Text(userRole, style: const TextStyle(fontSize: 9, color: SunsetColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            _buildSidebarButton(title: "Dashboard", icon: Icons.dashboard_outlined, index: 0),
                            if (canSeeUsers) _buildSidebarButton(title: "Users", icon: Icons.people_outline, index: 2),
                            if (canSeeAiInsights) _buildSidebarButton(title: "AI Insights", icon: Icons.auto_awesome, index: 1),
                            _buildSidebarButton(title: "Expenses", icon: Icons.receipt_long, index: 4),
                            _buildSidebarButton(title: "Income", icon: Icons.attach_money, index: 5),
                            _buildSidebarButton(title: "Budget", icon: Icons.pie_chart_outline, index: 6),
                            _buildSidebarButton(title: "Calendar", icon: Icons.calendar_today, index: 3),
                            
                            if (!_isSidebarOpen)
                              _buildSidebarButton(title: "Settings", icon: Icons.settings_outlined, index: 7, onTapOverride: () {
                                setState(() {
                                  _isSidebarOpen = true;
                                  _isSettingsExpanded = true;
                                });
                              })
                            else
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  leading: const Icon(Icons.settings_outlined, size: 20, color: SunsetColors.dark),
                                  title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SunsetColors.dark)),
                                  initiallyExpanded: _isSettingsExpanded,
                                  onExpansionChanged: (expanded) => setState(() => _isSettingsExpanded = expanded),
                                  children: [
                                    _buildSidebarSubButton(title: "Profile", icon: Icons.person_outline, index: 7),
                                    _buildSidebarSubButton(title: "Types", icon: Icons.layers_outlined, index: 8),
                                    _buildSidebarSubButton(title: "Categories", icon: Icons.sell_outlined, index: 9),
                                    _buildSidebarSubButton(title: "Payment Methods", icon: Icons.credit_card_outlined, index: 10),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildSidebarButton(title: "Logout", icon: Icons.logout, index: -1, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _pages[_currentIndex]),
              ],
            ),
          );
        } else {
          // ---------------- 📱 手机端 (Mobile View with Standard Full-width Navigation) ----------------
          
          // 核心调整：5个按钮固定显示在底部栏，且无视角色限制，始终可见
          List<BottomNavigationBarItem> bottomNavItems = [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: "Dash"),
            const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: "Expenses"),
            const BottomNavigationBarItem(icon: Icon(Icons.attach_money_outlined), label: "Income"),
            const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: "AI"),
            const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
          ];

          List<int> bottomNavIndices = [0, 4, 5, 1, -1];

          // 重新校准当前选中的 BottomNavigationBar 索引值，防止因 More 页引起的高亮错乱
          int bottomNavCurrentIndex = bottomNavIndices.indexOf(_currentIndex);
          if (bottomNavCurrentIndex == -1) {
            bottomNavCurrentIndex = bottomNavIndices.length - 1; // 回退到高亮最右侧 Settings 键
          }

          return Scaffold(
            body: SafeArea(
              top: false,
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
            // 改回原本的扁平式底栏设计
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: bottomNavCurrentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: SunsetColors.primary,
              unselectedItemColor: SunsetColors.dark.withValues(alpha: 0.4),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              onTap: (index) {
                int targetIndex = bottomNavIndices[index];
                if (targetIndex == -1) {
                  _showMobileSettingsMenu(userName, userRole, canSeeUsers);
                } else {
                  setState(() => _currentIndex = targetIndex);
                }
              },
              items: bottomNavItems,
            ),
          );
        }
      },
    );
  }

  // 电脑端菜单按钮
  Widget _buildSidebarButton({required String title, required IconData icon, required int index, Color? color, VoidCallback? onTapOverride}) {
    bool isSelected = _currentIndex == index;
    
    Widget buttonContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isSidebarOpen ? 16 : 0, 
        vertical: _isSidebarOpen ? 12 : 14 
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? SunsetColors.primary : Colors.transparent, 
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        mainAxisAlignment: _isSidebarOpen ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isSelected ? Colors.white : (color ?? SunsetColors.dark)),
          if (_isSidebarOpen) ...[
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : (color ?? SunsetColors.dark))),
          ]
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: onTapOverride ?? () {
          if (index == -1) {
            _handleLogout();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: !_isSidebarOpen 
            ? Tooltip(message: title, preferBelow: false, child: buttonContent) 
            : buttonContent,
      ),
    );
  }

  // 电脑端 Settings 展开子菜单按钮
  Widget _buildSidebarSubButton({required String title, required IconData icon, required int index}) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 2, bottom: 2, right: 8),
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: isSelected ? SunsetColors.primary.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? SunsetColors.primary : SunsetColors.dark),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? SunsetColors.primary : SunsetColors.dark)),
            ],
          ),
        ),
      ),
    );
  }

  // 手机端 Bottom Sheet 独立大按钮 (高圆角适配)
  Widget _buildMobileMenuButton({required String title, required IconData icon, required int index, Color? color}) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          if (index == -1) {
            _handleLogout();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? SunsetColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : (color ?? SunsetColors.dark)),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? Colors.white : (color ?? SunsetColors.dark))),
            ],
          ),
        ),
      ),
    );
  }

  // 手机端 Settings 弹出菜单
  void _showMobileSettingsMenu(String userName, String userRole, bool canSeeUsers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFEE8DB), Color(0xFFFFFaf5)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(bottom: BorderSide(color: Color(0x1AF97316))),
                  ),
                  child: Column(
                    children: [
                      Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: SunsetColors.primary.withValues(alpha: 0.15),
                              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.w900, fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: SunsetColors.dark)),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: SunsetColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(userRole, style: const TextStyle(color: SunsetColors.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 32, bottom: 8, top: 4),
                        child: Text("FEATURES", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                      if (canSeeUsers)
                        _buildMobileMenuButton(title: "Users", icon: Icons.people_outline, index: 2),
                      // 🌟 Budget 完美在 More/Settings 页面渲染
                      _buildMobileMenuButton(title: "Budget", icon: Icons.pie_chart_outline, index: 6),
                      _buildMobileMenuButton(title: "Calendar", icon: Icons.calendar_today, index: 3),
                      
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Divider(height: 1, color: Color(0xFFF3F4F6))),
                      
                      const Padding(
                        padding: EdgeInsets.only(left: 32, bottom: 8, top: 4),
                        child: Text("SETTINGS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                      _buildMobileMenuButton(title: "Profile", icon: Icons.person_outline, index: 7),
                      _buildMobileMenuButton(title: "Types", icon: Icons.layers_outlined, index: 8),
                      _buildMobileMenuButton(title: "Categories", icon: Icons.sell_outlined, index: 9),
                      _buildMobileMenuButton(title: "Payment Methods", icon: Icons.credit_card_outlined, index: 10),

                      const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Divider(height: 1, color: Color(0xFFF3F4F6))),
                      
                      _buildMobileMenuButton(title: "Logout", icon: Icons.logout, index: -1, color: Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}