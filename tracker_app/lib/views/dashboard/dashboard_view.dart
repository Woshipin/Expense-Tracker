import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/card.dart';
import 'widgets/trend_chart.dart';
import 'widgets/category_chart.dart';
import 'widgets/metric_card.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 完美修复：锁定绝对高度 76px，去除 childAspectRatio 带来的虚高和多余 Padding
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1), 
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 76, // 🌟 核心修改：锁定高度为 76px！消灭一切比例引起的虚高！
                    ),
                    children: const [
                      MetricCard(title: "BALANCE", value: "-RM 250.00", icon: Icons.account_balance_wallet_outlined, color: SunsetColors.balance),
                      MetricCard(title: "INCOME", value: "RM 10,000.00", icon: Icons.trending_up, color: SunsetColors.income),
                      MetricCard(title: "EXPENSES", value: "RM 10,250.00", icon: Icons.trending_down, color: SunsetColors.expense),
                      MetricCard(title: "SAVINGS RATE", value: "-2.5%", icon: Icons.pie_chart_outline, color: SunsetColors.savings),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isDesktop || isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Expanded(flex: 6, child: _buildTrendChartCard()),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: _buildCategoryChartCard()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildTrendChartCard(),
                        const SizedBox(height: 16),
                        _buildCategoryChartCard(),
                      ],
                    ),
                  const SizedBox(height: 20),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRecentExpenses()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildRecentIncomes()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildBudgetStatus()),
                      ],
                    )
                  else if (isTablet)
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRecentExpenses()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRecentIncomes()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildBudgetStatus(),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRecentExpenses(),
                        const SizedBox(height: 16),
                        _buildRecentIncomes(),
                        const SizedBox(height: 16),
                        _buildBudgetStatus(),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrendChartCard() {
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
          const SizedBox(height: 250, child: TrendChart()),
        ],
      ),
    );
  }

  Widget _buildCategoryChartCard() {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Spending this month", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          const SizedBox(height: 170, child: CategoryChart()),
          const SizedBox(height: 30),
          _buildCategoryLegend("aaa", "RM 9150.00", const Color(0xFF64748B)),
          _buildCategoryLegend("Food & Drinks", "RM 1000.00", SunsetColors.expense),
          _buildCategoryLegend("Transport", "RM 100.00", const Color(0xFFF59E0B)),
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

  Widget _buildRecentExpenses() {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("Recent Expenses"),
          const SizedBox(height: 16),
          _buildTransactionItem(title: "qqq", subtitle: "Food & Drinks • Jun 25, 2026", amount: "-RM 1000.00", isExpense: true),
          _buildTransactionItem(title: "ccc", subtitle: "aaa • Jun 24, 2026", amount: "-RM 6000.00", isExpense: true),
          _buildTransactionItem(title: "aaa", subtitle: "aaa • Jun 24, 2026", amount: "-RM 1000.00", isExpense: true),
          _buildTransactionItem(title: "bbb", subtitle: "aaa • Jun 24, 2026", amount: "-RM 2000.00", isExpense: true),
          _buildTransactionItem(title: "Dinner with friends", subtitle: "aaa • Jun 22, 2026", amount: "-RM 150.00", isExpense: true, isLast: true),
        ],
      ),
    );
  }

  Widget _buildRecentIncomes() {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("Recent Incomes"),
          const SizedBox(height: 16),
          _buildTransactionItem(title: "May Full Salary", subtitle: "Salary • Jun 22, 2026", amount: "+RM 10000.00", isExpense: false),
          _buildTransactionItem(title: "UI Design Project", subtitle: "Freelance • May 22, 2026", amount: "+RM 3000.00", isExpense: false, isLast: true),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String title) {
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SunsetColors.dark)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildBudgetStatus() {
    return SunsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("Budget Status"),
          const SizedBox(height: 24),
          
          const Text("TOTAL SPENT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("RM 9,150.00", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: SunsetColors.dark)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text("of RM 10,000.00", style: TextStyle(color: SunsetColors.primary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(value: 0.915, minHeight: 12, backgroundColor: Color(0xFFFED7AA), valueColor: AlwaysStoppedAnimation<Color>(SunsetColors.primary)),
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        const Text("aaa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SunsetColors.dark)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: const Text("Jun 2026", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Text("91.5% used", style: TextStyle(color: SunsetColors.expense, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(value: 0.915, minHeight: 8, backgroundColor: Color(0xFFFEE2E2), valueColor: AlwaysStoppedAnimation<Color>(SunsetColors.expense)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Spent:", style: TextStyle(color: Colors.grey, fontSize: 11)), Text("RM 9,150.00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Limit:", style: TextStyle(color: Colors.grey, fontSize: 11)), Text("RM 10,000.00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: SunsetColors.dark.withValues(alpha: 0.7)))]),
                  ],
                ),
                const Divider(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Remaining: ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text("RM 850.00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}