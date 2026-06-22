<?php

namespace App\Http\Controllers;

use App\Models\PaymentMethod;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PaymentMethodController extends Controller
{
    // 获取列表 (关联加载 type 详情)
    public function index(Request $request)
    {
        $query = PaymentMethod::with('type')->where('user_id', auth()->id());

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $methods = $query->orderBy('created_at', 'desc')->paginate(12);

        return response()->json($methods);
    }

    // 保存支付方式 (支持 type_id, icon, color)
    public function store(Request $request)
    {
        $request->validate([
            'name' => [
                'required', 'string', 'max:255',
                Rule::unique('payment_methods')
                    ->where('user_id', auth()->id())
                    ->where('type_id', $request->type_id)
            ],
            'type_id' => 'required|exists:types,id', // 验证传入的收支类型必须存在
            'icon' => 'nullable|string|max:255',
            'color' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000',
            'status' => 'required|in:0,1', 
        ]);

        // 【安全接收】：将新字段 type_id, icon, color 纳入允许接收的数组中
        $data = $request->only(['name', 'type_id', 'icon', 'color', 'description', 'status']);
        $data['user_id'] = auth()->id(); // 强制绑定当前用户
        
        $method = PaymentMethod::create($data);

        return response()->json(['message' => 'Payment method created successfully', 'data' => $method], 201);
    }

    // 更新支付方式 (支持 type_id, icon, color)
    public function update(Request $request, $id)
    {
        $method = PaymentMethod::where('user_id', auth()->id())->findOrFail($id);

        $request->validate([
            'name' => [
                'required', 'string', 'max:255', 
                Rule::unique('payment_methods')
                    ->where('user_id', auth()->id())
                    ->where('type_id', $request->type_id)
                    ->ignore($method->id)
            ],
            'type_id' => 'required|exists:types,id',
            'icon' => 'nullable|string|max:255',
            'color' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000',
            'status' => 'required|in:0,1',
        ]);

        // 【安全接收】
        $method->update($request->only(['name', 'type_id', 'icon', 'color', 'description', 'status']));

        return response()->json(['message' => 'Payment method updated successfully', 'data' => $method]);
    }

    // 删除支付方式
    public function destroy($id)
    {
        $method = PaymentMethod::where('user_id', auth()->id())->findOrFail($id);
        $method->delete();

        return response()->json(['message' => 'Payment method deleted successfully']);
    }
}