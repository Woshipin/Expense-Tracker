<?php

namespace App\Http\Controllers; 

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Cookie;
use Laravel\Socialite\Facades\Socialite; 

class AuthController extends Controller
{
    /**
     * 用户注册
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'full_name' => 'required|string|max:255',
            'email'     => 'required|string|email|max:255|unique:users',
            'password'  => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        User::create([
            'full_name' => $request->full_name,
            'email'     => $request->email,
            'password'  => Hash::make($request->password),
        ]);

        return response()->json(['message' => 'Registration successful'], 201);
    }

    /**
     * 用户登录 (普通邮箱密码)
     */
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        if (! $token = auth('api')->attempt($credentials)) {
            return response()->json(['error' => 'Invalid credentials (邮箱或密码错误)'], 401);
        }

        if (auth('api')->user()->status === User::STATUS_INACTIVE) {
            auth('api')->logout();
            return response()->json(['error' => 'Account is banned or inactive (账号被封禁或未激活)'], 403);
        }

        return $this->respondWithToken($token, 'Login successful');
    }

    /**
     * 1. 重定向用户到第三方授权页面 (Google / Facebook)
     */
    public function redirectToProvider($provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return response()->json(['error' => 'Invalid provider'], 400);
        }
        
        $driver = Socialite::driver($provider)->stateless();

        // 【新增】如果是 Google 登录，强制每次都弹出选择账号的界面
        if ($provider === 'google') {
            $driver->with(['prompt' => 'select_account']);
        }

        // 【新增】如果是 Facebook 登录，强制每次要求重新验证身份 (可选，体验更好)
        if ($provider === 'facebook') {
            $driver->with(['auth_type' => 'reauthenticate']);
        }

        return $driver->redirect();
    }

    /**
     * 2. 第三方授权成功后的回调处理
     */
    public function handleProviderCallback($provider)
    {
        try {
            $socialUser = Socialite::driver($provider)->stateless()->user();
        } catch (\Exception $e) {
            return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/login?error=social_auth_failed');
        }

        // 查找用户是否已存在（依据唯一的邮箱匹配，实现账号合并）
        $user = User::where('email', $socialUser->getEmail())->first();

        if (!$user) {
            // 【情况 A】这个邮箱从来没在我们的系统出现过 -> 完全新建一个账号
            $user = User::create([
                'full_name'   => $socialUser->getName() ?? 'User',
                'email'       => $socialUser->getEmail(),
                'password'    => null, 
                'provider'    => $provider, // 记录最初的注册来源 (google 或 facebook)
                'provider_id' => $socialUser->getId(),
                'image_path'  => $socialUser->getAvatar(),
            ]);
        } else {
            // 【情况 B】这个邮箱已经存在了（可能是以前 Register 的，也可能是其他平台登录的）
            // 我们不覆盖他的 provider，只在他没有头像的时候，帮他把第三方头像同步过来
            if (!$user->image_path) {
                $user->update([
                    'image_path' => $socialUser->getAvatar(),
                ]);
            }
            // 只要邮箱匹配，直接往下走，允许他登录旧账号！
        }

        // 检查账号状态是否被封禁
        if ($user->status === User::STATUS_INACTIVE) {
            return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/login?error=account_banned');
        }

        // 生成 JWT Token 并登录
        $token = auth('api')->login($user);
        $ttl = auth('api')->factory()->getTTL();

        $cookie = cookie(
            'jwt_token', $token, $ttl, '/', null, env('APP_ENV') === 'production', true, false, 'Lax'
        );

        // 登录成功，带着 Cookie 重定向回前端的 Dashboard
        return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/dashboard')->withCookie($cookie);
    }

    /**
     * 获取当前登录的用户信息 (Me)
     */
    public function me()
    {
        return response()->json(auth('api')->user());
    }

    /**
     * 用户登出
     */
    public function logout()
    {
        auth('api')->logout();
        $cookie = Cookie::forget('jwt_token');

        return response()->json(['message' => 'Successfully logged out'])->withCookie($cookie);
    }

    /**
     * 刷新 Token
     */
    public function refresh()
    {
        return $this->respondWithToken(auth('api')->refresh(), 'Token refreshed');
    }

    /**
     * 统一封装：将 Token 放入 HttpOnly Cookie 并返回响应
     */
    protected function respondWithToken($token, $message = 'Success')
    {
        $ttl = auth('api')->factory()->getTTL();

        $cookie = cookie(
            'jwt_token',   
            $token,        
            $ttl,          
            '/',           
            null,          
            env('APP_ENV') === 'production', 
            true,          
            false,
            'Lax'          
        );

        return response()->json([
            'message'      => $message,
            'user'         => auth('api')->user(),
            'access_token' => $token,
            'token_type'   => 'bearer',
            'expires_in'   => $ttl * 60 
        ])->withCookie($cookie);
    }
}