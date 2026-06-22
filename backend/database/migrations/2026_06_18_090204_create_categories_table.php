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
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            
            // 【新增】关联到 types 表 (Expense / Income)
            $table->foreignId('type_id')->constrained('types')->onDelete('cascade'); 
            
            $table->string('name'); 
            
            // 【新增】图标和颜色
            $table->string('icon')->nullable(); // 例如: 'fa-solid fa-utensils'
            $table->string('color')->nullable(); // 例如: '#FF5733'
            
            $table->text('description')->nullable();
            $table->unsignedTinyInteger('status')->default(1); // ('0:Inactive, 1:Active');
            $table->timestamps();

            // 联合唯一索引：同一个用户在"同一个 Type (收/支)"下，不能创建同名的分类
            $table->unique(['user_id', 'type_id', 'name']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
