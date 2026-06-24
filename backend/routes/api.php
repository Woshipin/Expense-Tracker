<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\PaymentMethodController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\IncomeController;
use App\Http\Controllers\CalendarController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\TypeController;

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

    // 支付方式管理路由 (显式单条配置)
    Route::get('/payment-methods', [PaymentMethodController::class, 'index']);          // 获取/搜索列表
    Route::post('/payment-methods', [PaymentMethodController::class, 'store']);         // 新增
    Route::put('/payment-methods/{id}', [PaymentMethodController::class, 'update']);    // 修改
    Route::delete('/payment-methods/{id}', [PaymentMethodController::class, 'destroy']); // 删除

    // Categories 管理路由
    Route::get('/categories', [CategoryController::class, 'index']);
    Route::post('/categories', [CategoryController::class, 'store']);
    Route::put('/categories/{id}', [CategoryController::class, 'update']);
    Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

    // Expense 管理路由
    Route::get('/expenses', [ExpenseController::class, 'index']);
    Route::post('/expenses', [ExpenseController::class, 'store']);
    Route::put('/expenses/{id}', [ExpenseController::class, 'update']);
    Route::delete('/expenses/{id}', [ExpenseController::class, 'destroy']);

    // Types 管理路由
    Route::get('/types', [TypeController::class, 'index']);
    Route::post('/types', [TypeController::class, 'store']);
    Route::get('/types/{id}', [TypeController::class, 'show']);
    Route::put('/types/{id}', [TypeController::class, 'update']);
    Route::delete('/types/{id}', [TypeController::class, 'destroy']);

    // Income 管理路由
    Route::get('/incomes', [IncomeController::class, 'index']);
    Route::post('/incomes', [IncomeController::class, 'store']);
    Route::put('/incomes/{id}', [IncomeController::class, 'update']);
    Route::delete('/incomes/{id}', [IncomeController::class, 'destroy']);

    // 【新增】Calendar 路由
    Route::get('/calendar', [CalendarController::class, 'index']);

    // 【新增】Budget 路由
    Route::get('/budget/list',[BudgetController::class,'index']);
    Route::post('/budget/create',[BudgetController::class,'store']);
    Route::get('/budget/detail/{id}',[BudgetController::class,'show']);
    Route::post('/budget/update/{id}',[BudgetController::class,'update']);
    Route::delete('/budget/delete/{id}',[BudgetController::class,'destroy']);
});