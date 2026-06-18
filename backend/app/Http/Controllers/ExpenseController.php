<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ExpenseController extends Controller
{
    public function index(Request $request)
    {
        // 使用 with() 预加载关联，这样返回的 JSON 里就会包含 category 和 payment_method 的详细信息
        $query = Expense::with(['category', 'payment_method']);

        // 1. 搜索
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // 2. 分类 ID 筛选
        if ($request->filled('category_id') && $request->category_id !== 'all') {
            $query->where('category_id', $request->category_id);
        }

        // 3. 支付方式 ID 筛选
        if ($request->filled('payment_method_id') && $request->payment_method_id !== 'all') {
            $query->where('payment_method_id', $request->payment_method_id);
        }

        // 4. 开始日期
        if ($request->filled('start_date') && $request->start_date !== 'any') {
            if ($request->start_date === 'today') $query->whereDate('date', '>=', Carbon::today());
            elseif ($request->start_date === 'yesterday') $query->whereDate('date', '>=', Carbon::yesterday());
            else $query->whereDate('date', '>=', $request->start_date);
        }

        // 5. 结束日期
        if ($request->filled('end_date') && $request->end_date !== 'any') {
            if ($request->end_date === 'today') $query->whereDate('date', '<=', Carbon::today());
            elseif ($request->end_date === 'yesterday') $query->whereDate('date', '<=', Carbon::yesterday());
            else $query->whereDate('date', '<=', $request->end_date);
        }

        $expenses = $query->orderBy('date', 'desc')->orderBy('time', 'desc')->paginate(5);

        return response()->json($expenses);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required',
            // 确保存入的 ID 在对应表中存在
            'payment_method_id' => 'required|exists:payment_methods,id',
            'category_id' => 'required|exists:categories,id',
        ]);

        $expense = Expense::create($request->all());
        return response()->json(['message' => 'Expense created', 'data' => $expense], 201);
    }

    public function update(Request $request, $id)
    {
        $expense = Expense::findOrFail($id);

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'category_id' => 'required|exists:categories,id',
        ]);

        $expense->update($request->all());
        return response()->json(['message' => 'Expense updated', 'data' => $expense]);
    }

    public function destroy($id)
    {
        $expense = Expense::findOrFail($id);
        $expense->delete();
        return response()->json(['message' => 'Expense deleted']);
    }
}