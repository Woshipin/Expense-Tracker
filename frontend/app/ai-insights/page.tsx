"use client";

import { Card, Input, Toast } from "@/components/ui";
import { Sparkles, Send, Bot, User, Loader2, ArrowRight, TrendingUp, TrendingDown, Wallet, PiggyBank } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";
import { useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import Markdown from "react-markdown";
import api from "@/lib/axios";

interface MetricStats {
  totalIncome: number;
  totalExpense: number;
  netBalance: number;
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
  category_color?: string;
  budget_amount: number;
  spent_amount: number;
  percentage: number;
  month: number;
  year: number;
}

export default function AIInsightsPage() {
  const router = useRouter();
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'warning' } | null>(null);

  const getLocalDateString = (date: Date) => {
    const offset = date.getTimezoneOffset();
    const localDate = new Date(date.getTime() - (offset * 60 * 1000));
    return localDate.toISOString().split('T')[0];
  };

  const todayStr = getLocalDateString(new Date());
  const firstDayStr = getLocalDateString(new Date(new Date().getFullYear(), new Date().getMonth(), 1));

  const [startDate, setStartDate] = useState(firstDayStr);
  const [endDate, setEndDate] = useState(todayStr);

  const [metrics, setMetrics] = useState<MetricStats>({ totalIncome: 0, totalExpense: 0, netBalance: 0, savingsRate: 0 });
  const [chartData, setChartData] = useState<ChartItem[]>([]);
  const [categoryData, setCategoryData] = useState<PieItem[]>([]);
  const [recentExpenses, setRecentExpenses] = useState<TransactionItem[]>([]);
  const [recentIncomes, setRecentIncomes] = useState<TransactionItem[]>([]);
  const [budgets, setBudgets] = useState<BudgetItem[]>([]);
  const [isLoadingData, setIsLoadingData] = useState(true);

  const [messages, setMessages] = useState<{ role: 'user' | 'model', text: string }[]>([
    { role: 'model', text: 'Hello! I am your **Sunset AI Insights Coach**. Ask me anything about your filtered transaction metrics, and I will analyze them dynamically!' }
  ]);
  const [input, setInput] = useState("");
  const [isSendingMsg, setIsSendingMsg] = useState(false);
  const chatEndRef = useRef<HTMLDivElement>(null);

  // ✅ 新增：normalizeMarkdown — 把单换行转双换行，让 react-markdown 正确渲染段落空行
  const normalizeMarkdown = (text: string) => {
    return text.replace(/([^\n])\n([^\n])/g, '$1\n\n$2');
  };

  const loadInsightsData = async () => {
    try {
      setIsLoadingData(true);
      const response = await api.get(`/ai-insights?start_date=${startDate}&end_date=${endDate}`);
      setMetrics({
        totalIncome: response.data.metrics.income,
        totalExpense: response.data.metrics.expense,
        netBalance: response.data.metrics.balance,
        savingsRate: response.data.metrics.savingsRate
      });
      setChartData(response.data.chartData);
      setCategoryData(response.data.categoryData || []);
      setRecentExpenses(response.data.recentExpenses || []);
      setRecentIncomes(response.data.recentIncomes || []);
      setBudgets(response.data.budgets || []);
    } catch (error) {
      console.error("Failed to load insights analytics:", error);
      setToast({ message: "Unable to load financial insights.", type: "error" });
    } finally {
      setIsLoadingData(false);
    }
  };

  useEffect(() => {
    loadInsightsData();
  }, [startDate, endDate]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const formatCurrency = (val: number) => {
    const isNegative = val < 0;
    const formattedNum = Math.abs(val).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    return isNegative ? `-RM ${formattedNum}` : `RM ${formattedNum}`;
  };

  const getMonthName = (monthNum: number) => {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[monthNum - 1] || "Month";
  };

  const buildFinancialContext = () => {
    const expensesSummary = recentExpenses.length > 0
      ? recentExpenses.map(e => `- ${e.title} (${e.category}, ${e.date}): -RM ${e.price.toFixed(2)}`).join('\n')
      : '- No recent expenses.';

    const incomesSummary = recentIncomes.length > 0
      ? recentIncomes.map(i => `- ${i.title} (${i.category}, ${i.date}): +RM ${i.price.toFixed(2)}`).join('\n')
      : '- No recent incomes.';

    const budgetsSummary = budgets.length > 0
      ? budgets.map(b => {
          const remaining = b.budget_amount - b.spent_amount;
          const status = b.spent_amount > b.budget_amount
            ? `OVERSPENT by RM ${Math.abs(remaining).toFixed(2)}`
            : `RM ${remaining.toFixed(2)} remaining`;
          return `- ${b.category} (${getMonthName(b.month)} ${b.year}): Budget RM ${b.budget_amount.toFixed(2)}, Spent RM ${b.spent_amount.toFixed(2)}, ${b.percentage}% used — ${status}`;
        }).join('\n')
      : '- No active budgets.';

    const categorySummary = categoryData.length > 0
      ? categoryData.map(c => `- ${c.name}: RM ${c.value.toFixed(2)}`).join('\n')
      : '- No category data.';

    return `
You are Sunset AI Insights Coach, a personal finance advisor. You MUST base your analysis and advice primarily on the user's ACTUAL financial data provided below. Always reference specific numbers, categories, and budget statuses from their data before giving general advice. Format your response with clear sections using markdown headings (##) and bullet points for readability.

=== USER'S FINANCIAL DATA (${startDate} to ${endDate}) ===

**Summary Metrics:**
- Total Income: RM ${metrics.totalIncome.toFixed(2)}
- Total Expenses: RM ${metrics.totalExpense.toFixed(2)}
- Net Balance: RM ${metrics.netBalance.toFixed(2)}
- Savings Rate: ${metrics.savingsRate}%

**Recent Expenses:**
${expensesSummary}

**Recent Incomes:**
${incomesSummary}

**Budget Status:**
${budgetsSummary}

**Spending by Category:**
${categorySummary}

=== END OF USER DATA ===

Instructions:
1. ALWAYS start by referencing the user's actual data above.
2. Use specific RM amounts and category names from their data.
3. Only after addressing their real data, offer general financial tips.
4. Use ## headings and bullet points to make the response easy to read.
5. Keep the tone friendly, concise, and actionable.
    `.trim();
  };

  const handleSendMessage = async () => {
    if (!input.trim() || isSendingMsg) return;

    const userText = input.trim();
    const newMessages = [...messages, { role: 'user' as const, text: userText }];
    setMessages(newMessages);
    setInput("");
    setIsSendingMsg(true);

    try {
      const response = await api.post("/ai-insights/chat", {
        messages: newMessages,
        start_date: startDate,
        end_date: endDate,
        financial_context: buildFinancialContext(),
      });

      const aiResponseText = response.data.reply || "No response generated.";
      setMessages(prev => [...prev, { role: 'model', text: aiResponseText }]);

    } catch (error: any) {
      console.error("Direct Backend AI Connect Error:", error);
      const backendError = error.response?.data?.message || error.message;
      setMessages(prev => [...prev, {
        role: 'model',
        text: `⚠️ **无法连接到 AI 服务器。**\n\n*错误详情: ${backendError}*\n\n请检查后端 \`.env\` 中的 \`GROQ_API_KEY\` 配置是否正确。`
      }]);
    } finally {
      setIsSendingMsg(false);
    }
  };

  const overallSpendingLimit = budgets.reduce((acc, curr) => acc + curr.budget_amount, 0);
  const overallSpendingSpent = budgets.reduce((acc, curr) => acc + curr.spent_amount, 0);
  const overallSpendingPercentage = overallSpendingLimit > 0 ? Math.min(100, (overallSpendingSpent / overallSpendingLimit) * 100) : 0;

  return (
    <div className="space-y-6 animate-in fade-in zoom-in-95 duration-300 pb-16">
      {toast && <Toast message={toast.type === 'success' ? toast.message : ''} type={toast.type} onClose={() => setToast(null)} />}

      <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-sunset-dark">AI Insights</h1>
          <p className="text-sm font-medium text-sunset-dark/60 mt-1">Deep dive into your financial health with Sunset AI.</p>
        </div>
        <div className="flex items-center gap-2 self-start md:self-auto">
          <div className="flex items-center bg-white border border-sunset-primary/10 rounded-2xl p-1.5 shadow-sm overflow-x-auto">
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="bg-transparent text-xs font-bold text-sunset-dark outline-none px-2 py-1 cursor-pointer"
            />
            <span className="text-sunset-dark/40 font-bold px-1">-</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="bg-transparent text-xs font-bold text-sunset-dark outline-none px-2 py-1 cursor-pointer"
            />
          </div>
        </div>
      </header>

      {isLoadingData ? (
        <div className="h-[50vh] w-full flex flex-col items-center justify-center">
          <Loader2 className="w-12 h-12 text-sunset-primary animate-spin mb-4" />
          <p className="text-sunset-dark/60 font-semibold text-sm">Analyzing financial databases...</p>
        </div>
      ) : (
        <>
          {/* 1. 四大核心指标卡片 */}
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
            <Card className="p-5 border border-purple-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
              <div className="w-12 h-12 rounded-2xl bg-[#7c3aed] text-white flex items-center justify-center shrink-0 shadow-md shadow-purple-500/20">
                <Wallet size={22} strokeWidth={2.5} />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Balance</p>
                <h3 className="text-xl font-black text-gray-900 mt-0.5">{formatCurrency(metrics.netBalance)}</h3>
              </div>
            </Card>

            <Card className="p-5 border border-teal-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
              <div className="w-12 h-12 rounded-2xl bg-[#0d9488] text-white flex items-center justify-center shrink-0 shadow-md shadow-teal-500/20">
                <TrendingUp size={22} strokeWidth={2.5} />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Income</p>
                <h3 className="text-xl font-black text-gray-900 mt-0.5">{formatCurrency(metrics.totalIncome)}</h3>
              </div>
            </Card>

            <Card className="p-5 border border-red-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
              <div className="w-12 h-12 rounded-2xl bg-[#ef4444] text-white flex items-center justify-center shrink-0 shadow-md shadow-red-500/20">
                <TrendingDown size={22} strokeWidth={2.5} />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Expenses</p>
                <h3 className="text-xl font-black text-gray-900 mt-0.5">{formatCurrency(metrics.totalExpense)}</h3>
              </div>
            </Card>

            <Card className="p-5 border border-blue-100 shadow-sm flex items-center gap-4 bg-white rounded-2xl">
              <div className="w-12 h-12 rounded-2xl bg-[#2563eb] text-white flex items-center justify-center shrink-0 shadow-md shadow-blue-500/20">
                <PiggyBank size={22} strokeWidth={2.5} />
              </div>
              <div>
                <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Savings Rate</p>
                <h3 className="text-xl font-black text-gray-900 mt-0.5">{metrics.savingsRate}%</h3>
              </div>
            </Card>
          </div>

          {/* 2. 可视化面板 */}
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <Card className="xl:col-span-2 shadow-sm border border-sunset-primary/10 flex flex-col rounded-2xl p-6 bg-white min-w-0">
              <h3 className="font-bold text-sunset-dark mb-6">Cashflow Overview</h3>
              <div className="flex-1 w-full relative min-h-[250px]">
                {chartData.length > 0 ? (
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <defs>
                        <linearGradient id="colorExpense" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#ef4444" stopOpacity={0.25} />
                          <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
                        </linearGradient>
                        <linearGradient id="colorIncome" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#0d9488" stopOpacity={0.25} />
                          <stop offset="95%" stopColor="#0d9488" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#2D1B14', opacity: 0.5 }} dy={10} />
                      <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#2D1B14', opacity: 0.5 }} dx={-10} />
                      <Tooltip
                        contentStyle={{ borderRadius: '16px', border: '1px solid rgba(255,123,66,0.1)', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}
                        itemStyle={{ color: '#2D1B14', fontWeight: 600 }}
                        labelStyle={{ color: '#2D1B14', opacity: 0.5, fontWeight: 700 }}
                      />
                      <Area type="monotone" dataKey="income" stroke="#0d9488" strokeWidth={3} fillOpacity={1} fill="url(#colorIncome)" name="Income (RM)" />
                      <Area type="monotone" dataKey="expense" stroke="#ef4444" strokeWidth={3} fillOpacity={1} fill="url(#colorExpense)" name="Expense (RM)" />
                    </AreaChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="absolute inset-0 flex items-center justify-center text-gray-400 text-xs">
                    No transactions recorded for this period.
                  </div>
                )}
              </div>
            </Card>

            <Card className="shadow-sm border border-sunset-primary/10 flex flex-col rounded-2xl p-6 bg-white min-w-0">
              <h3 className="font-bold text-sunset-dark mb-4">Category Spending</h3>
              <div className="flex-1 flex flex-col justify-center">
                {categoryData.length > 0 ? (
                  <>
                    <div className="h-[180px] w-full relative mb-4">
                      <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                          <Pie data={categoryData} cx="50%" cy="50%" innerRadius={50} outerRadius={75} paddingAngle={2} dataKey="value" stroke="none">
                            {categoryData.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={entry.color} />
                            ))}
                          </Pie>
                          <Tooltip formatter={(v: any) => `RM ${v}`} wrapperClassName="rounded-xl overflow-hidden shadow-xl border-none" contentStyle={{ border: 'none' }} />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>
                    <div className="space-y-3.5">
                      {categoryData.slice(0, 3).map(c => (
                        <div key={c.name}>
                          <div className="flex justify-between text-xs mb-1">
                            <span className="font-bold text-sunset-dark/70 flex items-center gap-2">
                              <div className="w-2 h-2 rounded-full" style={{ background: c.color }}></div>{c.name}
                            </span>
                            <span className="font-black text-sunset-dark">RM {c.value.toFixed(2)}</span>
                          </div>
                          <div className="w-full h-1.5 bg-black/5 rounded-full overflow-hidden">
                            <div
                              className="h-full rounded-full transition-all duration-500"
                              style={{ width: `${overallSpendingLimit > 0 ? (c.value / overallSpendingLimit) * 100 : 0}%`, backgroundColor: c.color }}
                            ></div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </>
                ) : (
                  <div className="flex-1 flex items-center justify-center text-gray-400 text-xs py-10">
                    No categories expenditure records.
                  </div>
                )}
              </div>
            </Card>
          </div>

          {/* 3. Recent Transactions + Budget */}
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
            <Card className="p-6 bg-white rounded-2xl shadow-sm border border-sunset-primary/10">
              <div className="flex justify-between items-center mb-6">
                <h3 className="font-bold text-sunset-dark">Recent Expenses</h3>
                <button onClick={() => router.push('/expenses')} className="text-sm text-[#ef4444] font-bold hover:underline flex items-center">
                  View all <ArrowRight size={14} className="ml-1" />
                </button>
              </div>
              <div className="space-y-4">
                {recentExpenses && recentExpenses.length > 0 ? (
                  recentExpenses.map((expense) => (
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
                      <div className="font-bold text-sm text-[#ef4444] shrink-0 ml-2">-RM {expense.price.toFixed(2)}</div>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-gray-400 text-center py-10">No recent expenses found.</p>
                )}
              </div>
            </Card>

            <Card className="p-6 bg-white rounded-2xl shadow-sm border border-sunset-primary/10">
              <div className="flex justify-between items-center mb-6">
                <h3 className="font-bold text-sunset-dark">Recent Incomes</h3>
                <button onClick={() => router.push('/income')} className="text-sm text-[#0d9488] font-bold hover:underline flex items-center">
                  View all <ArrowRight size={14} className="ml-1" />
                </button>
              </div>
              <div className="space-y-4">
                {recentIncomes && recentIncomes.length > 0 ? (
                  recentIncomes.map((income) => (
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
                      <div className="font-bold text-sm text-[#0d9488] shrink-0 ml-2">+RM {income.price.toFixed(2)}</div>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-gray-400 text-center py-10">No recent incomes found.</p>
                )}
              </div>
            </Card>

            <Card className="p-6 bg-white rounded-2xl shadow-sm border border-sunset-primary/10 md:col-span-2 xl:col-span-1">
              <div className="flex justify-between items-center mb-6">
                <h3 className="font-bold text-sunset-dark">Budget Status</h3>
                <button onClick={() => router.push('/budget')} className="text-sm text-sunset-primary font-bold hover:underline flex items-center">
                  View all <ArrowRight size={14} className="ml-1" />
                </button>
              </div>
              <div className="mb-6 bg-sunset-primary/5 p-4 rounded-2xl border border-sunset-primary/10">
                <div className="flex justify-between items-end mb-2">
                  <div>
                    <p className="text-[10px] text-gray-400 uppercase font-black tracking-wider">Total Spent</p>
                    <h4 className="text-2xl font-black text-gray-900 leading-none mt-1">{formatCurrency(overallSpendingSpent)}</h4>
                  </div>
                  <span className="text-xs font-semibold text-sunset-primary bg-sunset-primary/10 px-2.5 py-1 rounded-xl">
                    of {formatCurrency(overallSpendingLimit)}
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div className="bg-sunset-primary h-2 rounded-full transition-all duration-500" style={{ width: `${overallSpendingPercentage}%` }}></div>
                </div>
              </div>
              <div className="space-y-4">
                {budgets.length > 0 ? (
                  budgets.map((budget) => {
                    const isOverspent = budget.spent_amount > budget.budget_amount;
                    const remaining = budget.budget_amount - budget.spent_amount;
                    const barColor = budget.percentage >= 80 ? 'bg-[#ef4444]' : 'bg-[#0d9488]';
                    return (
                      <div key={budget.id} className="p-3.5 bg-gray-50/70 rounded-xl border border-gray-100 space-y-2.5">
                        <div className="flex justify-between items-center">
                          <div className="flex items-center gap-2 min-w-0">
                            <div className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: budget.category_color }} />
                            <span className="font-bold text-gray-850 text-sm truncate">{budget.category}</span>
                            <span className="text-[10px] font-bold px-1.5 py-0.5 bg-gray-200/50 text-gray-500 rounded-md shrink-0">
                              {getMonthName(budget.month)} {budget.year}
                            </span>
                          </div>
                          <span className={`text-xs font-black shrink-0 ${budget.percentage >= 80 ? 'text-red-500' : 'text-[#0d9488]'}`}>
                            {budget.percentage}% used
                          </span>
                        </div>
                        <div className="w-full bg-gray-200/80 rounded-full h-2">
                          <div className={`${barColor} h-2 rounded-full transition-all duration-500`} style={{ width: `${Math.min(100, budget.percentage)}%` }}></div>
                        </div>
                        <div className="flex justify-between items-center text-xs text-gray-500">
                          <span>Spent: <strong className="text-gray-800 font-bold">{formatCurrency(budget.spent_amount)}</strong></span>
                          <span>Limit: <strong className="text-gray-800 font-bold">{formatCurrency(budget.budget_amount)}</strong></span>
                        </div>
                        <div className="text-[11px] pt-1 border-t border-dashed border-gray-200 flex justify-end">
                          {isOverspent ? (
                            <span>Overspent: <strong className="text-red-500 font-bold">{formatCurrency(Math.abs(remaining))}</strong></span>
                          ) : (
                            <span>Remaining: <strong className="text-[#0d9488] font-bold">{formatCurrency(remaining)}</strong></span>
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

          {/* 4. AI Insights 聊天面板 */}
          <div className="mt-4">
            <h3 className="font-black text-sunset-dark flex items-center gap-2 mb-4">
              <Sparkles className="text-sunset-primary animate-pulse" size={20} /> AI Insights Advisor
            </h3>

            <Card className="p-0 overflow-hidden shadow-sm border border-sunset-primary/10 flex flex-col bg-white rounded-3xl" style={{ height: '800px' }}>
              {/* Header */}
              <div className="py-4 bg-sunset-bg relative flex flex-col items-center justify-center border-b border-sunset-primary/10 shrink-0">
                <div className="absolute inset-0 overflow-hidden pointer-events-none opacity-35">
                  <div className="absolute -top-16 -left-16 w-32 h-32 bg-sunset-primary blur-[50px] rounded-full mix-blend-multiply animate-pulse"></div>
                  <div className="absolute top-1/2 right-1/4 w-48 h-48 bg-orange-400 blur-[80px] rounded-full mix-blend-multiply opacity-50"></div>
                </div>
                <div className="text-center relative z-10 w-full flex flex-col items-center">
                  <div className="w-10 h-10 bg-gradient-to-tr from-sunset-primary to-orange-400 rounded-xl animate-[spin_12s_linear_infinite] shadow-[0_0_20px_rgba(255,123,66,0.35)] mb-2" style={{ borderRadius: '40% 60% 70% 30% / 40% 50% 60% 50%' }}></div>
                  <p className="font-black text-sm text-sunset-dark mb-0.5">Sunset AI Engine Synced</p>
                  <p className="text-[10px] font-bold text-sunset-dark/50 uppercase tracking-widest">
                    Realtime scope: {startDate} ~ {endDate}
                  </p>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 min-h-0 overflow-y-auto p-4 md:p-6 space-y-6 bg-[#fffcfb]">
                {messages.map((msg, index) => (
                  <div key={index} className={`flex gap-3.5 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}>
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 shadow-sm ${msg.role === 'user' ? 'bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white' : 'bg-sunset-primary/10 text-sunset-primary border border-sunset-primary/10'}`}>
                      {msg.role === 'user' ? <User size={15} /> : <Bot size={15} />}
                    </div>
                    <div className={`p-4 rounded-2xl max-w-[85%] sm:max-w-[75%] shadow-sm ${msg.role === 'user' ? 'bg-gradient-to-br from-sunset-primary to-sunset-secondary text-white rounded-tr-sm' : 'bg-white border border-orange-200/50 text-sunset-dark rounded-tl-sm'}`}>
                      {msg.role === 'user' ? (
                        <p className="text-sm font-semibold">{msg.text}</p>
                      ) : (
                        // ✅ 修改：使用 normalizeMarkdown 处理文本，解决单换行不渲染段落空行的问题
                        // ✅ 修改：prose 样式 — 深黑文字、橙色 bold、段落间距
                        <div className="text-sm font-medium leading-relaxed prose prose-sm max-w-none text-gray-900 prose-headings:text-gray-900 prose-headings:font-black prose-headings:mt-5 prose-headings:mb-3 prose-p:text-gray-900 prose-p:mb-4 prose-p:mt-0 prose-strong:text-sunset-primary prose-strong:font-bold prose-li:text-gray-900 prose-li:my-1 prose-ul:my-3 prose-ol:my-3">
                          <Markdown>{normalizeMarkdown(msg.text)}</Markdown>
                        </div>
                      )}
                    </div>
                  </div>
                ))}

                {isSendingMsg && (
                  <div className="flex gap-3.5">
                    <div className="w-8 h-8 rounded-full bg-sunset-primary/10 text-sunset-primary flex items-center justify-center shrink-0 border border-sunset-primary/10">
                      <Bot size={15} />
                    </div>
                    <div className="p-4 rounded-2xl bg-white border border-orange-200/50 rounded-tl-sm flex items-center gap-1.5 h-[50px] shadow-sm">
                      <span className="w-1.5 h-1.5 rounded-full bg-sunset-primary animate-bounce"></span>
                      <span className="w-1.5 h-1.5 rounded-full bg-sunset-primary animate-bounce delay-100"></span>
                      <span className="w-1.5 h-1.5 rounded-full bg-sunset-primary animate-bounce delay-200"></span>
                    </div>
                  </div>
                )}
                <div ref={chatEndRef} />
              </div>

              {/* Input */}
              <div className="p-4 border-t border-sunset-primary/10 bg-white shrink-0">
                <form onSubmit={(e) => { e.preventDefault(); handleSendMessage(); }} className="relative flex items-center">
                  <Input
                    placeholder="Ask AI Advisor about your monthly expenses or saving strategy..."
                    className="w-full p-3 pl-4 pr-12 h-12 bg-[#fffcfb] border-sunset-primary/20 rounded-2xl focus:ring-2 focus:ring-sunset-primary/30 text-sm font-semibold"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    disabled={isSendingMsg}
                  />
                  <button
                    type="submit"
                    disabled={isSendingMsg || !input.trim()}
                    className="absolute right-1.5 h-9 w-9 p-0 flex items-center justify-center rounded-xl bg-sunset-primary text-white hover:bg-sunset-dark transition-colors border-none shadow-none disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Send size={15} />
                  </button>
                </form>
              </div>
            </Card>
          </div>
        </>
      )}
    </div>
  );
}