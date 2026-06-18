<?php

namespace App\Http\Controllers;

use App\Models\Income;
use Illuminate\Http\Request;
use Carbon\Carbon;

class IncomeController extends Controller
{
    public function index(Request $request)
    {
        $query = Income::with(['category', 'payment_method']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        if ($request->filled('category_id') && $request->category_id !== 'all') {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('payment_method_id') && $request->payment_method_id !== 'all') {
            $query->where('payment_method_id', $request->payment_method_id);
        }

        if ($request->filled('start_date') && $request->start_date !== 'any') {
            if ($request->start_date === 'today') $query->whereDate('date', '>=', Carbon::today());
            elseif ($request->start_date === 'yesterday') $query->whereDate('date', '>=', Carbon::yesterday());
            else $query->whereDate('date', '>=', $request->start_date);
        }

        if ($request->filled('end_date') && $request->end_date !== 'any') {
            if ($request->end_date === 'today') $query->whereDate('date', '<=', Carbon::today());
            elseif ($request->end_date === 'yesterday') $query->whereDate('date', '<=', Carbon::yesterday());
            else $query->whereDate('date', '<=', $request->end_date);
        }

        $incomes = $query->orderBy('date', 'desc')->orderBy('time', 'desc')->paginate(5);

        return response()->json($incomes);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'category_id' => 'required|exists:categories,id',
        ]);

        $income = Income::create($request->all());
        return response()->json(['message' => 'Income created', 'data' => $income], 201);
    }

    public function update(Request $request, $id)
    {
        $income = Income::findOrFail($id);

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'category_id' => 'required|exists:categories,id',
        ]);

        $income->update($request->all());
        return response()->json(['message' => 'Income updated', 'data' => $income]);
    }

    public function destroy($id)
    {
        $income = Income::findOrFail($id);
        $income->delete();
        return response()->json(['message' => 'Income deleted']);
    }
}