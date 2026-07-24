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
        $userId = auth()->id(); // 安全隔离：获取当前登录用户 ID

        // 获取该用户的支出 (Expense)
        $expenses = Expense::with(['category', 'payment_method'])
            ->where('user_id', $userId)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->get()
            ->map(function ($item) {
                $item->type = 'expense'; 
                return $item;
            });

        // 获取该用户的收入 (Income)
        $incomes = Income::with(['category', 'payment_method'])
            ->where('user_id', $userId)
            ->whereYear('date', $year)
            ->whereMonth('date', $month)
            ->get()
            ->map(function ($item) {
                $item->type = 'income';
                return $item;
            });

        // 合并数据并按日期和时间升序排序
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