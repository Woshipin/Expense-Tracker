<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        Schema::disableForeignKeyConstraints();
        DB::table('categories')->truncate();
        Schema::enableForeignKeyConstraints();

        DB::table('categories')->insert([
            // 支出分类 (type_id = 1) [ID: 1 - 8]
            ['id' => 1, 'user_id' => 1, 'type_id' => 1, 'name' => 'Food & Drinks', 'icon' => 'utensils', 'color' => '#ef4444', 'description' => 'Meals, snacks, and drinks', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'user_id' => 1, 'type_id' => 1, 'name' => 'Transport', 'icon' => 'car', 'color' => '#eab308', 'description' => 'Gas, parking, and transit fares', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'user_id' => 1, 'type_id' => 1, 'name' => 'Shopping', 'icon' => 'shopping-bag', 'color' => '#ec4899', 'description' => 'Clothes, gadgets, and personal items', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 4, 'user_id' => 1, 'type_id' => 1, 'name' => 'Entertainment', 'icon' => 'film', 'color' => '#a855f7', 'description' => 'Movies, games, and concert tickets', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 5, 'user_id' => 1, 'type_id' => 1, 'name' => 'Utilities', 'icon' => 'home', 'color' => '#3b82f6', 'description' => 'Water, electricity, gas and internet bills', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 6, 'user_id' => 1, 'type_id' => 1, 'name' => 'Medical', 'icon' => 'heart-pulse', 'color' => '#14b8a6', 'description' => 'Medicines, clinic visits, and health checkups', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 7, 'user_id' => 1, 'type_id' => 1, 'name' => 'Education', 'icon' => 'graduation-cap', 'color' => '#6366f1', 'description' => 'Books, courses, and tutorials', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 8, 'user_id' => 1, 'type_id' => 1, 'name' => 'Groceries', 'icon' => 'shopping-cart', 'color' => '#f97316', 'description' => 'Daily supermarket essentials', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            
            // 收入分类 (type_id = 2) [ID: 9 - 12]
            ['id' => 9, 'user_id' => 1, 'type_id' => 2, 'name' => 'Salary', 'icon' => 'briefcase', 'color' => '#22c55e', 'description' => 'Monthly active salary', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 10, 'user_id' => 1, 'type_id' => 2, 'name' => 'Freelance', 'icon' => 'laptop', 'color' => '#06b6d4', 'description' => 'Side gigs and freelance payments', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 11, 'user_id' => 1, 'type_id' => 2, 'name' => 'Investments', 'icon' => 'trending-up', 'color' => '#10b981', 'description' => 'Stocks dividends, and crypto returns', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 12, 'user_id' => 1, 'type_id' => 2, 'name' => 'Others', 'icon' => 'gift', 'color' => '#ec4899', 'description' => 'Gifts, second-hand sales, and refunds', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}