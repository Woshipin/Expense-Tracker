<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\UserController;

// 公开路由 (无需鉴权)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// 【修改】Laravel Socialite 专用的两个第三方登录路由
Route::get('/auth/{provider}', [AuthController::class, 'redirectToProvider']);
Route::get('/auth/{provider}/callback', [AuthController::class, 'handleProviderCallback']);

// 【新增】忘记密码 & 重置密码 路由
Route::post('/forgot-password', [AuthController::class, 'sendResetLinkEmail']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

// 受保护路由 (需要 JWT Token)
Route::middleware('auth:api')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/refresh', [AuthController::class, 'refresh']);

    // 【新增】Profile 相关路由
    Route::put('/profile', [ProfileController::class, 'updateProfile']);
    Route::put('/profile/password', [ProfileController::class, 'updatePassword']);

    // 【新增】用户管理路由 (仅限管理员访问)
    Route::get('/users', [UserController::class, 'index']);          // 获取用户列表 (查)
    Route::post('/users', [UserController::class, 'store']);         // 新增用户 (增)
    Route::put('/users/{id}', [UserController::class, 'update']);    // 更新用户 (改)
    Route::delete('/users/{id}', [UserController::class, 'destroy']); // 删除用户 (删)
});