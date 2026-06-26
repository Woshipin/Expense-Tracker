<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Income;
use App\Models\Budget;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;

class AiInsightsController extends Controller
{
    /**
     * 获取指定日期范围内的 AI Insights 核心财务数据与过滤列表
     */
    public function getInsights(Request $request)
    {
        $userId = Auth::id();
        if (!$userId) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $startDate = $request->query('start_date', Carbon::now()->startOfMonth()->toDateString());
        $endDate = $request->query('end_date', Carbon::now()->endOfMonth()->toDateString());

        // 1. 指定日期范围内的收支统计
        $totalIncome = Income::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('price');

        $totalExpense = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('price');

        $netBalance = $totalIncome - $totalExpense;
        $savingsRate = $totalIncome > 0 ? (($totalIncome - $totalExpense) / $totalIncome) * 100 : 0;

        // 2. 收支走势图数据
        $chartData = [];
        $start = Carbon::parse($startDate);
        $end = Carbon::parse($endDate);
        $diffInDays = $start->diffInDays($end);
        $step = $diffInDays > 15 ? 'week' : 'day';

        if ($step === 'day') {
            for ($date = $start->copy(); $date->lte($end); $date->addDay()) {
                $dateStr = $date->toDateString();
                $dayIncome = Income::where('user_id', $userId)->whereDate('date', $dateStr)->sum('price');
                $dayExpense = Expense::where('user_id', $userId)->whereDate('date', $dateStr)->sum('price');
                $chartData[] = [
                    'name'    => $date->format('M d'),
                    'income'  => (float) $dayIncome,
                    'expense' => (float) $dayExpense,
                ];
            }
        } else {
            for ($date = $start->copy(); $date->lte($end); $date->addWeek()) {
                $weekEnd = $date->copy()->endOfWeek()->min($end);
                $weekIncome = Income::where('user_id', $userId)
                    ->whereBetween('date', [$date->toDateString(), $weekEnd->toDateString()])
                    ->sum('price');
                $weekExpense = Expense::where('user_id', $userId)
                    ->whereBetween('date', [$date->toDateString(), $weekEnd->toDateString()])
                    ->sum('price');
                $chartData[] = [
                    'name'    => 'W' . $date->weekOfMonth . ' (' . $date->format('M d') . ')',
                    'income'  => (float) $weekIncome,
                    'expense' => (float) $weekExpense,
                ];
            }
        }

        // 3. 消费最高的分类开支占比
        $categorySpending = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->selectRaw('category_id, SUM(price) as total_spent')
            ->groupBy('category_id')
            ->orderByDesc('total_spent')
            ->get()
            ->map(function ($item) {
                return [
                    'name'  => $item->category->name ?? 'Uncategorized',
                    'value' => (float) $item->total_spent,
                    'color' => $item->category->color ?? '#FF7B42',
                ];
            });

        // 4. 最近支出记录
        $recentExpenses = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->orderByDesc('date')
            ->orderByDesc('time')
            ->take(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id'       => $item->id,
                    'title'    => $item->title,
                    'category' => $item->category->name ?? 'Uncategorized',
                    'date'     => Carbon::parse($item->date)->format('M d, Y'),
                    'price'    => (float) $item->price,
                    'type'     => 'expense',
                ];
            });

        // 5. 最近收入记录
        $recentIncomes = Income::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->orderByDesc('date')
            ->orderByDesc('time')
            ->take(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id'       => $item->id,
                    'title'    => $item->title,
                    'category' => $item->category->name ?? 'Uncategorized',
                    'date'     => Carbon::parse($item->date)->format('M d, Y'),
                    'price'    => (float) $item->price,
                    'type'     => 'income',
                ];
            });

        // 6. 获取预算状态
        $currentMonth = $start->month;
        $currentYear  = $start->year;
        $budgets = Budget::where('user_id', $userId)
            ->where('month', $currentMonth)
            ->where('year', $currentYear)
            ->with('category')
            ->get()
            ->map(function ($budget) use ($userId, $startDate, $endDate) {
                $spent = Expense::where('user_id', $userId)
                    ->where('category_id', $budget->category_id)
                    ->whereBetween('date', [$startDate, $endDate])
                    ->sum('price');

                $percentage = $budget->amount > 0 ? ($spent / $budget->amount) * 100 : 0;

                return [
                    'id'             => $budget->id,
                    'category'       => $budget->category->name ?? 'Category',
                    'category_color' => $budget->category->color ?? '#94a3b8',
                    'budget_amount'  => (float) $budget->amount,
                    'spent_amount'   => (float) $spent,
                    'percentage'     => round($percentage, 1),
                    'month'          => (int) $budget->month,
                    'year'           => (int) $budget->year,
                ];
            });

        return response()->json([
            'metrics' => [
                'balance'     => (float) $netBalance,
                'income'      => (float) $totalIncome,
                'expense'     => (float) $totalExpense,
                'savingsRate' => round($savingsRate, 1),
            ],
            'chartData'      => $chartData,
            'categoryData'   => $categorySpending,
            'recentExpenses' => $recentExpenses,
            'recentIncomes'  => $recentIncomes,
            'budgets'        => $budgets,
        ]);
    }

    /**
     * 后端安全调用 Groq API 进行 AI 问答
     */
    public function chat(Request $request)
    {
        $userId = Auth::id();
        if (!$userId) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $request->validate([
            'messages'   => 'required|array',
            'start_date' => 'required|date',
            'end_date'   => 'required|date',
        ]);

        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');
        $messages  = $request->input('messages');

        // =====================================================================
        // 1. 从数据库查询用户真实财务数据（后端自行查询，不依赖前端传入）
        // =====================================================================
        $totalIncome = Income::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('price');

        $totalExpense = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('price');

        $netBalance  = $totalIncome - $totalExpense;
        $savingsRate = $totalIncome > 0
            ? round((($totalIncome - $totalExpense) / $totalIncome) * 100, 1)
            : 0;

        // 分类消费明细
        $categorySpending = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->selectRaw('category_id, SUM(price) as total_spent')
            ->groupBy('category_id')
            ->orderByDesc('total_spent')
            ->get()
            ->map(fn($item) => [
                'category' => $item->category->name ?? 'Uncategorized',
                'spent'    => 'RM ' . number_format((float) $item->total_spent, 2),
            ]);

        // 最近 5 笔支出
        $recentExpenses = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->orderByDesc('date')
            ->orderByDesc('time')
            ->take(5)
            ->get()
            ->map(fn($item) => [
                'title'    => $item->title,
                'category' => $item->category->name ?? 'Uncategorized',
                'date'     => Carbon::parse($item->date)->format('M d, Y'),
                'amount'   => 'RM ' . number_format((float) $item->price, 2),
            ]);

        // 最近 5 笔收入
        $recentIncomes = Income::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->orderByDesc('date')
            ->orderByDesc('time')
            ->take(5)
            ->get()
            ->map(fn($item) => [
                'title'    => $item->title,
                'category' => $item->category->name ?? 'Uncategorized',
                'date'     => Carbon::parse($item->date)->format('M d, Y'),
                'amount'   => 'RM ' . number_format((float) $item->price, 2),
            ]);

        // 预算配置与使用状况
        $start        = Carbon::parse($startDate);
        $currentMonth = $start->month;
        $currentYear  = $start->year;

        $budgets = Budget::where('user_id', $userId)
            ->where('month', $currentMonth)
            ->where('year', $currentYear)
            ->with('category')
            ->get()
            ->map(function ($budget) use ($userId, $startDate, $endDate) {
                $spent = Expense::where('user_id', $userId)
                    ->where('category_id', $budget->category_id)
                    ->whereBetween('date', [$startDate, $endDate])
                    ->sum('price');

                $percentage = $budget->amount > 0
                    ? round(($spent / $budget->amount) * 100, 1)
                    : 0;

                $remaining = $budget->amount - $spent;
                $status    = $spent > $budget->amount
                    ? 'OVERSPENT by RM ' . number_format(abs($remaining), 2)
                    : 'RM ' . number_format($remaining, 2) . ' remaining';

                return [
                    'category'     => $budget->category->name ?? 'Category',
                    'budget_limit' => 'RM ' . number_format((float) $budget->amount, 2),
                    'spent'        => 'RM ' . number_format((float) $spent, 2),
                    'percentage'   => $percentage . '% used',
                    'status'       => $status,
                ];
            });

        // =====================================================================
        // 2. 构建 System Prompt
        // ✅ 修改：改用字符串拼接替代 heredoc，避免缩进导致数据注入失败
        // ✅ 修改：将真实财务数据直接嵌入 system prompt 正文
        // =====================================================================
        $categoryLines = $categorySpending->map(fn($c) => "- {$c['category']}: {$c['spent']}")->implode("\n");
        $expenseLines  = $recentExpenses->map(fn($e) => "- [{$e['date']}] {$e['title']} ({$e['category']}): {$e['amount']}")->implode("\n");
        $incomeLines   = $recentIncomes->map(fn($i) => "- [{$i['date']}] {$i['title']} ({$i['category']}): {$i['amount']}")->implode("\n");
        $budgetLines   = $budgets->map(fn($b) => "- {$b['category']}: Limit {$b['budget_limit']}, Spent {$b['spent']} ({$b['percentage']}) — {$b['status']}")->implode("\n");

        $systemPrompt  = "You are \"Sunset AI Insights Coach\", a friendly and professional personal finance advisor embedded inside a personal finance app.\n\n";
        $systemPrompt .= "YOUR PRIMARY RULE: You MUST base every response FIRST on the user's ACTUAL financial data listed below. NEVER say you don't have data — the data is already provided here.\n\n";
        $systemPrompt .= "FORMATTING RULES:\n";
        $systemPrompt .= "- Use ## for main section headings.\n";
        $systemPrompt .= "- Use **bold** for important numbers, category names, and key terms.\n";
        $systemPrompt .= "- Use bullet points (- ) for lists.\n";
        $systemPrompt .= "- Always add a blank line between every paragraph and section.\n";
        $systemPrompt .= "- Each paragraph should be 2-3 sentences max.\n\n";
        $systemPrompt .= "LANGUAGE RULE: Always reply in the EXACT SAME LANGUAGE as the user's latest message.\n\n";
        $systemPrompt .= "=== USER'S ACTUAL FINANCIAL DATA ({$startDate} to {$endDate}) ===\n\n";
        $systemPrompt .= "**Overview:**\n";
        $systemPrompt .= "- Total Income: RM " . number_format($totalIncome, 2) . "\n";
        $systemPrompt .= "- Total Expenses: RM " . number_format($totalExpense, 2) . "\n";
        $systemPrompt .= "- Net Balance: RM " . number_format($netBalance, 2) . "\n";
        $systemPrompt .= "- Savings Rate: {$savingsRate}%\n\n";
        $systemPrompt .= "**Spending by Category:**\n{$categoryLines}\n\n";
        $systemPrompt .= "**Recent Expenses (latest 5):**\n{$expenseLines}\n\n";
        $systemPrompt .= "**Recent Incomes (latest 5):**\n{$incomeLines}\n\n";
        $systemPrompt .= "**Budget Status:**\n{$budgetLines}\n\n";
        $systemPrompt .= "=== END OF USER DATA ===\n\n";
        $systemPrompt .= "For hypothetical questions (e.g. 'how to allocate RM X'), first map into the user's EXISTING categories above, then add general tips.";

        // =====================================================================
        // 3. 将前端对话历史转换成 Groq messages 格式（正确的 role 映射）
        //    前端用 'user' | 'model'，Groq 用 'user' | 'assistant'
        // =====================================================================
        $groqMessages = [];

        foreach ($messages as $msg) {
            $role = $msg['role'] === 'model' ? 'assistant' : 'user';

            // 跳过 AI 的初始欢迎语（避免污染 context）
            if ($role === 'assistant' && str_contains($msg['text'], 'Sunset AI Insights Coach')) {
                continue;
            }

            $groqMessages[] = [
                'role'    => $role,
                'content' => $msg['text'],
            ];
        }

        // =====================================================================
        // 4. 调用 Groq API
        // =====================================================================
        $apiKey = config('services.groq.api_key');

        if (!$apiKey) {
            return response()->json(['message' => 'AI service configuration is missing.'], 500);
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type'  => 'application/json',
            ])->post('https://api.groq.com/openai/v1/chat/completions', [
                'model'       => 'llama-3.3-70b-versatile',
                'messages'    => array_merge(
                    [['role' => 'system', 'content' => $systemPrompt]],
                    $groqMessages
                ),
                'temperature' => 0.65,
                'max_tokens'  => 2000,   // 提高避免回答被截断
            ]);

            if ($response->failed()) {
                $errorData    = $response->json();
                $errorMessage = $errorData['error']['message'] ?? 'Unknown Groq API error.';
                return response()->json(['message' => $errorMessage], 400);
            }

            $data          = $response->json();
            $aiResponseText = $data['choices'][0]['message']['content'] ?? 'No response generated.';

            return response()->json(['reply' => $aiResponseText]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to connect with AI services: ' . $e->getMessage(),
            ], 500);
        }
    }
}