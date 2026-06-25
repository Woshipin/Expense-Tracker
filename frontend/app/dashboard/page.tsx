"use client";

import { Card, Toast } from "@/components/ui";
import { Wallet, TrendingUp, TrendingDown, PiggyBank, ArrowRight, Loader2 } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import api from "@/lib/axios";

interface DashboardMetrics {
  balance: number;
  income: number;
  expense: number;
  savingsRate: number;
}

interface ChartItem {
  name: string;
  income: number;
  expense: number;
}

interface PieItem {
  name: string;
  value: number;
  color: string;
}

interface TransactionItem {
  id: number;
  title: string;
  category: string;
  date: string;
  price: number;
  type: string;
}

interface BudgetItem {
  id: number;
  category: string;
  category_color?: string; // 新增：分类主题色
  budget_amount: number;
  spent_amount: number;
  percentage: number;
  month: number; // 新增：预算月份
  year: number; // 新增：预算年份
}

interface DashboardData {
  metrics: DashboardMetrics;
  chartData: ChartItem[];
  pieData: PieItem[];
  recentExpenses: TransactionItem[];
  recentIncomes: TransactionItem[];
  budgets: BudgetItem[];
}

export default function DashboardPage() {
  const router = useRouter();
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'warning' } | null>(null);
  const [data, setData] = useState<DashboardData | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setIsLoading(true);
        const response = await api.get('/dashboard');
        setData(response.data);
      } catch (error: any) {
        console.error("Failed to fetch dashboard metrics:", error);
        setToast({ message: "Unable to retrieve dashboard metrics.", type: "error" });
      } finally {
        setIsLoading(false);
      }
    };
    fetchDashboardData();
  }, []);

  const formatCurrency = (val: number) => {
    const isNegative = val < 0;
    const absoluteValue = Math.abs(val);
    const formattedNum = absoluteValue.toLocaleString('en-US', { 
      minimumFractionDigits: 2, 
      maximumFractionDigits: 2 
    });
    return isNegative ? `-RM ${formattedNum}` : `RM ${formattedNum}`;
  };

  // 数字月份转换为文字简写
  const getMonthName = (monthNum: number) => {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[monthNum - 1] || "Month";
  };

  if (isLoading || !data) {
    return (
      <div className="h-[70vh] w-full flex flex-col items-center justify-center">
        <Loader2 className="w-12 h-12 text-sunset-primary animate-spin mb-4" />
        <p className="text-sunset-dark/60 font-semibold text-sm">Compiling financial data...</p>
      </div>
    );
  }

  const totalBudgetLimit = data.budgets.reduce((acc, curr) => acc + curr.budget_amount, 0);
  const totalBudgetSpent = data.budgets.reduce((acc, curr) => acc + curr.spent_amount, 0);
  const overallBudgetPercentage = totalBudgetLimit > 0 ? Math.min(100, (totalBudgetSpent / totalBudgetLimit) * 100) : 0;

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300 pb-10">
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
      
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">Dashboard</h1>
          <p className="text-sm text-sunset-dark/60 mt-1">An overview of your finances this month</p>
        </div>
      </header>

      {/* 1. 顶部四大核心卡片 */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {/* Balance Card */}
        <Card className="p-5 border border-purple-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
          <div className="w-12 h-12 rounded-2xl bg-[#7c3aed] text-white flex items-center justify-center shrink-0 shadow-md shadow-purple-500/20">
            <Wallet size={22} strokeWidth={2.5} />
          </div>
          <div>
            <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Balance</p>
            <h3 className="text-xl font-black text-gray-900 mt-0.5">{formatCurrency(data.metrics.balance)}</h3>
          </div>
        </Card>

        {/* Income Card */}
        <Card className="p-5 border border-teal-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
          <div className="w-12 h-12 rounded-2xl bg-[#0d9488] text-white flex items-center justify-center shrink-0 shadow-md shadow-teal-500/20">
            <TrendingUp size={22} strokeWidth={2.5} />
          </div>
          <div>
            <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Income</p>
            <h3 className="text-xl font-black text-gray-900 mt-0.5">{formatCurrency(data.metrics.income)}</h3>
          </div>
        </Card>

        {/* Expenses Card */}
        <Card className="p-5 border border-red-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
          <div className="w-12 h-12 rounded-2xl bg-[#ef4444] text-white flex items-center justify-center shrink-0 shadow-md shadow-red-500/20">
            <TrendingDown size={22} strokeWidth={2.5} />
          </div>
          <div>
            <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Expenses</p>
            <h3 className="text-xl font-black text-gray-900 mt-0.5">{formatCurrency(data.metrics.expense)}</h3>
          </div>
        </Card>

        {/* Savings Rate Card */}
        <Card className="p-5 border border-blue-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
          <div className="w-12 h-12 rounded-2xl bg-[#2563eb] text-white flex items-center justify-center shrink-0 shadow-md shadow-blue-500/20">
            <PiggyBank size={22} strokeWidth={2.5} />
          </div>
          <div>
            <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Savings Rate</p>
            <h3 className="text-xl font-black text-gray-900 mt-0.5">{data.metrics.savingsRate}%</h3>
          </div>
        </Card>
      </div>

      {/* 2. 中间图表部分 */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
        {/* Monthly Trend */}
        <Card className="xl:col-span-2 shadow-sm border border-sunset-primary/10 flex flex-col rounded-2xl p-6 bg-white min-w-0">
          <div className="flex items-center justify-between mb-6 shrink-0">
            <h3 className="font-bold text-sunset-dark">Monthly Trend</h3>
            <span className="text-xs bg-sunset-primary/15 text-sunset-primary font-bold px-2.5 py-1 rounded-xl">
              Last 7 Days
            </span>
          </div>
          <div className="flex-1 w-full min-h-[250px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data.chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorExpense" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#0d9488" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#0d9488" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#2D1B14', opacity: 0.5 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#2D1B14', opacity: 0.5 }} dx={-10} />
                <Tooltip 
                  contentStyle={{ borderRadius: '16px', border: '1px solid rgba(255,123,66,0.1)', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}
                  itemStyle={{ color: '#2D1B14', fontWeight: 600 }}
                  formatter={(value: any, name: any) => [`RM ${value}`, String(name).charAt(0).toUpperCase() + String(name).slice(1)]}
                />
                <Area type="monotone" dataKey="income" stroke="#0d9488" strokeWidth={3} fillOpacity={1} fill="url(#colorIncome)" />
                <Area type="monotone" dataKey="expense" stroke="#ef4444" strokeWidth={3} fillOpacity={1} fill="url(#colorExpense)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Top Categories */}
        <Card className="shadow-sm border border-sunset-primary/10 flex flex-col rounded-2xl p-6 bg-white min-w-0">
          <h3 className="font-bold text-sunset-dark mb-1">Top Categories</h3>
          <p className="text-xs text-sunset-dark/50 mb-4">Spending this month</p>
          <div className="flex-1 flex flex-col justify-center">
            {data.pieData.length > 0 ? (
              <>
                <div className="h-[180px] w-full relative">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={data.pieData}
                        cx="50%"
                        cy="50%"
                        innerRadius={55}
                        outerRadius={75}
                        paddingAngle={3}
                        dataKey="value"
                        stroke="none"
                      >
                        {data.pieData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(v:any) => `RM ${v}`} wrapperClassName="rounded-xl overflow-hidden" contentStyle={{ border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}/>
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="mt-2 space-y-2">
                  {data.pieData.map((item) => (
                    <div key={item.name} className="flex items-center justify-between text-xs">
                      <div className="flex items-center gap-2">
                        <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: item.color }} />
                        <span className="font-medium text-sunset-dark/70">{item.name}</span>
                      </div>
                      <span className="font-bold text-sunset-dark">RM {item.value.toFixed(2)}</span>
                    </div>
                  ))}
                </div>
              </>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-gray-400 text-xs py-10">
                No monthly spending data.
              </div>
            )}
          </div>
        </Card>
      </div>

      {/* 3. 底部版块 */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        
        {/* Recent Expenses */}
        <Card className="p-6 bg-white rounded-2xl shadow-sm border border-sunset-primary/10">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-sunset-dark">Recent Expenses</h3>
            <button onClick={() => router.push('/expenses')} className="text-sm text-[#ef4444] font-bold hover:underline flex items-center">
              View all <ArrowRight size={14} className="ml-1" />
            </button>
          </div>
          <div className="space-y-4">
            {data.recentExpenses && data.recentExpenses.length > 0 ? (
              data.recentExpenses.map((expense) => (
                <div key={expense.id} className="flex items-center justify-between pb-4 border-b border-gray-100 last:border-0 last:pb-0">
                  <div className="flex items-center gap-4 min-w-0">
                    <div className="w-10 h-10 rounded-full flex items-center justify-center bg-red-50 text-[#ef4444] shrink-0">
                      <TrendingDown size={18} />
                    </div>
                    <div className="min-w-0">
                      <p className="font-bold text-sm text-gray-900 truncate">{expense.title}</p>
                      <p className="text-xs text-gray-500 truncate">{expense.category} • {expense.date}</p>
                    </div>
                  </div>
                  <div className="font-bold text-sm text-[#ef4444] shrink-0 ml-2">
                    -RM {expense.price.toFixed(2)}
                  </div>
                </div>
              ))
            ) : (
              <p className="text-sm text-gray-400 text-center py-10">No recent expenses found.</p>
            )}
          </div>
        </Card>

        {/* Recent Incomes */}
        <Card className="p-6 bg-white rounded-2xl shadow-sm border border-sunset-primary/10">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-sunset-dark">Recent Incomes</h3>
            <button onClick={() => router.push('/income')} className="text-sm text-[#0d9488] font-bold hover:underline flex items-center">
              View all <ArrowRight size={14} className="ml-1" />
            </button>
          </div>
          <div className="space-y-4">
            {data.recentIncomes && data.recentIncomes.length > 0 ? (
              data.recentIncomes.map((income) => (
                <div key={income.id} className="flex items-center justify-between pb-4 border-b border-gray-100 last:border-0 last:pb-0">
                  <div className="flex items-center gap-4 min-w-0">
                    <div className="w-10 h-10 rounded-full flex items-center justify-center bg-teal-50 text-[#0d9488] shrink-0">
                      <TrendingUp size={18} />
                    </div>
                    <div className="min-w-0">
                      <p className="font-bold text-sm text-gray-900 truncate">{income.title}</p>
                      <p className="text-xs text-gray-500 truncate">{income.category} • {income.date}</p>
                    </div>
                  </div>
                  <div className="font-bold text-sm text-[#0d9488] shrink-0 ml-2">
                    +RM {income.price.toFixed(2)}
                  </div>
                </div>
              ))
            ) : (
              <p className="text-sm text-gray-400 text-center py-10">No recent incomes found.</p>
            )}
          </div>
        </Card>

        {/* Budget Status 板块 - 进行了数据可视化与细目设计升级 */}
        <Card className="p-6 bg-white rounded-2xl shadow-sm border border-sunset-primary/10 md:col-span-2 xl:col-span-1">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-sunset-dark">Budget Status</h3>
            <button onClick={() => router.push('/budget')} className="text-sm text-sunset-primary font-bold hover:underline flex items-center">
              View all <ArrowRight size={14} className="ml-1" />
            </button>
          </div>
          
          {/* 总指标进度 */}
          <div className="mb-6 bg-sunset-primary/5 p-4 rounded-2xl border border-sunset-primary/10">
            <div className="flex justify-between items-end mb-2">
              <div>
                <p className="text-[10px] text-gray-400 uppercase font-black tracking-wider">Total Spent</p>
                <h4 className="text-2xl font-black text-gray-900 leading-none mt-1">
                  {formatCurrency(totalBudgetSpent)}
                </h4>
              </div>
              <span className="text-xs font-semibold text-sunset-primary bg-sunset-primary/10 px-2.5 py-1 rounded-xl">
                 of {formatCurrency(totalBudgetLimit)}
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div 
                className="bg-sunset-primary h-2 rounded-full transition-all duration-500" 
                style={{ width: `${overallBudgetPercentage}%` }}
              ></div>
            </div>
          </div>

          {/* 循环渲染每一个具体预算信息 (提供高度易读的细节支持) */}
          <div className="space-y-4">
            {data.budgets.length > 0 ? (
              data.budgets.map((budget) => {
                const isOverspent = budget.spent_amount > budget.budget_amount;
                const remaining = budget.budget_amount - budget.spent_amount;
                const barColor = budget.percentage >= 80 ? 'bg-[#ef4444]' : 'bg-[#0d9488]';
                
                return (
                  <div key={budget.id} className="p-3.5 bg-gray-50/70 rounded-xl border border-gray-100 space-y-2.5">
                    {/* 第一排：分类、月份、超支百分比 */}
                    <div className="flex justify-between items-center">
                      <div className="flex items-center gap-2 min-w-0">
                        <div 
                          className="w-2.5 h-2.5 rounded-full shrink-0" 
                          style={{ backgroundColor: budget.category_color }} 
                        />
                        <span className="font-bold text-gray-850 text-sm truncate">{budget.category}</span>
                        {/* 增加月份和年份标签 */}
                        <span className="text-[10px] font-bold px-1.5 py-0.5 bg-gray-200/50 text-gray-500 rounded-md shrink-0">
                          {getMonthName(budget.month)} {budget.year}
                        </span>
                      </div>
                      <span className={`text-xs font-black shrink-0 ${budget.percentage >= 80 ? 'text-red-500' : 'text-[#0d9488]'}`}>
                        {budget.percentage}% used
                      </span>
                    </div>

                    {/* 第二排：进度条 */}
                    <div className="w-full bg-gray-200/80 rounded-full h-2">
                      <div 
                        className={`${barColor} h-2 rounded-full transition-all duration-500`} 
                        style={{ width: `${Math.min(100, budget.percentage)}%` }}
                      ></div>
                    </div>

                    {/* 第三排：花费与上限明细 */}
                    <div className="flex justify-between items-center text-xs text-gray-500">
                      <span>Spent: <strong className="text-gray-800 font-bold">{formatCurrency(budget.spent_amount)}</strong></span>
                      <span>Limit: <strong className="text-gray-800 font-bold">{formatCurrency(budget.budget_amount)}</strong></span>
                    </div>

                    {/* 第四排：自动预算结余（Remaining / Overspent） */}
                    <div className="text-[11px] pt-1 border-t border-dashed border-gray-200 flex justify-end">
                      {isOverspent ? (
                        <span>
                          Overspent: <strong className="text-red-500 font-bold">{formatCurrency(Math.abs(remaining))}</strong>
                        </span>
                      ) : (
                        <span>
                          Remaining: <strong className="text-[#0d9488] font-bold">{formatCurrency(remaining)}</strong>
                        </span>
                      )}
                    </div>
                  </div>
                );
              })
            ) : (
              <p className="text-sm text-gray-400 text-center py-6">No active budgets for this month.</p>
            )}
          </div>
        </Card>

      </div>
    </div>
  );
}