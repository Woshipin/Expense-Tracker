<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Validation\Rule;

class ExpenseController extends Controller
{
    public function index(Request $request)
    {
        // 仅查询当前用户
        $query = Expense::with(['category', 'payment_method'])
                        ->where('user_id', auth()->id());

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($request->filled('category_id') && $request->category_id !== 'all') {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('payment_method_id') && $request->payment_method_id !== 'all') {
            $query->where('payment_method_id', $request->payment_method_id);
        }

        if ($request->filled('start_date') && $request->start_date !== 'any') {
            if ($request->start_date === 'today') $query->whereDate('date', '>=', Carbon::today());
            elseif ($request->start_date === 'yesterday') $query->whereDate('date', '>=', Carbon::yesterday());
            else $query->whereDate('date', '>=', $request->start_date);
        }

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
            // 极高安全防护：确保提交的 ID 是存在于数据库中，并且 user_id 是当前登录者的
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('user_id', auth()->id())],
            'category_id' => ['required', Rule::exists('categories', 'id')->where('user_id', auth()->id())],
        ]);

        $data = $request->all();
        $data['user_id'] = auth()->id(); // 强制绑定

        $expense = Expense::create($data);
        return response()->json(['message' => 'Expense created', 'data' => $expense], 201);
    }

    public function update(Request $request, $id)
    {
        // 仅能修改自己的账单
        $expense = Expense::where('user_id', auth()->id())->findOrFail($id);

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required',
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('user_id', auth()->id())],
            'category_id' => ['required', Rule::exists('categories', 'id')->where('user_id', auth()->id())],
        ]);

        $expense->update($request->all());
        return response()->json(['message' => 'Expense updated', 'data' => $expense]);
    }

    public function destroy($id)
    {
        // 仅能删除自己的账单
        $expense = Expense::where('user_id', auth()->id())->findOrFail($id);
        $expense->delete();
        return response()->json(['message' => 'Expense deleted']);
    }
}