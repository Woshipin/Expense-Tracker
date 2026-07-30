<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use PHPOpenSourceSaver\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable, SoftDeletes;

    // 角色常量定义 (0 为最高管理员)
    public const ROLE_SUPER_ADMIN = 0;
    public const ROLE_ADMIN       = 1;
    public const ROLE_PREMIUM     = 2;
    public const ROLE_BASIC       = 3;

    // 状态常量定义
    public const STATUS_INACTIVE = 0;
    public const STATUS_ACTIVE   = 1;

    /**
     * 自动追加到模型序列化输出里的自定义属性
     */
    protected $appends = [
        'permissions',
    ];

    protected $fillable = [
        'full_name',
        'email',
        'password',
        'role',
        'status',
        'currency',
        'image_path',
        'provider',
        'provider_id',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
            'role'              => 'integer',
            'status'            => 'integer',
        ];
    }

    /**
     * 用户所属的权限组关联
     */
    public function permissionGroups(): BelongsToMany
    {
        return $this->belongsToMany(PermissionGroup::class, 'permission_group_user', 'user_id', 'permission_group_id')
                    ->withTimestamps();
    }

    /**
     * 🌟 核心控制访问器：
     * 1. 刚注册 / 未加入任何权限组的新账号：默认开通除 Users、Types、Permissions 外的所有功能！
     * 2. 已加入权限组的账号：严格按照关联的 Permission Group 打勾节点生效。
     * 3. Super Admin (Role 0)：保底拥有 Permissions 页面管理权。
     */
    public function getPermissionsAttribute(): array
    {
        $groups = $this->permissionGroups()->get();
        $permissions = [];

        // 汇总已加入的权限组打勾节点
        foreach ($groups as $group) {
            if (is_array($group->permissions)) {
                $permissions = array_merge($permissions, $group->permissions);
            }
        }

        // 🌟【新注册/未配置账号默认权限策略】：
        // 如果账号尚未被拉入任何权限组，默认开放除了 Users、Types、Permissions 之外的全部页面和功能！
        if ($groups->isEmpty()) {
            $permissions = [
                // 1. Dashboard & AI 智能分析 (含 Chatbot)
                'dashboard.view',
                'ai_insights.view',
                'ai_insights.chat',

                // 2. Expenses 支出管理 (包含查看、新增、编辑、删除、AI扫码全部功能)
                'expenses.view',
                'expenses.create',
                'expenses.edit',
                'expenses.delete',
                'expenses.scan',

                // 3. Income 收入管理 (全部功能)
                'incomes.view',
                'incomes.create',
                'incomes.edit',
                'incomes.delete',

                // 4. Calendar 日历流 (全部功能)
                'calendar.view',
                'calendar.create',
                'calendar.edit',
                'calendar.delete',
                'calendar.manage',

                // 5. Budget 预算中心 (全部功能)
                'budget.view',
                'budget.create',
                'budget.edit',
                'budget.delete',
                'budget.manage',

                // 6. Categories 分类配置 (全部功能)
                'categories.view',
                'categories.create',
                'categories.edit',
                'categories.delete',
                'categories.manage',

                // 7. Payment Methods 支付渠道 (全部功能)
                'payment_methods.view',
                'payment_methods.create',
                'payment_methods.edit',
                'payment_methods.delete',
                'payment_methods.manage',
            ];
        }

        // 🌟 保底规则：Super Admin (Role 0) 始终保留 Permissions 页面访问与管理权
        if ((int)$this->role === self::ROLE_SUPER_ADMIN) {
            $permissions[] = 'permissions.view';
            $permissions[] = 'permissions.manage';
        }

        return array_values(array_unique($permissions));
    }

    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [
            'full_name'  => $this->full_name,
            'role'       => $this->role,
            'status'     => $this->status,
            'image_path' => $this->image_path,
        ];
    }
}