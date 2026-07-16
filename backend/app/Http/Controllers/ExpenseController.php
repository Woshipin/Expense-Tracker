<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Category;
use App\Models\PaymentMethod;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;

class ExpenseController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'search' => 'nullable|string|max:100',
            'category_id' => 'nullable|string',
            'payment_method_id' => 'nullable|string',
            'start_date' => 'nullable|string',
            'end_date' => 'nullable|string',
        ]);

        $query = Expense::with(['category', 'payment_method'])
                        ->where('user_id', auth()->id());

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
            if ($request->start_date === 'today') {
                $query->whereDate('date', '>=', Carbon::today());
            } elseif ($request->start_date === 'yesterday') {
                $query->whereDate('date', '>=', Carbon::yesterday());
            } else {
                $startDate = strtotime($request->start_date) ? Carbon::parse($request->start_date) : null;
                if ($startDate) $query->whereDate('date', '>=', $startDate);
            }
        }

        if ($request->filled('end_date') && $request->end_date !== 'any') {
            if ($request->end_date === 'today') {
                $query->whereDate('date', '<=', Carbon::today());
            } elseif ($request->end_date === 'yesterday') {
                $query->whereDate('date', '<=', Carbon::yesterday());
            } else {
                $endDate = strtotime($request->end_date) ? Carbon::parse($request->end_date) : null;
                if ($endDate) $query->whereDate('date', '<=', $endDate);
            }
        }

        $expenses = $query->orderBy('date', 'desc')->orderBy('time', 'desc')->paginate(10);
        return response()->json($expenses);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required|date_format:H:i', 
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('user_id', auth()->id())],
            'category_id' => ['required', Rule::exists('categories', 'id')->where('user_id', auth()->id())],
        ]);

        $validated['user_id'] = auth()->id();
        $expense = Expense::create($validated);
        return response()->json(['message' => 'Expense created', 'data' => $expense], 201);
    }

    public function update(Request $request, $id)
    {
        $expense = Expense::where('user_id', auth()->id())->findOrFail($id);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'price' => 'required|numeric|min:0',
            'date' => 'required|date',
            'time' => 'required|date_format:H:i',
            'payment_method_id' => ['required', Rule::exists('payment_methods', 'id')->where('user_id', auth()->id())],
            'category_id' => ['required', Rule::exists('categories', 'id')->where('user_id', auth()->id())],
        ]);

        $expense->update($validated);
        return response()->json(['message' => 'Expense updated', 'data' => $expense]);
    }

    public function destroy($id)
    {
        $expense = Expense::where('user_id', auth()->id())->findOrFail($id);
        $expense->delete();
        return response()->json(['message' => 'Expense deleted']);
    }

    /**
     * AI 扫描小票 (中英文双语、自动剔除货币符号、专属 Key 稳定版)
     */
    public function scanReceipt(Request $request)
    {
        $userId = Auth::id();

        $request->validate([
            'receipt_image' => 'required|image|mimes:jpeg,png,jpg|max:5120', 
            'client_date'   => 'nullable|string',
            'client_time'   => 'nullable|string',
        ]);

        $fallbackDate = $request->input('client_date', Carbon::today()->toDateString());
        $fallbackTime = $request->input('client_time', Carbon::now()->format('H:i'));

        $file = $request->file('receipt_image');

        // =====================================================================
        // 第 1 步：调用 OCR.space 提取中英文文字
        // =====================================================================
        try {
            $ocrResponse = Http::attach(
                'file', file_get_contents($file->path()), $file->getClientOriginalName()
            )->post('https://api.ocr.space/parse/image', [
                // 【已更新】：替换为您专属的稳定版免费 API Key，单日额度 25000 次，速度更快更稳定
                'apikey' => 'K81381008388957', 
                'language' => 'chs', 
                'isTable' => 'true', 
                'scale' => 'true'
            ]);

            $ocrData = $ocrResponse->json();

            if (isset($ocrData['IsErroredOnProcessing']) && $ocrData['IsErroredOnProcessing']) {
                $errorMsg = $ocrData['ErrorMessage'][0] ?? 'OCR limit exceeded or processing error.';
                return response()->json(['message' => 'OCR Service Error: ' . $errorMsg], 422);
            }

            $receiptText = $ocrData['ParsedResults'][0]['ParsedText'] ?? '';

            if (empty(trim($receiptText))) {
                return response()->json(['message' => 'Cannot read text from image. Please ensure the photo is clear and well-lit.'], 422);
            }

        } catch (\Exception $e) {
            return response()->json(['message' => 'OCR Connection Failed: ' . $e->getMessage()], 500);
        }

        // =====================================================================
        // 第 2 步：构建高容错 Prompt，教导 Llama 3.3 提炼 JSON
        // =====================================================================
        $categories = Category::where('user_id', $userId)->where('type_id', 1)->select('id', 'name')->get();
        $paymentMethods = PaymentMethod::where('user_id', $userId)->where('type_id', 1)->select('id', 'name')->get();

        $categoryList = $categories->map(fn($c) => "[ID: {$c->id}, Name: {$c->name}]")->implode(", ");
        $paymentList = $paymentMethods->map(fn($p) => "[ID: {$p->id}, Name: {$p->name}]")->implode(", ");

        $prompt = "You are an AI receipt parser. Extract purchased items from this OCR text into a JSON ARRAY.
        You MUST return ONLY a valid JSON ARRAY. No explanations. No markdown blocks.

        OCR TEXT:
        \"\"\"
        {$receiptText}
        \"\"\"

        STRICT RULES:
        1. Extract the name and price for EVERY SINGLE ITEM row. 
        2. KEEP ORIGINAL NAME: Extract the item name EXACTLY as printed (e.g. '紅燒豆腐飯', 'Joseph Drouhin'). Do NOT translate.
        3. IGNORE NON-ITEMS: DO NOT extract grand totals, sub-totals, service charges, tax rows, or cash change (e.g., 'TOTAL', 'SUBTOTAL', 'TAX', 'Service Charge').
        4. price: Must be a pure number/float. DO NOT include any currency symbols like $, RM, or ¥ in the JSON.
        5. Use '{$fallbackDate}' for date and '{$fallbackTime}' for time if not explicitly found on the receipt.

        DATA SCHEMAS:
        - title: Original item name.
        - price: The clean numeric price (e.g. 138.00).
        - description: Format: 'Qty: [qty] | Original: [original name]' (e.g., 'Qty: 1 | Original: Steamed Shrimp Dumpling').
        - date: 'YYYY-MM-DD'
        - time: 'HH:MM'

        MATCH IDs:
        Categories: {$categoryList}
        - category_id: Match best ID (integer).
        Payment Methods: {$paymentList}
        - payment_method_id: Match best ID (integer).

        OUTPUT JSON ARRAY FORMAT:
        [
            { \"title\": \"Joseph Drouhin\", \"description\": \"Qty: 1 | Original: Joseph Drouhin\", \"price\": 138.00, \"date\": \"2019-06-08\", \"time\": \"12:57\", \"category_id\": 1, \"payment_method_id\": 2 }
        ]";

        $apiKey = config('services.groq.api_key');
        
        try {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $apiKey,
                'Content-Type'  => 'application/json',
            ])->post('https://api.groq.com/openai/v1/chat/completions', [
                'model' => 'llama-3.3-70b-versatile', 
                'messages' => [
                    ['role' => 'user', 'content' => $prompt]
                ],
                'temperature' => 0.0, // 降到 0 保证最高的数据解析精准度
                'max_tokens' => 2000, 
            ]);

            if ($response->failed()) {
                return response()->json(['message' => 'Groq API Error: ' . $response->body()], 400);
            }

            $data = $response->json();
            $aiOutput = $data['choices'][0]['message']['content'] ?? '';

            // 清理 JSON 外壳
            $cleanedJson = preg_replace('/```json|```/', '', $aiOutput);
            $start = strpos($cleanedJson, '[');
            $end = strrpos($cleanedJson, ']');
            if ($start !== false && $end !== false) {
                $cleanedJson = substr($cleanedJson, $start, $end - $start + 1);
            }
            $cleanedJson = trim($cleanedJson);

            // 【关键清洗】：移除 AI 尾部可能会多写的非法逗号
            $cleanedJson = preg_replace('/,\s*([\]}])/m', '$1', $cleanedJson);

            $itemsData = json_decode($cleanedJson, true);

            if (json_last_error() !== JSON_ERROR_NONE || !is_array($itemsData)) {
                return response()->json(['message' => 'AI failed to parse items.', 'raw_output' => $aiOutput], 422);
            }

            // =====================================================================
            // 第 3 步：遍历清洗并安全入库
            // =====================================================================
            $savedCount = 0;

            foreach ($itemsData as $item) {
                $rawPrice = $item['price'] ?? null;
                if (is_null($rawPrice)) continue;

                // 【核心容错修复】：将价格转换为字符串，并使用正则剥离掉可能混入的 $、RM、¥ 符号
                $priceString = (string)$rawPrice;
                $cleanPriceString = preg_replace('/[^\d.]/', '', $priceString);
                $price = (float)$cleanPriceString;

                if ($price <= 0) continue; // 过滤非正数

                $catId = $item['category_id'] ?? null;
                $payId = $item['payment_method_id'] ?? null;

                if (!$categories->contains('id', $catId)) $catId = $categories->first()->id ?? null;
                if (!$paymentMethods->contains('id', $payId)) $payId = $paymentMethods->first()->id ?? null;

                $title = trim($item['title'] ?? '');
                if (empty($title)) $title = 'Receipt Item';

                $description = trim($item['description'] ?? '');
                if (empty($description)) $description = 'Scanned via AI';

                Expense::create([
                    'user_id' => $userId,
                    'title' => substr($title, 0, 255),
                    'description' => substr($description, 0, 1000), 
                    'price' => $price,
                    'date' => preg_match('/^\d{4}-\d{2}-\d{2}$/', $item['date'] ?? '') ? $item['date'] : $fallbackDate,
                    'time' => preg_match('/^\d{2}:\d{2}$/', $item['time'] ?? '') ? $item['time'] : $fallbackTime,
                    'category_id' => $catId,
                    'payment_method_id' => $payId,
                ]);

                $savedCount++;
            }

            if ($savedCount === 0) {
                return response()->json(['message' => 'No valid items found on the receipt.'], 422);
            }

            return response()->json([
                'message' => "Successfully scanned and saved {$savedCount} items!",
                'count' => $savedCount
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Failed to process receipt: ' . $e->getMessage(),
            ], 500);
        }
    }
}