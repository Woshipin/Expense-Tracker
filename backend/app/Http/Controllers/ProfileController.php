<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    /**
     * 更新用户基本资料 (姓名, 邮箱, 头像)
     */
    public function updateProfile(Request $request)
    {
        $user = auth('api')->user();

        $request->validate([
            'full_name' => 'required|string|max:255',
            // 验证邮箱格式，且确保邮箱唯一（排除当前用户自己的邮箱）
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            // 验证图片文件
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048', 
        ]);

        $data = [
            'full_name' => $request->full_name,
            'email'     => $request->email,
        ];

        // 处理图片上传
        if ($request->hasFile('image')) {
            // 如果存在旧头像，自动从服务器删除，避免垃圾文件堆积
            if ($user->image_path) {
                $oldLocalPath = str_replace(asset(''), public_path(''), $user->image_path);
                if (file_exists($oldLocalPath)) {
                    @unlink($oldLocalPath);
                }
            }

            $file = $request->file('image');
            $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            $file->move(public_path('images'), $filename);
            // 拼接可直接访问的 URL
            $data['image_path'] = asset('images/' . $filename);
        }

        $user->update($data);

        return response()->json([
            'message' => 'Profile updated successfully',
            'user'    => $user
        ]);
    }

    /**
     * 修改密码
     */
    public function updatePassword(Request $request)
    {
        $user = auth('api')->user();

        // 【安全检查】如果用户是第三方登录（没密码），禁止在这里修改密码
        if ($user->provider) {
            return response()->json([
                'error' => 'Social login users cannot change password here.'
            ], 400);
        }

        $request->validate([
            'current_password' => 'required|string',
            'new_password'     => 'required|string|min:6|confirmed', // 必须有 new_password_confirmation
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
}