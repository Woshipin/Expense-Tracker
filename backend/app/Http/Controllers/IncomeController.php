<?php

namespace App\Http\Controllers;

use App\Models\Income;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Validation\Rule;

class IncomeController extends Controller
{
    public function index(Request $request)
    {
        // 改进：对控制器的 Query 参数进行基础校验，防止非法输入引发数据库报错 (500)
        $request->validate([
            'search' => 'nullable|string|max:100',
            'category_id' => 'nullable|string',
            'payment_method_id' => 'nullable|string',
            'start_date' => 'nullable|string',
            'end_date' => 'nullable|string',
        ]);

        // 仅查询当前用户
        $query = Income::with(['category', 'payment_method'])
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
            if ($request->start_date === 'today') {
                $query->whereDate('date', '>=', Carbon::today());
            } elseif ($request->start_date === 'yesterday') {
                $query->whereDate('date', '>=', Carbon::yesterday());
            } else {
                // 确保传入的值是有效日期格式后再进行查询
                $startDate = strtotime($request->start_date) ? Carbon::parse($request->start_date) : null;
                if ($startDate) {
                    $query->whereDate('date', '>=', $startDate);
                }
            }
        }

        if ($request->filled('end_date') && $request->end_date !== 'any') {
            if ($request->end_date === 'today') {
                $query->whereDate('date', '<=', Carbon::today());
            } elseif ($request->end_date === 'yesterday') {
                $query->whereDate('date', '<=', Carbon::yesterday());
            } else {
                // 确保传入的值是有效日期格式后再进行查询
                $endDate = strtotime($request->end_date) ? Carbon::parse($request->end_date) : null;
                if ($endDate) {
                    $query->whereDate('date', '<=', $endDate);
                }
            }
        }

        // 提示：请确保在数据库迁移中为 ['user_id', 'date', 'time'] 创建了联合索引以保证排序性能
        $incomes = $query->orderBy('date', 'desc')->orderBy('time', 'desc')->paginate(10);

        return response()->json($incomes);
    }

    public function store(Request $request)
    {
        // 改进：严格限制了 'time' 的输入格式为 24小时制 HH:MM (例如 14:30)
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required|date_format:H:i',
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('user_id', auth()->id())],
            'category_id' => ['required', Rule::exists('categories', 'id')->where('user_id', auth()->id())],
        ]);

        // 改进：避免使用 $request->all()，仅将通过安全验证的数据写入数据库，防止恶意参数注入
        $validated['user_id'] = auth()->id();

        $income = Income::create($validated);
        return response()->json(['message' => 'Income created', 'data' => $income], 201);
    }

    public function update(Request $request, $id)
    {
        $income = Income::where('user_id', auth()->id())->findOrFail($id);

        // 改进：同样严格限制了 'time' 的格式
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required|date_format:H:i',
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('user_id', auth()->id())],
            'category_id' => ['required', Rule::exists('categories', 'id')->where('user_id', auth()->id())],
        ]);

        // 改进：仅更新通过验证的数据
        $income->update($validated);
        return response()->json(['message' => 'Income updated', 'data' => $income]);
    }

    public function destroy($id)
    {
        $income = Income::where('user_id', auth()->id())->findOrFail($id);
        $income->delete();
        return response()->json(['message' => 'Income deleted']);
    }
}