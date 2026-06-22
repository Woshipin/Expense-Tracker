<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentMethod extends Model
{
    use HasFactory;

    // 【修改】：加入 type_id, icon, color 允许批量赋值
    protected $fillable = [
        'user_id',
        'type_id',      // 新增
        'name',
        'icon',         // 新增
        'color',        // 新增
        'description',
        'status',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // 关联：属于一个收支类型 (Expense/Income)
    public function type()
    {
        return $this->belongsTo(Type::class);
    }
}