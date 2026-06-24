<?php

namespace App\Http\Controllers;

use App\Models\Budget;
use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log; // 引入日志模块

class BudgetController extends Controller
{
    /**
     * 获取预算列表
     */
    public function index()
    {
        try {
            $user = auth()->user();

            $budgets = Budget::with('category')
                ->where('user_id', $user->id)
                ->latest()
                ->get();

            $result = $budgets->map(function ($budget) use ($user) {
                
                // 防崩溃保护 1：如果分类被意外删除，提供默认值防止试图读取 null 的属性
                $categoryData = $budget->category ? [
                    'id' => $budget->category->id,
                    'name' => $budget->category->name,
                    'icon' => $budget->category->icon,
                    'color' => $budget->category->color,
                ] : [
                    'id' => 0,
                    'name' => '未分类/已删除',
                    'icon' => '❓',
                    'color' => '#94a3b8',
                ];

                // 核心修复点 🎯：根据你的 expenses 迁移文件，金额字段是 price，日期字段是 date
                $spent = Expense::where('user_id', $user->id)
                    ->where('category_id', $budget->category_id)
                    ->whereMonth('date', $budget->month) 
                    ->whereYear('date', $budget->year)
                    ->sum('price'); // <--- 已经将这里修改为 price 

                $remaining = $budget->amount - $spent;

                $percentage = $budget->amount > 0
                    ? round(($spent / $budget->amount) * 100, 2)
                    : 0;

                return [
                    'id' => $budget->id,
                    'category' => $categoryData,
                    'amount' => (float) $budget->amount,
                    'month' => (int) $budget->month,
                    'year' => (int) $budget->year,
                    'spent' => (float) $spent,
                    'remaining' => (float) $remaining,
                    'percentage' => (float) $percentage,
                ];
            });

            return response()->json($result);

        } catch (\Exception $e) {
            // 记录具体错误日志，方便排查
            Log::error('Budget Index Error: ' . $e->getMessage());
            return response()->json([
                'message' => '获取预算失败，后端错误：' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 创建预算
     */
    public function store(Request $request)
    {
        try {
            $userId = auth()->id();

            $request->validate([
                'category_id' => [
                    'required',
                    'exists:categories,id',
                    // 防止同一年同一月重复添加同一个分类的预算
                    Rule::unique('budgets')->where(function ($query) use ($userId, $request) {
                        return $query->where('user_id', $userId)
                                     ->where('month', $request->month)
                                     ->where('year', $request->year);
                    })
                ],
                'amount' => 'required|numeric|min:1',
                'month' => 'required|integer|min:1|max:12',
                'year' => 'required|integer'
            ], [
                'category_id.unique' => '该月份已存在此分类的预算，请勿重复添加。'
            ]);

            $budget = Budget::create([
                'user_id' => $userId,
                'category_id' => $request->category_id,
                'amount' => $request->amount,
                'month' => $request->month,
                'year' => $request->year
            ]);

            return response()->json([
                'message' => '预算创建成功',
                'data' => $budget
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['message' => collect($e->errors())->flatten()->first()], 422);
        } catch (\Exception $e) {
            return response()->json(['message' => '创建失败：' . $e->getMessage()], 500);
        }
    }

    /**
     * 获取预算详情
     */
    public function show($id)
    {
        try {
            $budget = Budget::where('user_id', auth()->id())->findOrFail($id);
            $budget->amount = (float) $budget->amount;
            return response()->json($budget);
        } catch (\Exception $e) {
            return response()->json(['message' => '找不到该预算'], 404);
        }
    }

    /**
     * 更新预算
     */
    public function update(Request $request, $id)
    {
        try {
            $userId = auth()->id();
            $budget = Budget::where('user_id', $userId)->findOrFail($id);

            $request->validate([
                'category_id' => [
                    'required',
                    'exists:categories,id',
                    // 编辑时也要验证唯一性，但忽略当前记录本身
                    Rule::unique('budgets')->where(function ($query) use ($userId, $request) {
                        return $query->where('user_id', $userId)
                                     ->where('month', $request->month)
                                     ->where('year', $request->year);
                    })->ignore($budget->id)
                ],
                'amount' => 'required|numeric|min:1',
                'month' => 'required|integer|min:1|max:12',
                'year' => 'required|integer'
            ], [
                'category_id.unique' => '该月份已存在此分类的预算。'
            ]);

            $budget->update([
                'category_id' => $request->category_id,
                'amount' => $request->amount,
                'month' => $request->month,
                'year' => $request->year
            ]);

            return response()->json(['message' => '预算更新成功']);
            
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['message' => collect($e->errors())->flatten()->first()], 422);
        } catch (\Exception $e) {
            return response()->json(['message' => '更新失败：' . $e->getMessage()], 500);
        }
    }

    /**
     * 删除预算
     */
    public function destroy($id)
    {
        try {
            $budget = Budget::where('user_id', auth()->id())->findOrFail($id);
            $budget->delete();
            return response()->json(['message' => '预算删除成功']);
        } catch (\Exception $e) {
            return response()->json(['message' => '删除失败'], 500);
        }
    }
}