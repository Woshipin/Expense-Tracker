<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            TypeSeeder::class,           // 第一步：写入基础收支类型 (Type ID: 1, 2)
            UserSeeder::class,           // 第二步：写入默认用户 (User ID: 1)
            CategorySeeder::class,       // 第三步：写入分类，需要依赖 User ID 和 Type ID
            PaymentMethodSeeder::class,  // 第四步：写入支付方式，同样依赖 User ID 和 Type ID
            ExpenseSeeder::class,        // 第五步：写入开销，依赖前面所有的 ID
            IncomeSeeder::class,         // 第六步：写入收入，依赖前面所有的 ID
        ]);
    }
}
