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
        // 0. 清理可能残留的旧表（防止 1050 表已存在报错）
        Schema::dropIfExists('permission_group_user');
        Schema::dropIfExists('permission_groups');
        Schema::dropIfExists('permission_groups_tables');

        // 1. 权限组主表
        Schema::create('permission_groups', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->text('description')->nullable();
            $table->json('permissions')->nullable(); // 存储权限节点 JSON 数组 ['expenses.view', 'expenses.create']
            $table->timestamps();
        });

        // 2. 权限组与用户的多对多关联表 (Pivot Table)
        Schema::create('permission_group_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('permission_group_id')->constrained('permission_groups')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('permission_group_user');
        Schema::dropIfExists('permission_groups');
        Schema::dropIfExists('permission_groups_tables');
    }
};