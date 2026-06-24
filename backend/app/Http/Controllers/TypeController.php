<?php

namespace App\Http\Controllers;

use App\Models\Type;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TypeController extends Controller
{
    /**
     * 获取 Type 列表 (支持分页、搜索、状态过滤)
     */
    public function index(Request $request)
    {
        $query = Type::query();

        // 搜索名称
        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        // 过滤状态
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $types = $query->latest()->paginate(12);

        return response()->json($types);
    }

    /**
     * 新增 Type
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:types,name',
            'status' => 'required|in:0,1',
        ], [
            'name.unique' => 'The type name has already been taken.'
        ]);

        $type = Type::create([
            'name' => $request->name,
            'status' => $request->status,
        ]);

        return response()->json([
            'message' => 'Type created successfully',
            'data' => $type
        ], 201);
    }

    /**
     * 获取单条 Type 详情
     */
    public function show($id)
    {
        $type = Type::findOrFail($id);
        return response()->json($type);
    }

    /**
     * 更新 Type
     */
    public function update(Request $request, $id)
    {
        $type = Type::findOrFail($id);

        $request->validate([
            // 验证唯一性时，排除当前记录本身的 ID
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('types')->ignore($type->id)
            ],
            'status' => 'required|in:0,1',
        ]);

        $type->update([
            'name' => $request->name,
            'status' => $request->status,
        ]);

        return response()->json([
            'message' => 'Type updated successfully',
            'data' => $type
        ]);
    }

    /**
     * 删除 Type
     */
    public function destroy($id)
    {
        $type = Type::findOrFail($id);
        
        // 建议：如果你后续设置了外键，且有 category 绑定了这个 type，
        // 这里可以直接 delete（迁移文件写了级联删除），或者返回错误提示不能删除。
        $type->delete();

        return response()->json([
            'message' => 'Type deleted successfully'
        ]);
    }
}