<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TypeSeeder extends Seeder
{
    public function run(): void
    {
        // 使用 insertOrIgnore，如果 id 1 和 2 已经存在则自动忽略，不会报错
        DB::table('types')->insertOrIgnore([
            ['id' => 1, 'name' => 'Expense', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'name' => 'Income', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}