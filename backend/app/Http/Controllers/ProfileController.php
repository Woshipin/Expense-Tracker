<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    /**
     * 更新用户基本资料 (姓名, 邮箱)
     */
    public function updateProfile(Request $request)
    {
        $user = auth('api')->user();

        $request->validate([
            'full_name' => 'required|string|max:255',
            // 验证邮箱格式，且确保邮箱唯一（排除当前用户自己的邮箱）
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
        ]);

        $user->update([
            'full_name' => $request->full_name,
            'email'     => $request->email,
        ]);

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