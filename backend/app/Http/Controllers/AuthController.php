<?php

namespace App\Http\Controllers; // 注意这里的命名空间，保持和你现在的一致

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Cookie;
use Laravel\Socialite\Facades\Socialite; // 【新增】引入 Socialite

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
     * 用户登录
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

    // ==========================================
    // 【修改】Laravel Socialite 核心逻辑开始
    // ==========================================

    /**
     * 1. 重定向用户到第三方授权页面 (Google / Facebook)
     */
    public function redirectToProvider($provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return response()->json(['error' => 'Invalid provider'], 400);
        }
        // stateless() 是 API 专用的，不依赖 Session
        return Socialite::driver($provider)->stateless()->redirect();
    }

    /**
     * 2. 第三方授权成功后的回调处理
     */
    public function handleProviderCallback($provider)
    {
        try {
            $socialUser = Socialite::driver($provider)->stateless()->user();
        } catch (\Exception $e) {
            // 如果用户拒绝授权或出错，重定向回前端登录页并带上错误参数
            return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/login?error=social_auth_failed');
        }

        // 查找用户是否已存在
        $user = User::where('email', $socialUser->getEmail())->first();

        if (!$user) {
            // 用户不存在，自动注册
            $user = User::create([
                'full_name'   => $socialUser->getName() ?? 'User',
                'email'       => $socialUser->getEmail(),
                'password'    => null, 
                'provider'    => $provider,
                'provider_id' => $socialUser->getId(),
                'image_path'  => $socialUser->getAvatar(),
            ]);
        } else {
            // 用户已存在，更新 provider 信息
            if (!$user->provider) {
                $user->update([
                    'provider'    => $provider,
                    'provider_id' => $socialUser->getId(),
                ]);
            }
        }

        // 检查账号状态是否被封禁
        if ($user->status === User::STATUS_INACTIVE) {
            return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/login?error=account_banned');
        }

        // 生成 JWT Token
        $token = auth('api')->login($user);
        $ttl = auth('api')->factory()->getTTL();

        // 创建 HttpOnly Cookie
        $cookie = cookie(
            'jwt_token', $token, $ttl, '/', null, env('APP_ENV') === 'production', true, false, 'Lax'
        );

        // 【关键】登录成功，带着 Cookie 重定向回前端的 Dashboard
        return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/dashboard')->withCookie($cookie);
    }

    // ==========================================
    // Laravel Socialite 核心逻辑结束
    // ==========================================

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