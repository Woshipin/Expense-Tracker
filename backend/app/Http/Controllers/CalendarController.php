<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Income;
use Illuminate\Http\Request;

class CalendarController extends Controller
{
    public function index(Request $request)
    {
        $year = $request->input('year', date('Y'));
        $month = $request->input('month', date('m'));
        $userId = auth()->id(); // 获取当前用户 ID

        // 获取该用户的开销
        $expenses = Expense::with(['category', 'payment_method'])
            ->where('user_id', $userId) // 安全隔离：只查当前用户
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->get()
            ->map(function ($item) {
                $item->type = 'expense'; 
                return $item;
            });

        // 获取该用户的收入
        $incomes = Income::with(['category', 'payment_method'])
            ->where('user_id', $userId) // 安全隔离：只查当前用户
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->get()
            ->map(function ($item) {
                $item->type = 'income';
                return $item;
            });

        // 合并数据并按日期和时间排序
        $merged = $expenses->concat($incomes)
            ->sortBy(['date', 'time'])
            ->values();

        return response()->json([
            'year' => $year,
            'month' => $month,
            'data' => $merged
        ]);
    }
}