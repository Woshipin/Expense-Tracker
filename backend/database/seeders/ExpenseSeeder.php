<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ExpenseSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('expenses')->insert([
            [
                'user_id' => 1, 
                'category_id' => 1, // Food & Drinks
                'payment_method_id' => 1, // Credit Card
                'title' => 'Dinner with friends', 
                'description' => 'Steakhouse dinner',
                'price' => 150, 
                'date' => Carbon::now()->toDateString(), 
                'time' => '19:30:00',
                'created_at' => now(), 
                'updated_at' => now()
            ],
            [
                'user_id' => 1, 
                'category_id' => 2, // Transport
                'payment_method_id' => 2, // Cash
                'title' => 'Gas Station', 
                'description' => 'Full tank',
                'price' => 100, 
                'date' => Carbon::now()->toDateString(), 
                'time' => '08:15:00',
                'created_at' => now(), 
                'updated_at' => now()
            ],
        ]);
    }
}