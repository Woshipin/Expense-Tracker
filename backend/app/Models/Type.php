<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Type extends Model
{
    protected $fillable = [
        'name',
        'status',
    ];

    // 如果后续你需要获取该类型下的所有分类，可以加上这个关联（可选）
    public function categories()
    {
        return $this->hasMany(Category::class);
    }
}