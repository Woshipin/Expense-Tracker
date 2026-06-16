<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\SoftDeletes; // 【新增】引入软删除
use PHPOpenSourceSaver\JWTAuth\Contracts\JWTSubject;    // 【新增】引入 JWT 接口

class User extends Authenticatable implements JWTSubject // 【新增】实现 JWT 接口
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, SoftDeletes; // 【新增】加入 SoftDeletes

    // ==========================================
    // 角色常量定义 (数字越小，权限越大)
    // ==========================================
    public const ROLE_SUPER_ADMIN = 0;
    public const ROLE_ADMIN       = 1;
    public const ROLE_PREMIUM     = 2;
    public const ROLE_BASIC       = 3;

    // ==========================================
    // 状态常量定义
    // ==========================================
    public const STATUS_INACTIVE = 0;
    public const STATUS_ACTIVE   = 1;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'full_name', // 将 name 改为了 full_name
        'email',
        'password',
        'role',      // 新增
        'status',    // 新增
        'currency',  // 新增
        'image_path',// 新增
        'provider',    // 【新增】允许赋值
        'provider_id', // 【新增】允许赋值
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
            'role'              => 'integer', // 【新增】确保查出来是整数
            'status'            => 'integer', // 【新增】确保查出来是整数
        ];
    }

    // ==========================================
    // JWT 接口必须实现的两个方法
    // ==========================================

    /**
     * 获取将被存储在 JWT 的 subject (sub) 中的标识符。
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    /**
     * 返回一个包含你想加到 JWT Token Payload 中的自定义声明的键值对数组。
     */
    public function getJWTCustomClaims()
    {
        return [
            // 将基础信息放入 Token 中，Next.js 解码 Cookie 即可直接使用，无需查库
            'full_name'  => $this->full_name,
            'role'       => $this->role,
            'status'     => $this->status,
            'image_path' => $this->image_path,
        ];
    }
}