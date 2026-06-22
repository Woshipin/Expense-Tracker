<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); 
            
            // 【新增】关联到 types 表。
            // 注意：有些支付方式(如银行卡)既能支出也能收入。如果你想让它通用，可以把 constrained 换成 nullable()，但这里按照你的要求加上了 type。
            $table->foreignId('type_id')->constrained('types')->onDelete('cascade'); 

            $table->string('name'); 
            
            // 【新增】图标和颜色
            $table->string('icon')->nullable(); // 例如: 'fa-solid fa-credit-card'
            $table->string('color')->nullable(); // 例如: '#FF5733'
            
            $table->text('description')->nullable();
            $table->unsignedTinyInteger('status')->default(1); // ('0:Inactive, 1:Active');
            $table->timestamps();

            // 联合唯一索引：同一个用户在同一个 Type 下，不能创建同名的支付方式
            $table->unique(['user_id', 'type_id', 'name']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_methods');
    }
};
