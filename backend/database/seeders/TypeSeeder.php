<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TypeSeeder extends Seeder
{
    public function run(): void
    {
        // 临时关闭外键约束检查
        Schema::disableForeignKeyConstraints();
        DB::table('types')->truncate();
        Schema::enableForeignKeyConstraints(); // 重新启用
        
        DB::table('types')->insert([
            ['id' => 1, 'name' => 'Expense', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'name' => 'Income', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}