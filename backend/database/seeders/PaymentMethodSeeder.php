<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class PaymentMethodSeeder extends Seeder
{
    public function run(): void
    {
        Schema::disableForeignKeyConstraints();
        DB::table('payment_methods')->truncate();
        Schema::enableForeignKeyConstraints();

        DB::table('payment_methods')->insert([
            // 支出渠道 (type_id = 1) [ID: 1 - 4]
            ['id' => 1, 'user_id' => 1, 'type_id' => 1, 'name' => 'Credit Card', 'icon' => 'credit-card', 'color' => '#3b82f6', 'description' => 'Bank credit card', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'user_id' => 1, 'type_id' => 1, 'name' => 'Cash', 'icon' => 'banknote', 'color' => '#10b981', 'description' => 'Physical wallet cash', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 3, 'user_id' => 1, 'type_id' => 1, 'name' => 'Debit Card', 'icon' => 'wallet', 'color' => '#06b6d4', 'description' => 'Direct debit card', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 4, 'user_id' => 1, 'type_id' => 1, 'name' => 'E-Wallet', 'icon' => 'smartphone', 'color' => '#f59e0b', 'description' => 'Mobile e-wallet apps', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            
            // 收入渠道 (type_id = 2) [ID: 5 - 7]
            ['id' => 5, 'user_id' => 1, 'type_id' => 2, 'name' => 'Bank Transfer', 'icon' => 'landmark', 'color' => '#6366f1', 'description' => 'Direct to bank account', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 6, 'user_id' => 1, 'type_id' => 2, 'name' => 'Cash Deposit', 'icon' => 'safe', 'color' => '#10b981', 'description' => 'Direct cash deposit', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 7, 'user_id' => 1, 'type_id' => 2, 'name' => 'PayPal', 'icon' => 'paypal', 'color' => '#2563eb', 'description' => 'Online payment platform', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}