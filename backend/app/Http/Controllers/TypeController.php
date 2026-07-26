<?php

namespace App\Http\Controllers;

use App\Models\Type;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TypeController extends Controller
{
    /**
     * 辅助私有方法：验证当前登录用户是否为 Admin (1) 或 SuperAdmin (0)
     */
    private function checkAdminPermission()
    {
        $user = auth('api')->user() ?? auth()->user();

        // 如果未登录，或者用户的 role 既不是 SuperAdmin(0) 也不是 Admin(1)，则拒绝
        if (!$user || !in_array((int)$user->role, [User::ROLE_SUPER_ADMIN, User::ROLE_ADMIN])) {
            return false;
        }

        return true;
    }

    /**
     * 获取 Type 列表 (所有登录用户均可读取，用于分类/支出/收入页面下拉框选择)
     */
    public function index(Request $request)
    {
        $query = Type::query();

        // 搜索名称
        if ($request->filled('search')) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        // 过滤状态 (0: Inactive, 1: Active)
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $types = $query->orderBy('id', 'asc')->paginate(12);

        return response()->json($types);
    }

    /**
     * 新增 Type (仅限 Admin 和 SuperAdmin)
     */
    public function store(Request $request)
    {
        // 🌟 权限拦截：非管理员直接打回 403
        if (!$this->checkAdminPermission()) {
            return response()->json(['message' => 'Unauthorized. Only Admins can create types.'], 403);
        }

        $request->validate([
            'name'   => 'required|string|max:255|unique:types,name',
            'status' => 'required|in:0,1',
        ], [
            'name.unique' => 'The type name has already been taken.'
        ]);

        $type = Type::create([
            'name'   => $request->name,
            'status' => $request->status,
        ]);

        return response()->json([
            'message' => 'Type created successfully',
            'data'    => $type
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
     * 更新 Type (仅限 Admin 和 SuperAdmin)
     */
    public function update(Request $request, $id)
    {
        // 🌟 权限拦截：非管理员直接打回 403
        if (!$this->checkAdminPermission()) {
            return response()->json(['message' => 'Unauthorized. Only Admins can update types.'], 403);
        }

        $type = Type::findOrFail($id);

        $request->validate([
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('types')->ignore($type->id)
            ],
            'status' => 'required|in:0,1',
        ]);

        $type->update([
            'name'   => $request->name,
            'status' => $request->status,
        ]);

        return response()->json([
            'message' => 'Type updated successfully',
            'data'    => $type
        ]);
    }

    /**
     * 删除 Type (仅限 Admin 和 SuperAdmin)
     */
    public function destroy($id)
    {
        // 🌟 权限拦截：非管理员直接打回 403
        if (!$this->checkAdminPermission()) {
            return response()->json(['message' => 'Unauthorized. Only Admins can delete types.'], 403);
        }

        $type = Type::findOrFail($id);
        $type->delete();

        return response()->json([
            'message' => 'Type deleted successfully'
        ]);
    }
}