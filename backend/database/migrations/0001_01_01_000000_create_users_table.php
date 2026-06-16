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
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('full_name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            
            // 【修改】因为社交登录没有密码，所以设为 nullable()
            $table->string('password')->nullable(); 
            
            // 【新增】第三方登录所需字段
            $table->string('provider')->nullable()->comment('google, facebook 等');
            $table->string('provider_id')->nullable()->comment('第三方平台提供的唯一ID');

            // --- 角色与状态 ---
            $table->unsignedTinyInteger('role')->default(3)->comment('0:SuperAdmin, 1:Admin, 2:Premium, 3:Basic');
            $table->unsignedTinyInteger('status')->default(1)->comment('0:Inactive, 1:Active');
            
            // --- 附加功能字段 ---
            $table->string('currency', 3)->default('USD')->comment('默认记账货币');
            $table->string('image_path')->nullable()->comment('用户头像/图片路径');
            
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });

        // 密码重置表 (保留以备后用)
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        // Session 表 (虽然你用 JWT + Cookie，但保留它以防未来需要)
        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
