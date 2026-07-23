<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Auth\Notifications\ResetPassword; 
use Illuminate\Support\Facades\URL; // 🌟 1. 引入 URL Facade

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // =====================================================================
        // 🌟 1. 核心修复：强制 Render 线上生产环境统一使用 HTTPS 传输协议
        // 彻底解决 Render 代理网络下 Facebook / Google OAuth 误识别为 HTTP 导致回调失败的问题！
        // =====================================================================
        if (env('APP_ENV') === 'production' || config('app.env') === 'production') {
            URL::forceScheme('https');
        }

        // =====================================================================
        // 🚀 【全新改进版】：自适应重设密码邮件生成器
        // 自动提取请求客户端的 Origin（原路径），自动判断生成 Next.js (3000/132/152) 还是 Flutter (53256) 的跳转地址！
        // =====================================================================
        ResetPassword::createUrlUsing(function (object $notifiable, string $token) {
            // 获取请求发送源（例如：http://localhost:53256 或 http://192.168.0.132:3000）
            $origin = request()->header('Origin');

            // 兼容性保护：如果是局域网物理 IP，自动为其包装上 .nip.io 绕开谷歌安全拦截规则
            if ($origin && preg_match('/192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+/', $origin)) {
                $urlParts = parse_url($origin);
                $host = $urlParts['host'];
                $port = isset($urlParts['port']) ? ':' . $urlParts['port'] : '';
                $origin = "http://{$host}.nip.io{$port}";
            }

            // 默认安全兜底
            $frontendUrl = $origin ?? env('FRONTEND_URL', 'http://localhost:3000');
            
            // 拼出给前端页面的链接，并附带 token 和 email
            return $frontendUrl . "/reset-password?token={$token}&email={$notifiable->getEmailForPasswordReset()}";
        });
    }
}