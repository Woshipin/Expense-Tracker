<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['id' => 1], // 强制指定 ID 为 1
            [
                // 【修改这里】：将 'name' 改为 'full_name' 匹配你的表结构
                'full_name' => 'Pin', 
                'email' => 'ahpin7762@gmail.com',
                'password' => Hash::make('Pin@776253'), // 默认密码
                'role' => 0, // 0 对应你的迁移文件注释：SuperAdmin
                'status' => 1,
                'email_verified_at' => now(),
            ]
        );
    }
}