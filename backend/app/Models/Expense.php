<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    use HasFactory;

    // 【修改】：加入 user_id 允许批量赋值
    protected $fillable = [
        'user_id',
        'title',
        'description',
        'price',
        'date',
        'time',
        'payment_method_id', // 改为 ID
        'category_id',       // 改为 ID
    ];

    // 关联：一笔支出属于一个用户
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // 关联 Category 模型
    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    // 关联 PaymentMethod 模型 (命名为 payment_method 方便前端直接点出来)
    public function payment_method()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}