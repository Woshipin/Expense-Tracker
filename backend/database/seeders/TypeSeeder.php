<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TypeSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('types')->insert([
            ['id' => 1, 'name' => 'Expense', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
            ['id' => 2, 'name' => 'Income', 'status' => 1, 'created_at' => now(), 'updated_at' => now()],
        ]);
    }
}