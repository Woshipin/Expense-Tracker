<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CategoryController extends Controller
{
    // 获取列表 (关联加载 type 详情)
    public function index(Request $request)
    {
        // 预加载 type，方便前端识别 Expense 还是 Income
        $query = Category::with('type')->where('user_id', auth()->id());

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $categories = $query->orderBy('created_at', 'desc')->paginate(12); // 每页显示 12 个卡片

        return response()->json($categories);
    }

    // 保存分类 (支持 type_id, icon, color)
    public function store(Request $request)
    {
        $request->validate([
            // 联合唯一：同一个用户在同一个收支类型(type_id)下不能有重名的分类
            'name' => [
                'required', 'string', 'max:255', 
                Rule::unique('categories')
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
        
        $category = Category::create($data);

        return response()->json(['message' => 'Category created successfully', 'data' => $category], 201);
    }

    // 更新分类 (支持 type_id, icon, color)
    public function update(Request $request, $id)
    {
        $category = Category::where('user_id', auth()->id())->findOrFail($id);

        $request->validate([
            'name' => [
                'required', 'string', 'max:255', 
                Rule::unique('categories')
                    ->where('user_id', auth()->id())
                    ->where('type_id', $request->type_id)
                    ->ignore($category->id)
            ],
            'type_id' => 'required|exists:types,id',
            'icon' => 'nullable|string|max:255',
            'color' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:1000',
            'status' => 'required|in:0,1',
        ]);

        // 【安全接收】
        $category->update($request->only(['name', 'type_id', 'icon', 'color', 'description', 'status']));

        return response()->json(['message' => 'Category updated successfully', 'data' => $category]);
    }

    // 删除分类
    public function destroy($id)
    {
        $category = Category::where('user_id', auth()->id())->findOrFail($id);
        $category->delete();

        return response()->json(['message' => 'Category deleted successfully']);
    }
}