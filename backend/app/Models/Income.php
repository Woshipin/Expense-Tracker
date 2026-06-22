<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Income extends Model
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
        'payment_method_id',
        'category_id',
    ];

    // 关联：一笔收入属于一个用户
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function payment_method()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}