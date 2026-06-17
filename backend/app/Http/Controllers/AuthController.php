<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Cookie;
use Laravel\Socialite\Facades\Socialite;
use Illuminate\Support\Facades\Password; // 【新增】用于密码重置
use Illuminate\Auth\Events\PasswordReset; // 【新增】用于触发密码重置成功事件

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

        // 获取前端传来的 rememberMe 参数
        $remember = $request->boolean('rememberMe');

        return $this->respondWithToken($token, 'Login successful', $remember);
    }

    // ==========================================
    // Laravel Socialite 核心逻辑开始
    // ==========================================

    public function redirectToProvider($provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return response()->json(['error' => 'Invalid provider'], 400);
        }
        
        $driver = Socialite::driver($provider)->stateless();

        // 强制每次弹出选择账号
        if ($provider === 'google') {
            $driver->with(['prompt' => 'select_account']);
        }
        // 强制 Facebook 重新验证
        if ($provider === 'facebook') {
            $driver->with(['auth_type' => 'reauthenticate']);
        }

        return $driver->redirect();
    }

    public function handleProviderCallback($provider)
    {
        try {
            $socialUser = Socialite::driver($provider)->stateless()->user();
        } catch (\Exception $e) {
            return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/login?error=social_auth_failed');
        }

        $user = User::where('email', $socialUser->getEmail())->first();

        if (!$user) {
            $user = User::create([
                'full_name'   => $socialUser->getName() ?? 'User',
                'email'       => $socialUser->getEmail(),
                'password'    => null, 
                'provider'    => $provider,
                'provider_id' => $socialUser->getId(),
                'image_path'  => $socialUser->getAvatar(),
            ]);
        } else {
            if (!$user->image_path) {
                $user->update([
                    'image_path' => $socialUser->getAvatar(),
                ]);
            }
        }

        if ($user->status === User::STATUS_INACTIVE) {
            return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/login?error=account_banned');
        }

        $token = auth('api')->login($user);
        $ttl = auth('api')->factory()->getTTL();

        $cookie = cookie(
            'jwt_token', $token, $ttl, '/', null, env('APP_ENV') === 'production', true, false, 'Lax'
        );

        return redirect(env('FRONTEND_URL', 'http://localhost:3000') . '/dashboard')->withCookie($cookie);
    }

    // ==========================================
    // 密码重置逻辑 (Forgot / Reset Password)
    // ==========================================

    /**
     * 发送重置密码邮件
     */
    public function sendResetLinkEmail(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        // 检查该邮箱是否是第三方快捷登录（没密码）的用户，防止他们误操作
        $user = User::where('email', $request->email)->first();
        if ($user && $user->provider) {
            return response()->json([
                'message' => 'This account uses Social Login. Please login via ' . ucfirst($user->provider) . '.'
            ], 400);
        }

        // 调用 Laravel 底层 Broker 发送带 Token 的邮件
        $status = Password::broker()->sendResetLink(
            $request->only('email')
        );

        return $status === Password::RESET_LINK_SENT
                    ? response()->json(['message' => __($status)])
                    : response()->json(['message' => __($status)], 400);
    }

    /**
     * 执行密码重置
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|min:6|confirmed', // 要求前端必须传 password_confirmation
        ]);

        $status = Password::broker()->reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->forceFill([
                    'password' => Hash::make($password)
                ])->save();

                event(new PasswordReset($user));
            }
        );

        return $status === Password::PASSWORD_RESET
                    ? response()->json(['message' => __($status)])
                    : response()->json(['message' => __($status)], 400);
    }

    // ==========================================
    // 用户信息与鉴权
    // ==========================================

    public function me()
    {
        return response()->json(auth('api')->user());
    }

    public function logout()
    {
        auth('api')->logout();
        $cookie = Cookie::forget('jwt_token');

        return response()->json(['message' => 'Successfully logged out'])->withCookie($cookie);
    }

    public function refresh()
    {
        return $this->respondWithToken(auth('api')->refresh(), 'Token refreshed');
    }

    protected function respondWithToken($token, $message = 'Success', $remember = false)
    {
        $ttl = auth('api')->factory()->getTTL();

        if ($remember) {
            $ttl = 43200; // 30天
        }

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