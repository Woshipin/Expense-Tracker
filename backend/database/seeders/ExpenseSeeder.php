<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Carbon\Carbon;

class ExpenseSeeder extends Seeder
{
    public function run(): void
    {
        Schema::disableForeignKeyConstraints();
        DB::table('expenses')->truncate();
        Schema::enableForeignKeyConstraints();

        DB::table('expenses')->insert([
            // 第1天（今天）
            [
                'user_id' => 1, 'category_id' => 1, 'payment_method_id' => 4,
                'title' => 'Starbucks Coffee', 'description' => 'Latte with chocolate muffin',
                'price' => 18.50, 'date' => Carbon::today()->toDateString(), 'time' => '10:15:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'user_id' => 1, 'category_id' => 1, 'payment_method_id' => 1,
                'title' => 'Dinner at Steakhouse', 'description' => 'Dinner celebration with friends',
                'price' => 150.00, 'date' => Carbon::today()->toDateString(), 'time' => '19:30:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第2天（昨天）
            [
                'user_id' => 1, 'category_id' => 2, 'payment_method_id' => 2,
                'title' => 'Shell Fuel', 'description' => 'Full tank filling',
                'price' => 95.00, 'date' => Carbon::yesterday()->toDateString(), 'time' => '08:45:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'user_id' => 1, 'category_id' => 8, 'payment_method_id' => 3,
                'title' => 'Weekly Supermarket', 'description' => 'Fruits, vegetables, and milk',
                'price' => 124.80, 'date' => Carbon::yesterday()->toDateString(), 'time' => '15:20:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第3天
            [
                'user_id' => 1, 'category_id' => 4, 'payment_method_id' => 1,
                'title' => 'Netflix Monthly Premium', 'description' => 'Automatic monthly renewal',
                'price' => 55.00, 'date' => Carbon::today()->subDays(2)->toDateString(), 'time' => '00:05:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'user_id' => 1, 'category_id' => 3, 'payment_method_id' => 1,
                'title' => 'Nike Air Sneakers', 'description' => 'Running shoes on summer sale',
                'price' => 320.00, 'date' => Carbon::today()->subDays(2)->toDateString(), 'time' => '14:10:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第4天
            [
                'user_id' => 1, 'category_id' => 5, 'payment_method_id' => 3,
                'title' => 'Electricity Bill', 'description' => 'TNB monthly payment',
                'price' => 189.20, 'date' => Carbon::today()->subDays(3)->toDateString(), 'time' => '11:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第5天
            [
                'user_id' => 1, 'category_id' => 1, 'payment_method_id' => 4,
                'title' => 'McDonad\'s Meal', 'description' => 'Double Cheeseburger set lunch',
                'price' => 22.50, 'date' => Carbon::today()->subDays(4)->toDateString(), 'time' => '12:30:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'user_id' => 1, 'category_id' => 6, 'payment_method_id' => 2,
                'title' => 'Pharmacy Medicine', 'description' => 'Cough syrup and vitamins',
                'price' => 45.00, 'date' => Carbon::today()->subDays(4)->toDateString(), 'time' => '18:15:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第6天
            [
                'user_id' => 1, 'category_id' => 4, 'payment_method_id' => 4,
                'title' => 'Cinema Tickets', 'description' => 'Avengers IMAX with popcorn',
                'price' => 48.00, 'date' => Carbon::today()->subDays(5)->toDateString(), 'time' => '20:15:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第7天
            [
                'user_id' => 1, 'category_id' => 7, 'payment_method_id' => 1,
                'title' => 'Udemy Course Purchase', 'description' => 'Laravel Next.js Web development course',
                'price' => 59.90, 'date' => Carbon::today()->subDays(6)->toDateString(), 'time' => '22:10:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第8天
            [
                'user_id' => 1, 'category_id' => 2, 'payment_method_id' => 4,
                'title' => 'Grab Car Ride', 'description' => 'Ride to airport',
                'price' => 65.00, 'date' => Carbon::today()->subDays(7)->toDateString(), 'time' => '06:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第9天
            [
                'user_id' => 1, 'category_id' => 8, 'payment_method_id' => 3,
                'title' => 'Organic Groceries Store', 'description' => 'Fresh beef and organic vegetables',
                'price' => 98.40, 'date' => Carbon::today()->subDays(8)->toDateString(), 'time' => '16:50:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第10天
            [
                'user_id' => 1, 'category_id' => 5, 'payment_method_id' => 1,
                'title' => 'Unifi Broadband WiFi', 'description' => 'Home high-speed internet plan',
                'price' => 139.00, 'date' => Carbon::today()->subDays(9)->toDateString(), 'time' => '09:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第11天
            [
                'user_id' => 1, 'category_id' => 1, 'payment_method_id' => 2,
                'title' => 'Ramen Noodles', 'description' => 'Dinner comfort food',
                'price' => 32.00, 'date' => Carbon::today()->subDays(10)->toDateString(), 'time' => '19:45:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第12天
            [
                'user_id' => 1, 'category_id' => 3, 'payment_method_id' => 1,
                'title' => 'Uniqlo Casual Shirt', 'description' => 'Cotton workwear shirt',
                'price' => 79.90, 'date' => Carbon::today()->subDays(11)->toDateString(), 'time' => '14:30:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第13天
            [
                'user_id' => 1, 'category_id' => 6, 'payment_method_id' => 1,
                'title' => 'Dental Scaling Checkup', 'description' => 'Routine scaling and polishing',
                'price' => 150.00, 'date' => Carbon::today()->subDays(12)->toDateString(), 'time' => '10:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第14天
            [
                'user_id' => 1, 'category_id' => 1, 'payment_method_id' => 4,
                'title' => 'Tealive Bubble Tea', 'description' => 'Brown sugar pearl milk tea',
                'price' => 11.50, 'date' => Carbon::today()->subDays(13)->toDateString(), 'time' => '15:10:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            [
                'user_id' => 1, 'category_id' => 7, 'payment_method_id' => 2,
                'title' => 'Novel Book', 'description' => 'Atomic Habits printed book',
                'price' => 45.00, 'date' => Carbon::today()->subDays(13)->toDateString(), 'time' => '12:00:00',
                'created_at' => now(), 'updated_at' => now()
            ],
            // 第15天
            [
                'user_id' => 1, 'category_id' => 2, 'payment_method_id' => 3,
                'title' => 'Touch \'n Go Top Up', 'description' => 'Toll card reload',
                'price' => 50.00, 'date' => Carbon::today()->subDays(14)->toDateString(), 'time' => '17:30:00',
                'created_at' => now(), 'updated_at' => now()
            ],
        ]);
    }
}