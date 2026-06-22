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
        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            // 【新增】关联到 users 表
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            
            $table->string('title');
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2); 
            $table->date('date');
            $table->time('time');
            
            // 为了保证数据的绝对完整性，建议也将这两个改为外键约束
            $table->foreignId('payment_method_id')->constrained('payment_methods')->onDelete('cascade');
            $table->foreignId('category_id')->constrained('categories')->onDelete('cascade');
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
