<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentMethod extends Model
{
    use HasFactory;

    // 允许批量赋值的属性
    protected $fillable = [
        'name',
        'description',
        'status',
    ];
}