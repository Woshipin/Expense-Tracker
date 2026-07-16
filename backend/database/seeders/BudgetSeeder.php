<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Carbon\Carbon;

class BudgetSeeder extends Seeder
{
    public function run(): void
    {
        // 1. 临时关闭外键约束检查，清空旧的预算数据，防止重复填充报错
        Schema::disableForeignKeyConstraints();
        DB::table('budgets')->truncate();
        Schema::enableForeignKeyConstraints();

        $currentYear = Carbon::now()->year;
        $budgets = [];

        // 2. 定义核心支出分类（Category ID）及其每月的标准预算额度
        // ID 对应 CategorySeeder 中设置的支出分类
        $budgetTemplates = [
            1 => 600.00,  // Food & Drinks
            2 => 200.00,  // Transport
            3 => 150.00,  // Shopping
            5 => 300.00,  // Utilities
            8 => 400.00,  // Groceries
        ];

        // 3. 循环 1 至 12 月，为上述分类生成一整年的月度预算
        for ($month = 1; $month <= 12; $month++) {
            foreach ($budgetTemplates as $categoryId => $amount) {
                $budgets[] = [
                    'user_id' => 1,
                    'category_id' => $categoryId,
                    'amount' => $amount,
                    'month' => $month,
                    'year' => $currentYear,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        // 4. 执行批量插入
        DB::table('budgets')->insert($budgets);
    }
}