<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Auth\Notifications\ResetPassword; // 【新增这一行】

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
        // 【新增】自定义重置密码邮件里的链接，指向 Next.js 前端
        ResetPassword::createUrlUsing(function (object $notifiable, string $token) {
            $frontendUrl = env('FRONTEND_URL', 'http://localhost:3000');
            // 拼出给前端页面的链接，并附带 token 和 email
            return $frontendUrl . "/reset-password?token={$token}&email={$notifiable->getEmailForPasswordReset()}";
        });
    }
}
