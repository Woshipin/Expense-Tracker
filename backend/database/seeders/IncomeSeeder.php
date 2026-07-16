<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Carbon\Carbon;

class IncomeSeeder extends Seeder
{
    public function run(): void
    {
        Schema::disableForeignKeyConstraints();
        DB::table('incomes')->truncate();
        Schema::enableForeignKeyConstraints();

        DB::table('incomes')->insert([
            // 第1天（今天）
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 5,
                'title' => 'Landing Page Project', 'description' => 'Client final payment for UI development',
                'price' => 1500.00, 'date' => Carbon::today()->toDateString(), 'time' => '16:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第2天（昨天）
            [
                'user_id' => 1, 'category_id' => 11, 'payment_method_id' => 5,
                'title' => 'Stock Dividends Payout', 'description' => 'Public Bank quarterly stock payout',
                'price' => 220.00, 'date' => Carbon::yesterday()->toDateString(), 'time' => '09:30:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第3天
            [
                'user_id' => 1, 'category_id' => 12, 'payment_method_id' => 6,
                'title' => 'Sold Old Office Chair', 'description' => 'Carousell second hand buyer deal',
                'price' => 180.00, 'date' => Carbon::today()->subDays(2)->toDateString(), 'time' => '13:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第4天
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 7,
                'title' => 'Logo Design Commission', 'description' => 'Client initial deposit via PayPal',
                'price' => 450.00, 'date' => Carbon::today()->subDays(3)->toDateString(), 'time' => '22:15:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第5天
            [
                'user_id' => 1, 'category_id' => 9, 'payment_method_id' => 5,
                'title' => 'Regular Full Salary', 'description' => 'Monthly tech job salary bank in',
                'price' => 10000.00, 'date' => Carbon::today()->subDays(4)->toDateString(), 'time' => '08:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第6天
            [
                'user_id' => 1, 'category_id' => 12, 'payment_method_id' => 5,
                'title' => 'Tax Return Refund', 'description' => 'LHDN government tax return payment',
                'price' => 1250.00, 'date' => Carbon::today()->subDays(5)->toDateString(), 'time' => '11:45:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第7天
            [
                'user_id' => 1, 'category_id' => 11, 'payment_method_id' => 5,
                'title' => 'Crypto Trading Returns', 'description' => 'Bitcoin trade cash-out',
                'price' => 890.00, 'date' => Carbon::today()->subDays(6)->toDateString(), 'time' => '14:20:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第8天
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 5,
                'title' => 'Consulting Session Fee', 'description' => '2 hours system design review consultation',
                'price' => 300.00, 'date' => Carbon::today()->subDays(7)->toDateString(), 'time' => '10:30:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第9天
            [
                'user_id' => 1, 'category_id' => 12, 'payment_method_id' => 6,
                'title' => 'Birthday Cash Gift', 'description' => 'Cash gift from parents',
                'price' => 500.00, 'date' => Carbon::today()->subDays(8)->toDateString(), 'time' => '12:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第10天
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 7,
                'title' => 'Bug Bounty Reward', 'description' => 'Reported minor security vulnerability on platform',
                'price' => 600.00, 'date' => Carbon::today()->subDays(9)->toDateString(), 'time' => '23:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第11天
            [
                'user_id' => 1, 'category_id' => 11, 'payment_method_id' => 5,
                'title' => 'Fixed Deposit Interest', 'description' => 'Maybank regular fixed deposit auto interest',
                'price' => 115.50, 'date' => Carbon::today()->subDays(10)->toDateString(), 'time' => '09:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第12天
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 5,
                'title' => 'SEO Writing retainer', 'description' => 'Monthly technical content contract payment',
                'price' => 1200.00, 'date' => Carbon::today()->subDays(11)->toDateString(), 'time' => '15:30:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第13天
            [
                'user_id' => 1, 'category_id' => 12, 'payment_method_id' => 6,
                'title' => 'Sold Spare Monitor', 'description' => 'Dell 24 inch screen second-hand deal',
                'price' => 250.00, 'date' => Carbon::today()->subDays(12)->toDateString(), 'time' => '18:10:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第14天
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 5,
                'title' => 'Website Maintenance Gigs', 'description' => 'E-commerce plugin fix service',
                'price' => 450.00, 'date' => Carbon::today()->subDays(13)->toDateString(), 'time' => '10:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第15天
            [
                'user_id' => 1, 'category_id' => 11, 'payment_method_id' => 7,
                'title' => 'Affiliate Marketing Bonus', 'description' => 'Hosting referral link program payment',
                'price' => 150.00, 'date' => Carbon::today()->subDays(14)->toDateString(), 'time' => '17:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第16天
            [
                'user_id' => 1, 'category_id' => 9, 'payment_method_id' => 5,
                'title' => 'Quarterly Performance Bonus', 'description' => 'Company KPI bonus payout',
                'price' => 3500.00, 'date' => Carbon::today()->subDays(15)->toDateString(), 'time' => '08:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第17天
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 5,
                'title' => 'Web App Translation', 'description' => 'English to Chinese localization work',
                'price' => 800.00, 'date' => Carbon::today()->subDays(16)->toDateString(), 'time' => '11:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第18天
            [
                'user_id' => 1, 'category_id' => 12, 'payment_method_id' => 6,
                'title' => 'Internet Provider Rebate', 'description' => 'Overcharged balance refund from ISP',
                'price' => 88.00, 'date' => Carbon::today()->subDays(17)->toDateString(), 'time' => '14:50:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第19天
            [
                'user_id' => 1, 'category_id' => 10, 'payment_method_id' => 7,
                'title' => 'Custom Discord Bot Gigs', 'description' => 'Configured moderation bot for client server',
                'price' => 200.00, 'date' => Carbon::today()->subDays(18)->toDateString(), 'time' => '19:15:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第20天
            [
                'user_id' => 1, 'category_id' => 11, 'payment_method_id' => 5,
                'title' => 'Gold Investment Return', 'description' => 'Paper gold trading program profit out',
                'price' => 420.00, 'date' => Carbon::today()->subDays(19)->toDateString(), 'time' => '16:40:00',
                'created_at' => now(), 'updated_at' => now()
            ],
        ]);
    }
}