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
                'id'                => 1,
                'full_name'         => 'Super Admin',
                'email'             => 'superadmin@gmail.com',
                'password'          => Hash::make('Pin@776253'), // 直接填入
                'role'              => 0, // 0: SuperAdmin
                'status'            => 1, // 1: Active
                'currency'          => 'USD',
                'email_verified_at' => now(),
                'created_at'        => now(),
                'updated_at'        => now(),
            ],
            // 2. 🌟 Admin 账号 (role = 1)
            [
                'id'                => 2,
                'full_name'         => 'Admin',
                'email'             => 'admin@gmail.com',
                'password'          => Hash::make('Pin@776253'), // 直接填入
                'role'              => 1, // 1: Admin
                'status'            => 1, // 1: Active
                'currency'          => 'USD',
                'email_verified_at' => now(),
                'created_at'        => now(),
                'updated_at'        => now(),
            ],
            // 3. 🌟 Standard Basic User 普通用户账号 (role = 3)
            [
                'id'                => 3,
                'full_name'         => 'aaa',
                'email'             => 'aaa@gmail.com',
                'password'          => Hash::make('Pin@776253'), // 直接填入
                'role'              => 3, // 3: Basic User
                'status'            => 1, // 1: Active
                'currency'          => 'USD',
                'email_verified_at' => now(),
                'created_at'        => now(),
                'updated_at'        => now(),
            ],
        ];

        // 遍历并强行写入或更新数据库
        foreach ($users as $userData) {
            User::updateOrCreate(
                ['email' => $userData['email']],
                $userData
            );
        }
    }
}