<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TypeSeeder extends Seeder
{
    public function run(): void
    {
        // 1. 自动删除所有不是 Expense 和 Income 的测试杂乱数据
        DB::table('types')->whereNotIn('name', ['Expense', 'Income'])->delete();

        // 2. 确保标准的 ID 1 (Expense) 和 ID 2 (Income) 存在
        DB::table('types')->insertOrIgnore([
            ['id' => 1, 'name' => 'Expense', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'name' => 'Income', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}