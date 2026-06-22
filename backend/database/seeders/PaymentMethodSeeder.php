<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PaymentMethodSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('payment_methods')->insert([
            // 支出渠道 (type_id = 1)
            ['user_id' => 1, 'type_id' => 1, 'name' => 'Credit Card', 'icon' => 'credit-card', 'color' => '#3b82f6', 'description' => 'Main bank credit card', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['user_id' => 1, 'type_id' => 1, 'name' => 'Cash', 'icon' => 'banknote', 'color' => '#10b981', 'description' => 'Physical cash wallet', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            
            // 收入渠道 (type_id = 2)
            ['user_id' => 1, 'type_id' => 2, 'name' => 'Bank Transfer', 'icon' => 'landmark', 'color' => '#6366f1', 'description' => 'Direct to bank account', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}