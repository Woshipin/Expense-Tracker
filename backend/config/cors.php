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

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    // 'allowed_origins' => ['*'],

    // 【修改】将原来的 ['*'] 改为你的 Next.js 前端地址。
    // 原因：当 supports_credentials 设置为 true 时，浏览器出于安全要求，不允许 allowed_origins 为通配符 '*'。
    // 必须明确指定允许跨域的域名（如果你部署到线上环境，记得把线上的域名也加到这个数组里）。
    'allowed_origins' => ['http://localhost:3000'],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // 'supports_credentials' => false,

    // 【修改】将原来的 false 改为 true。
    // 原因：因为我们要通过 HttpOnly Cookie 传递 JWT Token。
    // 只有把这个设为 true，前端 axios 请求（开启 withCredentials 后）才能成功带上 Cookie 与后端通信。
    'supports_credentials' => true,

];
