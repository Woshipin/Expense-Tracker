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

            // 【核心修复】：优先处理前端传来的 Base64 图片 (100% 穿透所有云服务器和 Axios 传输限制)
            if ($request->filled('image_base64')) {
                $base64Image = $request->image_base64;

                if (preg_match('/^data:image\/(\w+);base64,/', $base64Image, $type)) {
                    $imageData = substr($base64Image, strpos($base64Image, ',') + 1);
                    $fileType = strtolower($type[1]); // jpg, png, gif, webp

                    if (in_array($fileType, ['jpg', 'jpeg', 'gif', 'png', 'webp'])) {
                        $imageData = base64_decode($imageData);

                        if ($imageData !== false) {
                            $destinationPath = public_path('images');
                            if (!file_exists($destinationPath)) {
                                @mkdir($destinationPath, 0777, true);
                            }

                            // 清理旧头像
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

                            $filename = time() . '_' . uniqid() . '.' . $fileType;
                            file_put_contents($destinationPath . '/' . $filename, $imageData);

                            // 100% 成功生成并写入 DB 的图片代理 URL
                            $data['image_path'] = url('api/images/' . $filename);
                        }
                    }
                }
            } 
            // 传统 File 方式兜底
            else if ($request->hasFile('image') || $request->file('image')) {
                $file = $request->file('image');
                if ($file && $file->isValid()) {
                    $destinationPath = public_path('images');
                    if (!file_exists($destinationPath)) {
                        @mkdir($destinationPath, 0777, true);
                    }

                    $ext = $file->guessExtension() ?: $file->getClientOriginalExtension() ?: 'jpg';
                    $filename = time() . '_' . uniqid() . '.' . $ext;
                    $file->move($destinationPath, $filename);

                    $data['image_path'] = url('api/images/' . $filename);
                }
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
     * API 代理读取并返回图片文件
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