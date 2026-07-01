import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/constants/colors.dart';
import '../core/widgets/toast.dart';
import 'dashboard/dashboard_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  bool _isSettingsExpanded = false;
  
  Map<String, dynamic>? _currentUser;
  bool _isLoadingUser = true;

  final List<Widget> _pages = [
    const DashboardView(),
    const Center(child: Text("AI Insights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Users", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Calendar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Income", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Budget", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Profile Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Types Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Categories Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
    const Center(child: Text("Payment Methods Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await ApiClient().dio.get('/me');
      setState(() {
        _currentUser = response.data;
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  String _getRoleName(dynamic role) {
    if (role == null) return "User";
    int roleId = int.tryParse(role.toString()) ?? 3;
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

  @override
  Widget build(BuildContext context) {
    final String userName = _currentUser?['full_name'] ?? (_isLoadingUser ? 'Loading...' : 'User');
    final String userRole = _getRoleName(_currentUser?['role']);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth >= 800;

        if (isWideScreen) {
          return Scaffold(
            backgroundColor: SunsetColors.bgStart,
            body: Row(
              children: [
                Container(
                  width: 260,
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
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.center,
                              child: const Text("+", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SunsetColors.dark)),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Sunset", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: SunsetColors.dark, height: 1.1)),
                                Text("EXPENSE TRACKER", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SunsetColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: SunsetColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
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
                            _buildSidebarButton(title: "AI Insights", icon: Icons.bar_chart, index: 1),
                            _buildSidebarButton(title: "Users", icon: Icons.people_outline, index: 2),
                            _buildSidebarButton(title: "Calendar", icon: Icons.calendar_today, index: 3),
                            _buildSidebarButton(title: "Expenses", icon: Icons.receipt_long, index: 4),
                            _buildSidebarButton(title: "Income", icon: Icons.attach_money, index: 5),
                            _buildSidebarButton(title: "Budget", icon: Icons.pie_chart_outline, index: 6),
                            
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: const Icon(Icons.settings_outlined, size: 20),
                                title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          return Scaffold(
            body: _pages[_currentIndex >= 7 ? 0 : _currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex >= 7 ? 0 : _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: SunsetColors.primary,
              unselectedItemColor: SunsetColors.dark.withValues(alpha: 0.4),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              onTap: (index) {
                if (index == 5) {
                  _showMobileMoreMenu(userName, userRole);
                } else {
                  final indexMap = [0, 4, 5, 1, 6]; 
                  setState(() => _currentIndex = indexMap[index]);
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: "Dash"),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Expenses"),
                BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Income"),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "AI"),
                BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: "Budget"),
                BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSidebarButton({required String title, required IconData icon, required int index, Color? color}) {
    bool isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: () {
          if (index == -1) {
            _handleLogout();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: isSelected ? SunsetColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : (color ?? SunsetColors.dark)),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? Colors.white : (color ?? SunsetColors.dark))),
            ],
          ),
        ),
      ),
    );
  }

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

  void _showMobileMoreMenu(String userName, String userRole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: SunsetColors.primary.withValues(alpha: 0.1),
                    child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(userRole, style: const TextStyle(color: SunsetColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              
              ListTile(leading: const Icon(Icons.people_outline, color: SunsetColors.dark), title: const Text("Users", style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); setState(() => _currentIndex = 2); }),
              ListTile(leading: const Icon(Icons.calendar_today, color: SunsetColors.dark), title: const Text("Calendar", style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); setState(() => _currentIndex = 3); }),
              ListTile(leading: const Icon(Icons.person_outline, color: SunsetColors.dark), title: const Text("Profile Settings", style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); setState(() => _currentIndex = 7); }),
              ListTile(leading: const Icon(Icons.layers_outlined, color: SunsetColors.dark), title: const Text("Types Settings", style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); setState(() => _currentIndex = 8); }),
              ListTile(leading: const Icon(Icons.sell_outlined, color: SunsetColors.dark), title: const Text("Categories Settings", style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); setState(() => _currentIndex = 9); }),
              ListTile(leading: const Icon(Icons.credit_card_outlined, color: SunsetColors.dark), title: const Text("Payment Methods", style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); setState(() => _currentIndex = 10); }),
              const Divider(),
              ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); _handleLogout(); }),
            ],
          ),
        );
      },
    );
  }
}