<?php

namespace App\Http\Controllers;

use App\Models\Budget;
use App\Models\Expense;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;

class BudgetController extends Controller
{
    /**
     * 获取预算列表 (包含 Category 的 Type 关联)
     */
    public function index()
    {
        try {
            $user = auth()->user();

            // 预加载 category 及其对应的 type 关系
            $budgets = Budget::with(['category.type'])
                ->where('user_id', $user->id)
                ->latest()
                ->get();

            $result = $budgets->map(function ($budget) use ($user) {
                
                // 分类数据，附带完整的 type 信息
                $categoryData = $budget->category ? [
                    'id'      => $budget->category->id,
                    'name'    => $budget->category->name,
                    'icon'    => $budget->category->icon,
                    'color'   => $budget->category->color,
                    'type_id' => $budget->category->type_id,
                    'type'    => $budget->category->type ? [
                        'id'   => $budget->category->type->id,
                        'name' => $budget->category->type->name,
                    ] : null,
                ] : [
                    'id'      => 0,
                    'name'    => 'Uncategorized',
                    'icon'    => 'Tag',
                    'color'   => '#94a3b8',
                    'type_id' => 1,
                    'type'    => ['id' => 1, 'name' => 'Expense'],
                ];

                // 统计当月在该分类下的已花费金额
                $spent = Expense::where('user_id', $user->id)
                    ->where('category_id', $budget->category_id)
                    ->whereMonth('date', $budget->month) 
                    ->whereYear('date', $budget->year)
                    ->sum('price'); 

                $remaining = $budget->amount - $spent;

                $percentage = $budget->amount > 0
                    ? round(($spent / $budget->amount) * 100, 2)
                    : 0;

                return [
                    'id'         => $budget->id,
                    'category'   => $categoryData,
                    'amount'     => (float) $budget->amount,
                    'month'      => (int) $budget->month,
                    'year'       => (int) $budget->year,
                    'spent'      => (float) $spent,
                    'remaining'  => (float) $remaining,
                    'percentage' => (float) $percentage,
                ];
            });

            return response()->json($result);

        } catch (\Exception $e) {
            Log::error('Budget Index Error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to fetch budgets: ' . $e->getMessage()
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
                    Rule::unique('budgets')->where(function ($query) use ($userId, $request) {
                        return $query->where('user_id', $userId)
                                     ->where('month', $request->month)
                                     ->where('year', $request->year);
                    })
                ],
                'amount' => 'required|numeric|min:1',
                'month'  => 'required|integer|min:1|max:12',
                'year'   => 'required|integer'
            ], [
                'category_id.unique' => 'A budget for this category already exists in the selected month.'
            ]);

            $budget = Budget::create([
                'user_id'     => $userId,
                'category_id' => $request->category_id,
                'amount'      => $request->amount,
                'month'       => $request->month,
                'year'        => $request->year
            ]);

            return response()->json([
                'message' => 'Budget created successfully',
                'data'    => $budget
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['message' => collect($e->errors())->flatten()->first()], 422);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to create budget: ' . $e->getMessage()], 500);
        }
    }

    public function show($id)
    {
        try {
            $budget = Budget::where('user_id', auth()->id())->findOrFail($id);
            $budget->amount = (float) $budget->amount;
            return response()->json($budget);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Budget not found'], 404);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $userId = auth()->id();
            $budget = Budget::where('user_id', $userId)->findOrFail($id);

            $request->validate([
                'category_id' => [
                    'required',
                    'exists:categories,id',
                    Rule::unique('budgets')->where(function ($query) use ($userId, $request) {
                        return $query->where('user_id', $userId)
                                     ->where('month', $request->month)
                                     ->where('year', $request->year);
                    })->ignore($budget->id)
                ],
                'amount' => 'required|numeric|min:1',
                'month'  => 'required|integer|min:1|max:12',
                'year'   => 'required|integer'
            ], [
                'category_id.unique' => 'A budget for this category already exists in the selected month.'
            ]);

            $budget->update([
                'category_id' => $request->category_id,
                'amount'      => $request->amount,
                'month'       => $request->month,
                'year'        => $request->year
            ]);

            return response()->json(['message' => 'Budget updated successfully']);
            
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['message' => collect($e->errors())->flatten()->first()], 422);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to update budget: ' . $e->getMessage()], 500);
        }
    }

    public function destroy($id)
    {
        try {
            $budget = Budget::where('user_id', auth()->id())->findOrFail($id);
            $budget->delete();
            return response()->json(['message' => 'Budget deleted successfully']);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to delete budget'], 500);
        }
    }
}