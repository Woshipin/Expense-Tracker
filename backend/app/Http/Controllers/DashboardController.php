<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Income;
use App\Models\Budget;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        // 获取当前登录用户
        $user = Auth::user();
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }
        $userId = $user->id;

        $now = Carbon::now();
        $currentMonth = $now->month;
        $currentYear = $now->year;
        
        // 当月起止日期
        $startOfMonth = $now->copy()->startOfMonth()->toDateString();
        $endOfMonth = $now->copy()->endOfMonth()->toDateString();

        // 1. 计算核心指标 (当月)
        $totalIncome = Income::where('user_id', $userId)
            ->whereBetween('date', [$startOfMonth, $endOfMonth])
            ->sum('price');

        $totalExpense = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startOfMonth, $endOfMonth])
            ->sum('price');

        // 本月净余额 (当月总收入 - 当月总支出)
        $balance = $totalIncome - $totalExpense;

        // 当月储蓄率
        $savingsRate = $totalIncome > 0 ? (($totalIncome - $totalExpense) / $totalIncome) * 100 : 0;

        // 2. 趋势折线图数据
        $chartData = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::today()->subDays($i);
            $dateStr = $date->toDateString();

            $dayIncome = Income::where('user_id', $userId)->whereDate('date', $dateStr)->sum('price');
            $dayExpense = Expense::where('user_id', $userId)->whereDate('date', $dateStr)->sum('price');

            $chartData[] = [
                'name' => $date->format('D'),
                'income' => (float)$dayIncome,
                'expense' => (float)$dayExpense,
            ];
        }

        // 3. 本月最高支出分类数据
        $topCategories = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startOfMonth, $endOfMonth])
            ->with('category')
            ->selectRaw('category_id, SUM(price) as total_spent')
            ->groupBy('category_id')
            ->orderByDesc('total_spent')
            ->take(5)
            ->get()
            ->map(function ($item) {
                return [
                    'name' => $item->category->name ?? 'Uncategorized',
                    'value' => (float)$item->total_spent,
                    'color' => $item->category->color ?? '#FF7B42',
                ];
            });
            
        // 4. 最近支出记录
        $recentExpenses = Expense::where('user_id', $userId)
            ->with('category')
            ->orderByDesc('date')
            ->orderByDesc('time')
            ->take(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'title' => $item->title,
                    'category' => $item->category->name ?? 'Uncategorized',
                    'date' => Carbon::parse($item->date)->format('M d, Y'),
                    'price' => (float)$item->price,
                    'type' => 'expense',
                ];
            });

        // 5. 最近收入记录
        $recentIncomes = Income::where('user_id', $userId)
            ->with('category')
            ->orderByDesc('date')
            ->orderByDesc('time')
            ->take(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'title' => $item->title,
                    'category' => $item->category->name ?? 'Uncategorized',
                    'date' => Carbon::parse($item->date)->format('M d, Y'),
                    'price' => (float)$item->price,
                    'type' => 'income',
                ];
            });

        // 6. 预算状态 (补充：category_color, month, year)
        $budgets = Budget::where('user_id', $userId)
            ->where('month', $currentMonth)
            ->where('year', $currentYear)
            ->with('category')
            ->get()
            ->map(function ($budget) use ($userId, $startOfMonth, $endOfMonth) {
                $spent = Expense::where('user_id', $userId)
                    ->where('category_id', $budget->category_id)
                    ->whereBetween('date', [$startOfMonth, $endOfMonth])
                    ->sum('price');

                $percentage = $budget->amount > 0 ? ($spent / $budget->amount) * 100 : 0;

                return [
                    'id' => $budget->id,
                    'category' => $budget->category->name ?? 'Category',
                    'category_color' => $budget->category->color ?? '#94a3b8', // 分类预设颜色
                    'budget_amount' => (float)$budget->amount,
                    'spent_amount' => (float)$spent,
                    'percentage' => round($percentage, 1),
                    'month' => (int)$budget->month, // 所属月份
                    'year' => (int)$budget->year,  // 所属年份
                ];
            });

        return response()->json([
            'metrics' => [
                'balance' => (float)$balance,
                'income' => (float)$totalIncome,
                'expense' => (float)$totalExpense,
                'savingsRate' => round($savingsRate, 1)
            ],
            'chartData' => $chartData,
            'pieData' => $topCategories,
            'recentExpenses' => $recentExpenses,
            'recentIncomes' => $recentIncomes,
            'budgets' => $budgets
        ]);
    }
}