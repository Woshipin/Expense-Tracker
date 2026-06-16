<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // 【修改】直接引入我们将要创建的中间件类
        $middleware->prepend(\App\Http\Middleware\JwtCookieToHeader::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
