<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie', 'images/*', 'storage/*'],

    'allowed_methods' => ['*'],

    // 'allowed_origins' => ['*'],

    // 【修改】在此处加入您的 Vercel 线上前端域名支持。同时保留您原有的全部本地/局域网联调配置。
    'allowed_origins' => [
        // 动态读取 Railway 上的 FRONTEND_URL 环境变量，方便后续迁移或修改域名
        env('FRONTEND_URL', 'http://localhost:3000'), 
        
        // 显式硬编码您的 Vercel 生产环境域名，确保线上环境 100% 畅通
        'https://expense-tracker-six-zeta-43.vercel.app', 

        'http://localhost:3000',
        'http://127.0.0.1:3000',       
        
        // 【自适应局域网域名，防止 Cookie 跨域丢失】
        'http://192.168.0.152.nip.io:3000',
        'http://192.168.0.132.nip.io:3000',
        'http://10.200.242.154.nip.io:3000',

        // (备用纯 IP 配置)
        'http://192.168.0.152:3000',   
        'http://192.168.0.132:3000',   
        'http://10.200.242.154:3000',  

        'http://localhost',            
        'https://localhost',           
        'http://localhost:8080', 
    ],

    // 智能正则匹配：允许 Flutter Web 调试时产生的随机端口 (如 localhost:53806)
    'allowed_origins_patterns' => [
        '#^http://localhost:\d+$#',
        '#^http://127\.0\.0\.1:\d+$#'
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // 'supports_credentials' => false,

    // 【保持 true】因为我们要通过 HttpOnly Cookie 传递 JWT Token。
    // 只有把这个设为 true，前端 axios 请求（开启 withCredentials 后）才能成功带上 Cookie 与后端通信。
    'supports_credentials' => true,

];
