<?php

namespace App\Http\Controllers;

use App\Models\PaymentMethod;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PaymentMethodController extends Controller
{
    /**
     * 获取列表 (对应 GET /payment-methods)
     */
    public function index(Request $request)
    {
        $query = PaymentMethod::query();

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $methods = $query->orderBy('created_at', 'desc')->paginate(5);

        return response()->json($methods);
    }

    /**
     * 新增保存 (对应 POST /payment-methods)
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:payment_methods,name',
            'description' => 'nullable|string|max:1000',
            // 【修改这里】：将 in:Active,Inactive 改为 in:0,1
            'status' => 'required|in:0,1', 
        ]);

        $method = PaymentMethod::create($request->only(['name', 'description', 'status']));

        return response()->json([
            'message' => 'Payment method created successfully',
            'data' => $method
        ], 201);
    }

    /**
     * 更新保存 (对应 PUT /payment-methods/{id})
     */
    public function update(Request $request, $id)
    {
        $method = PaymentMethod::findOrFail($id);

        $request->validate([
            'name' => ['required', 'string', 'max:255', Rule::unique('payment_methods')->ignore($method->id)],
            'description' => 'nullable|string|max:1000',
            // 【修改这里】：将 in:Active,Inactive 改为 in:0,1
            'status' => 'required|in:0,1',
        ]);

        $method->update($request->only(['name', 'description', 'status']));

        return response()->json([
            'message' => 'Payment method updated successfully',
            'data' => $method
        ]);
    }

    /**
     * 物理删除 (对应 DELETE /payment-methods/{id})
     */
    public function destroy($id)
    {
        $method = PaymentMethod::findOrFail($id);
        $method->delete();

        return response()->json([
            'message' => 'Payment method deleted successfully'
        ]);
    }
}