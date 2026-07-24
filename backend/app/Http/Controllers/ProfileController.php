<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
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
            'full_name'    => 'required|string|max:255',
            'email'        => ['required', 'string', 'email', 'max:255', Rule::unique('users')->ignore($user->id)],
            'image_base64' => 'nullable|string', 
            'image'        => 'nullable',
        ]);

        try {
            $data = [
                'full_name' => $request->full_name,
                'email'     => $request->email,
            ];

            // ==========================================
            // 【终极修复】：使用 Laravel Storage 处理文件
            // ==========================================
            $newFilename = null;

            // 1. 处理前端传来的 Base64 图片
            if ($request->filled('image_base64')) {
                $base64Image = $request->image_base64;

                if (preg_match('/^data:image\/(\w+);base64,/', $base64Image, $type)) {
                    $imageData = substr($base64Image, strpos($base64Image, ',') + 1);
                    $fileType = strtolower($type[1]);

                    if (in_array($fileType, ['jpg', 'jpeg', 'gif', 'png', 'webp'])) {
                        $imageData = base64_decode($imageData);

                        if ($imageData !== false) {
                            $newFilename = time() . '_' . uniqid() . '.' . $fileType;
                            // 使用 Storage 直接强力写入 storage/app/public/images/，自动创建目录
                            Storage::disk('public')->put('images/' . $newFilename, $imageData);
                        }
                    }
                }
            } 
            // 2. 传统 File 方式兜底
            else if ($request->hasFile('image') || $request->file('image')) {
                $file = $request->file('image');
                if ($file && $file->isValid()) {
                    $ext = $file->guessExtension() ?: $file->getClientOriginalExtension() ?: 'jpg';
                    $newFilename = time() . '_' . uniqid() . '.' . $ext;
                    
                    // 读取文件内容并写入 Storage
                    Storage::disk('public')->put('images/' . $newFilename, file_get_contents($file->getRealPath()));
                }
            }

            // 如果成功保存了新图片，执行旧图片清理和 URL 更新
            if ($newFilename) {
                // 安全清理旧头像 (通过正则匹配文件名)
                if ($user->image_path) {
                    $parsedPath = parse_url($user->image_path, PHP_URL_PATH);
                    if ($parsedPath) {
                        $oldFilename = basename($parsedPath);
                        // 如果旧文件存在于 Storage 中，删除它
                        if (Storage::disk('public')->exists('images/' . $oldFilename)) {
                            Storage::disk('public')->delete('images/' . $oldFilename);
                        }
                    }
                }

                // 保存 API 代理图片地址
                $data['image_path'] = url('api/images/' . $newFilename);
            }

            // 强行更新数据库
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
     * API 代理读取并返回图片文件 (自动从 Storage 抓取)
     */
    public function serveImage($filename)
    {
        // 尝试从 Storage 中获取文件
        if (Storage::disk('public')->exists('images/' . $filename)) {
            $path = Storage::disk('public')->path('images/' . $filename);
            return response()->file($path);
        }

        // 兜底检查旧的 public/images 目录
        $oldPath = public_path('images/' . $filename);
        if (file_exists($oldPath)) {
            return response()->file($oldPath);
        }

        abort(404);
    }
}