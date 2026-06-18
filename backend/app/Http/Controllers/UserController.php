<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    // 【新增】构造函数中添加权限保护，确保只有管理员可以访问用户管理相关接口
    // public function __construct()
    // {
    //     // 权限保护：只有超级管理员(0)和管理员(1)可以管理用户
    //     $this->middleware(function ($request, $next) {
    //         $currentUser = auth('api')->user();
    //         if (!$currentUser || $currentUser->role > User::ROLE_ADMIN) {
    //             return response()->json(['error' => 'Unauthorized. Only admins can manage users.'], 403);
    //         }
    //         return $next($request);
    //     });
    // }

    /**
     * 获取用户列表（支持分页、搜索、多条件筛选）
     */
    public function index(Request $request)
    {
        $query = User::query();

        // 1. 搜索姓名或邮箱
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        // 2. 筛选登录渠道 (google, facebook, password/standard)
        if ($request->filled('provider')) {
            if ($request->provider === 'standard') {
                $query->whereNull('provider');
            } else {
                $query->where('provider', $request->provider);
            }
        }

        // 3. 筛选角色
        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        // 4. 筛选状态
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(5);

        return response()->json($users);
    }

    /**
     * 创建用户 (包含头像上传逻辑)
     */
    public function store(Request $request)
    {
        $request->validate([
            'full_name' => 'required|string|max:255',
            'email'     => 'required|string|email|max:255|unique:users',
            'password'  => 'required|string|min:6',
            'role'      => 'required|integer|in:0,1,2,3',
            'status'    => 'required|integer|in:0,1',
            'image'     => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048', // 头像验证
        ]);

        // 处理图片上传
        $imagePath = null;
        if ($request->hasFile('image')) {
            $file = $request->file('image');
            // 重命名图片，防止冲突：时间戳 + 随机字符.后缀
            $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            // 移动文件到 public/images 目录
            $file->move(public_path('images'), $filename);
            // 拼接生成可以直接网络访问的真实完整 URL
            $imagePath = asset('images/' . $filename);
        }

        $user = User::create([
            'full_name'  => $request->full_name,
            'email'      => $request->email,
            'password'   => Hash::make($request->password),
            'role'       => $request->role,
            'status'     => $request->status,
            'image_path' => $imagePath, // 保存图片 URL
        ]);

        return response()->json(['message' => 'User created successfully', 'user' => $user], 201);
    }

    /**
     * 更新用户基本资料 (包含头像上传/覆盖逻辑)
     */
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'full_name' => 'required|string|max:255',
            'email'     => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'role'      => 'required|integer|in:0,1,2,3',
            'status'    => 'required|integer|in:0,1',
            'password'  => 'nullable|string|min:6',
            'image'     => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048', // 头像验证
        ]);

        $imagePath = $user->image_path; // 默认保留原头像

        // 如果用户上传了新头像
        if ($request->hasFile('image')) {
            // 优化：如果之前有旧的本地头像，自动删除它，防止垃圾文件堆积
            if ($user->image_path) {
                $oldLocalPath = str_replace(asset(''), public_path(''), $user->image_path);
                if (file_exists($oldLocalPath)) {
                    @unlink($oldLocalPath);
                }
            }

            $file = $request->file('image');
            $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('images'), $filename);
            $imagePath = asset('images/' . $filename); // 生成新头像地址
        }

        $data = [
            'full_name'  => $request->full_name,
            'email'      => $request->email,
            'role'       => $request->role,
            'status'     => $request->status,
            'image_path' => $imagePath,
        ];

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);

        return response()->json(['message' => 'User updated successfully', 'user' => $user]);
    }

    /**
     * 删除用户
     */
    public function destroy(User $user)
    {
        if (auth('api')->id() === $user->id) {
            return response()->json(['error' => 'You cannot delete yourself.'], 400);
        }

        $user->delete();

        return response()->json(['message' => 'User deleted successfully']);
    }
}