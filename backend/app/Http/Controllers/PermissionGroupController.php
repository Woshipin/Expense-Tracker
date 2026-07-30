<?php

namespace App\Http\Controllers;

use App\Models\PermissionGroup;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class PermissionGroupController extends Controller
{
    /**
     * 🌟 后端防御拦截：确保只有 Super Admin (Role 0) 或授权用户可以调取此 Controller 内的 API
     */
    private function checkPermissionGuard(): void
    {
        $user = auth()->user();
        if (!$user) {
            abort(401, 'Unauthenticated.');
        }

        // 如果是 Role 0 (Super Admin) 或者是组内赋予了权限的用户允许通过，否则直接抛出 403 异常
        if ((int)$user->role !== 0 && !in_array('permissions.view', $user->permissions || [])) {
            abort(403, 'Forbidden. Only Super Admin can manage permission groups.');
        }
    }

    /**
     * 1. 获取权限组列表
     */
    public function index(Request $request): JsonResponse
    {
        $this->checkPermissionGuard(); // 🌟 拦截检查

        $query = PermissionGroup::with('users');

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $groups = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $groups
        ]);
    }

    /**
     * 2. 新增权限组
     */
    public function store(Request $request): JsonResponse
    {
        $this->checkPermissionGuard(); // 🌟 拦截检查

        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:permission_groups,name',
            'description' => 'nullable|string|max:1000',
            'permissions' => 'nullable|array',
            'assigned_user_ids' => 'nullable|array',
            'assigned_user_ids.*' => 'exists:users,id',
        ]);

        DB::beginTransaction();
        try {
            $group = PermissionGroup::create([
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
                'permissions' => $validated['permissions'] ?? [],
            ]);

            if (!empty($validated['assigned_user_ids'])) {
                $group->users()->sync($validated['assigned_user_ids']);
            }

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Permission group created successfully.',
                'data' => $group->load('users')
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to create permission group: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 3. 获取单个权限组详情
     */
    public function show(string $id): JsonResponse
    {
        $this->checkPermissionGuard(); // 🌟 拦截检查

        $group = PermissionGroup::with('users')->find($id);

        if (!$group) {
            return response()->json(['status' => 'error', 'message' => 'Group not found.'], 404);
        }

        return response()->json(['status' => 'success', 'data' => $group]);
    }

    /**
     * 4. 更新权限组
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $this->checkPermissionGuard(); // 🌟 拦截检查

        $group = PermissionGroup::find($id);

        if (!$group) {
            return response()->json(['status' => 'error', 'message' => 'Group not found.'], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:permission_groups,name,' . $id,
            'description' => 'nullable|string|max:1000',
            'permissions' => 'nullable|array',
            'assigned_user_ids' => 'nullable|array',
            'assigned_user_ids.*' => 'exists:users,id',
        ]);

        DB::beginTransaction();
        try {
            $group->update([
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
                'permissions' => $validated['permissions'] ?? [],
            ]);

            $assignedUserIds = $validated['assigned_user_ids'] ?? [];
            $group->users()->sync($assignedUserIds);

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Permission group updated successfully.',
                'data' => $group->load('users')
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update permission group: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 5. 删除权限组
     */
    public function destroy(string $id): JsonResponse
    {
        $this->checkPermissionGuard(); // 🌟 拦截检查

        $group = PermissionGroup::find($id);

        if (!$group) {
            return response()->json(['status' => 'error', 'message' => 'Group not found.'], 404);
        }

        DB::beginTransaction();
        try {
            $group->users()->detach();
            $group->delete();

            DB::commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Permission group deleted successfully.'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to delete permission group: ' . $e->getMessage()
            ], 500);
        }
    }
}