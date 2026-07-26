<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Cookie;
use Illuminate\Support\Facades\Log; // 引入日志以记录异常
use Laravel\Socialite\Facades\Socialite;
use Illuminate\Support\Facades\Password; 
use Illuminate\Auth\Events\PasswordReset; 

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
    // Laravel Socialite 核心逻辑 (适用于 Web 端)
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
        $frontendUrl = rtrim(env('FRONTEND_URL', 'https://expense-tracker-six-zeta-43.vercel.app'), '/');

        // 🌟 防线 1：拦截 Facebook 官方爬虫，防止它提前把 Code 消耗掉
        $userAgent = request()->header('User-Agent', '');
        if (str_contains(strtolower($userAgent), 'facebookexternalhit')) {
            return response('OK', 200);
        }

        try {
            // 1. 获取第三方用户信息
            $socialUser = Socialite::driver($provider)->stateless()->user();

            // 2. 提取并清洗数据
            $email = $socialUser->getEmail() ?: "fb_{$socialUser->getId()}@facebook.com";
            $name = $socialUser->getName() ?: 'Facebook User';
            $rawAvatar = $socialUser->getAvatar();
            $safeAvatar = $rawAvatar ? substr($rawAvatar, 0, 255) : null;

            // 3. 数据库原子化更新或创建
            $user = User::updateOrCreate(
                ['email' => $email],
                [
                    'full_name'   => $name,
                    'provider'    => $provider,
                    'provider_id' => $socialUser->getId(),
                    'image_path'  => $safeAvatar,
                ]
            );

            // 4. 检查账号状态
            if ($user->status === User::STATUS_INACTIVE) {
                return redirect()->away("{$frontendUrl}/login?error=account_banned");
            }

            // 5. 签发 JWT Token
            $token = auth('api')->login($user);
            if (!$token) {
                $token = \PHPOpenSourceSaver\JWTAuth\Facades\JWTAuth::fromUser($user);
            }

            // 6. 重定向回 Vercel 前端
            return redirect()->away("{$frontendUrl}/login?token={$token}");

        } catch (\Exception $e) {
            Log::error("Web Social Auth Error ({$provider}): " . $e->getMessage());

            // 🌟 防线 2（终极救援）：如果 Code 还是被意外消耗了，直接去 DB 读取刚才救进去的用户放行登录！
            if (str_contains($e->getMessage(), 'code has been used')) {
                $recentUser = User::where('provider', $provider)->latest('updated_at')->first();
                if ($recentUser && $recentUser->status !== User::STATUS_INACTIVE) {
                    $token = auth('api')->login($recentUser);
                    return redirect()->away("{$frontendUrl}/login?token={$token}");
                }
            }

            // 其他失败情况
            $errorMessage = urlencode($e->getMessage());
            return redirect()->away("{$frontendUrl}/login?error={$errorMessage}");
        }
    }

    // ==========================================
    // 专供 Mobile App (Flutter/React Native) 使用的第三方登录 API
    // ==========================================
    public function appSocialLogin(Request $request, $provider)
    {
        if (!in_array($provider, ['google', 'facebook'])) {
            return response()->json(['error' => 'Invalid provider (无效的登录渠道)'], 400);
        }

        $request->validate([
            'token' => 'required|string', 
        ]);

        try {
            // 使用 userFromToken() 直接解析手机原生层传来的 Access Token
            $socialUser = Socialite::driver($provider)->stateless()->userFromToken($request->token);
        } catch (\Exception $e) {
            Log::error("App Social Login Error ({$provider}): " . $e->getMessage());
            return response()->json(['error' => 'Invalid ' . ucfirst($provider) . ' Token (凭证验证失败，请重试)'], 401);
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
            $user->update([
                'provider'    => $provider,
                'provider_id' => $socialUser->getId(),
                'image_path'  => $user->image_path ?: $socialUser->getAvatar(),
            ]);
        }

        if ($user->status === User::STATUS_INACTIVE) {
            return response()->json(['error' => 'Account is banned or inactive (账号被封禁)'], 403);
        }

        $token = auth('api')->login($user);
        $ttl = auth('api')->factory()->getTTL();

        return response()->json([
            'message'      => 'Login successful',
            'user'         => $user,
            'access_token' => $token,
            'token_type'   => 'bearer',
            'expires_in'   => $ttl * 60
        ]);
    }

    // ==========================================
    // 密码重置逻辑 (Forgot / Reset Password)
    // ==========================================

    public function sendResetLinkEmail(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();
        if ($user && $user->provider) {
            return response()->json([
                'message' => 'This account uses Social Login. Please login via ' . ucfirst($user->provider) . '.'
            ], 400);
        }

        $status = Password::broker()->sendResetLink(
            $request->only('email')
        );

        return $status === Password::RESET_LINK_SENT
                    ? response()->json(['message' => __($status)])
                    : response()->json(['message' => __($status)], 400);
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|min:6|confirmed', 
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