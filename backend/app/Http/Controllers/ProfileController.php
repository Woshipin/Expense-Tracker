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
            'email'     => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'image'     => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120', 
        ]);

        try {
            $data = [
                'full_name' => $request->full_name,
                'email'     => $request->email,
            ];

            // 彻底兼容 $request->file('image') 多种解析方式
            $file = $request->file('image');
            if ($file && $file->isValid()) {
                $destinationPath = public_path('images');
                if (!file_exists($destinationPath)) {
                    @mkdir($destinationPath, 0777, true);
                }

                // 安全清空旧的本地文件
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

                $ext = $file->guessExtension() ?: $file->getClientOriginalExtension() ?: 'jpg';
                $filename = time() . '_' . uniqid() . '.' . $ext;
                $file->move($destinationPath, $filename);

                // 生成 api/images/ 存储路径 URL
                $data['image_path'] = url('api/images/' . $filename);
            }

            // 更新数据库
            $user->update($data);
            $freshUser = $user->fresh();

            return response()->json([
                'message' => 'Profile updated successfully',
                'user'    => $freshUser
            ]);

        } catch (\Exception $e) {
            Log::error('Profile Update Fatal Error: ' . $e->getMessage());
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

        if ($user->provider) {
            return response()->json([
                'error' => 'Social login users cannot change password here.'
            ], 400);
        }

        $request->validate([
            'current_password' => 'required|string',
            'new_password'     => 'required|string|min:6|confirmed',
        ]);

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'errors' => ['current_password' => ['The current password is incorrect.']]
            ], 422);
        }

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