<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        DB::table('categories')->insert([
            // 支出分类 (type_id = 1)
            ['user_id' => 1, 'type_id' => 1, 'name' => 'Food & Drinks', 'icon' => 'utensils', 'color' => '#ef4444', 'description' => 'Daily meals and coffee', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['user_id' => 1, 'type_id' => 1, 'name' => 'Transport', 'icon' => 'car', 'color' => '#eab308', 'description' => 'Gas and public transit', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            
            // 收入分类 (type_id = 2)
            ['user_id' => 1, 'type_id' => 2, 'name' => 'Salary', 'icon' => 'briefcase', 'color' => '#22c55e', 'description' => 'Monthly full-time job salary', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['user_id' => 1, 'type_id' => 2, 'name' => 'Freelance', 'icon' => 'laptop', 'color' => '#8b5cf6', 'description' => 'Side hustle income', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}