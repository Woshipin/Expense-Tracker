<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class PermissionGroup extends Model
{
    use HasFactory;

    protected $table = 'permission_groups';

    protected $fillable = [
        'name',
        'description',
        'permissions',
    ];

    protected $casts = [
        'permissions' => 'array', // 自动转为 PHP Array
    ];

    /**
     * 属于该权限组的用户
     */
    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'permission_group_user', 'permission_group_id', 'user_id')
                    ->withTimestamps();
    }
}