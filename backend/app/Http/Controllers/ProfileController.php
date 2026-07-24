<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    /**
     * 更新用户基本资料 (姓名, 邮箱, 头像)
     */
    public function updateProfile(Request $request)
    {
        $user = auth('api')->user() ?? auth()->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $request->validate([
            'full_name' => 'required|string|max:255',
            // 验证邮箱格式，且确保邮箱唯一（排除当前用户自己的邮箱）
            'email'     => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            // 验证图片文件
            'image'     => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048', 
        ]);

        try {
            $data = [
                'full_name' => $request->full_name,
                'email'     => $request->email,
            ];

            // 处理图片上传
            if ($request->hasFile('image')) {
                // 【核心修复 1】：自动确保 public/images 文件夹存在，防止 Render 服务器因找不到目录报 500 错误
                $destinationPath = public_path('images');
                if (!file_exists($destinationPath)) {
                    @mkdir($destinationPath, 0777, true);
                }

                // 【核心修复 2】：安全解析并删除旧的本地头像
                if ($user->image_path) {
                    $parsedPath = parse_url($user->image_path, PHP_URL_PATH);
                    if ($parsedPath) {
                        $oldFilename = basename($parsedPath);
                        $oldFileLocal = public_path('images/' . $oldFilename);
                        if (file_exists($oldFileLocal) && is_file($oldFileLocal)) {
                            @unlink($oldFileLocal);
                        }
                    }
                }

                // 保存新文件
                $file = $request->file('image');
                $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
                $file->move($destinationPath, $filename);

                // 拼接可直接访问的 URL
                $data['image_path'] = asset('images/' . $filename);
            }

            $user->update($data);

            return response()->json([
                'message' => 'Profile updated successfully',
                'user'    => $user
            ]);

        } catch (\Exception $e) {
            Log::error('Profile Update Error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to update profile: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 修改密码
     */
    public function updatePassword(Request $request)
    {
        $user = auth('api')->user() ?? auth()->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        // 如果用户是第三方登录（没密码），禁止修改密码
        if ($user->provider) {
            return response()->json([
                'error' => 'Social login users cannot change password here.'
            ], 400);
        }

        $request->validate([
            'current_password' => 'required|string',
            'new_password'     => 'required|string|min:6|confirmed',
        ]);

        // 验证当前密码是否正确
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'errors' => ['current_password' => ['The current password is incorrect.']]
            ], 422);
        }

        // 更新新密码
        $user->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json(['message' => 'Password changed securely.']);
    }

    /**
     * API 代理读取并返回图片文件 (自动附加 CORS 头)
     */
    public function serveImage($filename)
    {
        $path = public_path('images/' . $filename);

        if (!file_exists($path)) {
            abort(404);
        }

        return response()->file($path);
    }
}