<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Income;
use App\Models\Budget;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

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

        // 计算储蓄率
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
                    'name' => $date->format('M d'),
                    'income' => (float)$dayIncome,
                    'expense' => (float)$dayExpense,
                ];
            }
        } else {
            for ($date = $start->copy(); $date->lte($end); $date->addWeek()) {
                $weekEnd = $date->copy()->endOfWeek()->min($end);
                $weekIncome = Income::where('user_id', $userId)->whereBetween('date', [$date->toDateString(), $weekEnd->toDateString()])->sum('price');
                $weekExpense = Expense::where('user_id', $userId)->whereBetween('date', [$date->toDateString(), $weekEnd->toDateString()])->sum('price');

                $chartData[] = [
                    'name' => 'W' . $date->weekOfMonth . ' (' . $date->format('M d') . ')',
                    'income' => (float)$weekIncome,
                    'expense' => (float)$weekExpense,
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
                    'name' => $item->category->name ?? 'Uncategorized',
                    'value' => (float)$item->total_spent,
                    'color' => $item->category->color ?? '#FF7B42',
                ];
            });

        // 4. 最近支出记录 (【已优化】：加入 whereBetween 过滤)
        $recentExpenses = Expense::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
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

        // 5. 最近收入记录 (【已优化】：加入 whereBetween 过滤)
        $recentIncomes = Income::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
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

        // 6. 获取预算状态
        $currentMonth = $start->month;
        $currentYear = $start->year;
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
                    'id' => $budget->id,
                    'category' => $budget->category->name ?? 'Category',
                    'category_color' => $budget->category->color ?? '#94a3b8',
                    'budget_amount' => (float)$budget->amount,
                    'spent_amount' => (float)$spent,
                    'percentage' => round($percentage, 1),
                    'month' => (int)$budget->month,
                    'year' => (int)$budget->year,
                ];
            });

        return response()->json([
            'metrics' => [
                'balance' => (float)$netBalance,
                'income' => (float)$totalIncome,
                'expense' => (float)$totalExpense,
                'savingsRate' => round($savingsRate, 1)
            ],
            'chartData' => $chartData,
            'categoryData' => $categorySpending,
            'recentExpenses' => $recentExpenses,
            'recentIncomes' => $recentIncomes,
            'budgets' => $budgets
        ]);
    }
}