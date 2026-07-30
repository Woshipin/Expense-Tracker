<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            // 1. 🌟 Super Admin 账号 (role = 0)
            [
                'full_name'         => 'Super Admin',
                'email'             => 'superadmin@gmail.com',
                'password'          => Hash::make('Pin@776253'),
                'role'              => 0, // 0: SuperAdmin
                'status'            => 1, // 1: Active
                'currency'          => 'USD',
                'email_verified_at' => now(),
            ],
            // 2. 🌟 Admin 账号 (role = 1)
            [
                'full_name'         => 'Admin',
                'email'             => 'admin@gmail.com',
                'password'          => Hash::make('Pin@776253'),
                'role'              => 1, // 1: Admin
                'status'            => 1, // 1: Active
                'currency'          => 'USD',
                'email_verified_at' => now(),
            ],
            // 3. 🌟 Standard Basic User 普通用户账号 (role = 3)
            [
                'full_name'         => 'aaa',
                'email'             => 'aaa@gmail.com',
                'password'          => Hash::make('Pin@776253'),
                'role'              => 3, // 3: Basic User
                'status'            => 1, // 1: Active
                'currency'          => 'USD',
                'email_verified_at' => now(),
            ],
        ];

        // 按 email 匹配：如果账号存在则更新基础字段，不存在则自增创建（不写死 ID，绝不引发 1062 主键冲突）
        foreach ($users as $userData) {
            User::updateOrCreate(
                ['email' => $userData['email']],
                $userData
            );
        }
    }
}