<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class IncomeSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('incomes')->insert([
            [
                'user_id' => 1, 
                'category_id' => 3, // Salary
                'payment_method_id' => 3, // Bank Transfer
                'title' => 'May Full Salary', 
                'description' => 'Tech company salary',
                'price' => 10000, 
                'date' => Carbon::now()->toDateString(), 
                'time' => '09:00:00',
                'created_at' => now(), 
                'updated_at' => now()
            ],
            [
                'user_id' => 1, 
                'category_id' => 4, // Freelance
                'payment_method_id' => 3, // Bank Transfer
                'title' => 'UI Design Project', 
                'description' => 'Client payment',
                'price' => 3000, 
                'date' => Carbon::now()->toDateString(), 
                'time' => '15:45:00',
                'created_at' => now(), 
                'updated_at' => now()
            ],
        ]);
    }
}