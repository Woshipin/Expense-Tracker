// lib/views/dashboard/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/card.dart';
import 'widgets/trend_chart.dart';
import 'widgets/category_chart.dart';
import 'widgets/metric_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // 从后端 /dashboard 获取完整财务数据
  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // 触发智能 API 超时和探测锁定
      await ApiClient().findWorkingUrl();
      
      final response = await ApiClient().dio.get('/dashboard');
      
      if (mounted) {
        setState(() {
          _data = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Dashboard Data Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Unable to retrieve financial metrics.";
          _isLoading = false;
        });
      }
    }
  }

  // 货币金额自适应格式化函数
  String _formatCurrency(num val) {
    final isNegative = val < 0;
    final absoluteValue = val.abs();
    final formattedNum = absoluteValue.toStringAsFixed(2);
    
    // 千分位加逗号
    final parts = formattedNum.split('.');
    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(regExp, (Match m) => '${m[1]},');
    final result = parts.join('.');
    
    return isNegative ? "-RM $result" : "RM $result";
  }

  // 辅助解析颜色代码
  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // 翻译月份简写
  String _getMonthName(int monthNum) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    if (monthNum >= 1 && monthNum <= 12) {
      return months[monthNum - 1];
    }
    return "Month";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: SunsetColors.primary),
              SizedBox(height: 16),
              Text("Compiling financial data...", style: TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _data == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage ?? "An error occurred", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchDashboardData,
                style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.primary),
                child: const Text("Retry", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    final metrics = _data!['metrics'];
    final chartData = _data!['chartData'] as List<dynamic>;
    final pieData = _data!['pieData'] as List<dynamic>;
    final recentExpenses = _data!['recentExpenses'] as List<dynamic>;
    final recentIncomes = _data!['recentIncomes'] as List<dynamic>;
    final budgets = _data!['budgets'] as List<dynamic>;

    // 计算总预算指标
    double totalBudgetLimit = 0;
    double totalBudgetSpent = 0;
    for (var b in budgets) {
      totalBudgetLimit += (b['budget_amount'] as num).toDouble();
      totalBudgetSpent += (b['spent_amount'] as num).toDouble();
    }
    double overallBudgetPercentage = totalBudgetLimit > 0 
        ? (totalBudgetSpent / totalBudgetLimit).clamp(0.0, 1.0) 
        : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [SunsetColors.bgStart, SunsetColors.bgEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dashboard", style: TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.w900, fontSize: 24)),
              Text("An overview of your finances this month", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500))
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_none, color: SunsetColors.dark), onPressed: () {}),
            const SizedBox(width: 16),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth >= 1050;
            bool isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 1050;

            return RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: SunsetColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 1. 顶部四大核心指标卡片 (动态注入数据，完美保留您的 76px 绝对高度设计)
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1), 
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 76, 
                      ),
                      children: [
                        MetricCard(
                          title: "BALANCE", 
                          value: _formatCurrency(metrics['balance'] ?? 0), 
                          icon: Icons.account_balance_wallet_outlined, 
                          color: SunsetColors.balance
                        ),
                        MetricCard(
                          title: "INCOME", 
                          value: _formatCurrency(metrics['income'] ?? 0), 
                          icon: Icons.trending_up, 
                          color: SunsetColors.income
                        ),
                        MetricCard(
                          title: "EXPENSES", 
                          value: _formatCurrency(metrics['expense'] ?? 0), 
                          icon: Icons.trending_down, 
                          color: SunsetColors.expense
                        ),
                        MetricCard(
                          title: "SAVINGS RATE", 
                          value: "${metrics['savingsRate'] ?? 0}%", 
                          icon: Icons.pie_chart_outline, 
                          color: SunsetColors.savings
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 🌟 2. 中间趋势与类别统计图表自适应排版
                    if (isDesktop || isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Expanded(flex: 6, child: _buildTrendChartCard(chartData)),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: _buildCategoryChartCard(pieData)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildTrendChartCard(chartData),
                          const SizedBox(height: 16),
                          _buildCategoryChartCard(pieData),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // 🌟 3. 底部收支列表与预算明细自适应排版
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildRecentExpenses(recentExpenses)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildRecentIncomes(recentIncomes)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildBudgetStatus(budgets, totalBudgetSpent, totalBudgetLimit, overallBudgetPercentage)),
                        ],
                      )
                    else if (isTablet)
                      Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildRecentExpenses(recentExpenses)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRecentIncomes(recentIncomes)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBudgetStatus(budgets, totalBudgetSpent, totalBudgetLimit, overallBudgetPercentage),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildRecentExpenses(recentExpenses),
                          const SizedBox(height: 16),
                          _buildRecentIncomes(recentIncomes),
                          const SizedBox(height: 16),
                          _buildBudgetStatus(budgets, totalBudgetSpent, totalBudgetLimit, overallBudgetPercentage),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 趋势图卡片组件
  Widget _buildTrendChartCard(List<dynamic> chartData) {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Monthly Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: SunsetColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("Last 7 Days", style: TextStyle(color: SunsetColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(height: 250, child: TrendChart(chartData: chartData)),
        ],
      ),
    );
  }

  // 分类环形图卡片组件 (包含动态图表和动态颜色 Legend 标识)
  Widget _buildCategoryChartCard(List<dynamic> pieData) {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Spending this month", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(height: 170, child: CategoryChart(pieData: pieData)),
          const SizedBox(height: 30),
          if (pieData.isNotEmpty)
            ...pieData.map((item) {
              final color = _parseHexColor(item['color']);
              final value = (item['value'] as num).toDouble();
              return _buildCategoryLegend(item['name'] ?? 'Other', _formatCurrency(value), color);
            })
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No spending data.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(String name, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SunsetColors.dark)),
            ],
          ),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SunsetColors.dark)),
        ],
      ),
    );
  }

  // 动态最近支出卡片
  Widget _buildRecentExpenses(List<dynamic> recentExpenses) {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("Recent Expenses", '/expenses'),
          const SizedBox(height: 16),
          if (recentExpenses.isNotEmpty)
            ...List.generate(recentExpenses.length, (index) {
              final item = recentExpenses[index];
              return _buildTransactionItem(
                title: item['title'] ?? 'Expense', 
                subtitle: "${item['category'] ?? 'Other'} • ${item['date'] ?? ''}", 
                amount: "-${_formatCurrency(item['price'] ?? 0)}", 
                isExpense: true,
                isLast: index == recentExpenses.length - 1
              );
            })
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text("No recent expenses.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  // 动态最近收入卡片
  Widget _buildRecentIncomes(List<dynamic> recentIncomes) {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("Recent Incomes", '/income'),
          const SizedBox(height: 16),
          if (recentIncomes.isNotEmpty)
            ...List.generate(recentIncomes.length, (index) {
              final item = recentIncomes[index];
              return _buildTransactionItem(
                title: item['title'] ?? 'Income', 
                subtitle: "${item['category'] ?? 'Other'} • ${item['date'] ?? ''}", 
                amount: "+${_formatCurrency(item['price'] ?? 0)}", 
                isExpense: false,
                isLast: index == recentIncomes.length - 1
              );
            })
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text("No recent incomes.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String title, String routePath) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        InkWell(
          onTap: () {},
          child: const Row(
            children: [
              Text("View all", style: TextStyle(color: SunsetColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(Icons.arrow_forward, size: 14, color: SunsetColors.primary),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTransactionItem({required String title, required String subtitle, required String amount, required bool isExpense, bool isLast = false}) {
    Color color = isExpense ? SunsetColors.expense : const Color(0xFF10B981); 
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isExpense ? Icons.trending_down : Icons.trending_up, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SunsetColors.dark), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  // 动态预算指示板卡片 (同步 Next.js 复杂的指示板块双色条、百分比、剩余计算逻辑)
  Widget _buildBudgetStatus(List<dynamic> budgets, double totalSpent, double totalLimit, double percentage) {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("Budget Status", '/budget'),
          const SizedBox(height: 24),
          
          const Text("TOTAL SPENT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(totalSpent), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: SunsetColors.dark)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text("of ${_formatCurrency(totalLimit)}", style: TextStyle(color: SunsetColors.primary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage, 
              minHeight: 12, 
              backgroundColor: const Color(0xFFFED7AA), 
              valueColor: const AlwaysStoppedAnimation<Color>(SunsetColors.primary)
            ),
          ),
          const SizedBox(height: 30),

          if (budgets.isNotEmpty)
            ...budgets.map((budget) {
              final spent = (budget['spent_amount'] as num).toDouble();
              final limit = (budget['budget_amount'] as num).toDouble();
              final percentVal = (budget['percentage'] as num).toDouble() / 100;
              final remaining = limit - spent;
              final isOverspent = spent > limit;
              final categoryColor = _parseHexColor(budget['category_color']);
              final progressColor = percentVal >= 0.8 ? SunsetColors.expense : const Color(0xFF0D9488);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: const Color(0xFFF1F5F9))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: categoryColor)),
                            const SizedBox(width: 8),
                            Text(budget['category'] ?? 'Category', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SunsetColors.dark)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), 
                              child: Text(
                                "${_getMonthName(budget['month'] ?? 1)} ${budget['year'] ?? ''}", 
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)
                              )
                            ),
                          ],
                        ),
                        Text(
                          "${budget['percentage']}% used", 
                          style: TextStyle(color: percentVal >= 0.8 ? SunsetColors.expense : const Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentVal.clamp(0.0, 1.0), 
                        minHeight: 8, 
                        backgroundColor: const Color(0xFFFEE2E2), 
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor)
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Spent:", style: TextStyle(color: Colors.grey, fontSize: 11)), Text(_formatCurrency(spent), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Limit:", style: TextStyle(color: Colors.grey, fontSize: 11)), Text(_formatCurrency(limit), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: SunsetColors.dark.withValues(alpha: 0.7)))]),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(isOverspent ? "Overspent: " : "Remaining: ", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(
                          _formatCurrency(remaining.abs()), 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOverspent ? SunsetColors.expense : const Color(0xFF10B981))
                        ),
                      ],
                    )
                  ],
                ),
              );
            })
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No budgets configured.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}