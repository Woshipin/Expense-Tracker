<?php

namespace App\Http\Controllers;

use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CategoryController extends Controller
{
    // 获取列表 (搜索 + 状态过滤 + 分页)
    public function index(Request $request)
    {
        $query = Category::query();

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

        $categories = $query->orderBy('created_at', 'desc')->paginate(5);

        return response()->json($categories);
    }

    // 新增
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:categories,name',
            'description' => 'nullable|string|max:1000',
            'status' => 'required|in:0,1', 
        ]);

        $category = Category::create($request->only(['name', 'description', 'status']));

        return response()->json([
            'message' => 'Category created successfully',
            'data' => $category
        ], 201);
    }

    // 更新
    public function update(Request $request, $id)
    {
        $category = Category::findOrFail($id);

        $request->validate([
            'name' => ['required', 'string', 'max:255', Rule::unique('categories')->ignore($category->id)],
            'description' => 'nullable|string|max:1000',
            'status' => 'required|in:0,1',
        ]);

        $category->update($request->only(['name', 'description', 'status']));

        return response()->json([
            'message' => 'Category updated successfully',
            'data' => $category
        ]);
    }

    // 删除
    public function destroy($id)
    {
        $category = Category::findOrFail($id);
        $category->delete();

        return response()->json([
            'message' => 'Category deleted successfully'
        ]);
    }
}