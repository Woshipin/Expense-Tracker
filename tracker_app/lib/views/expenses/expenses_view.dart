import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../shared/crud_helpers.dart';

class ExpenseListView extends StatefulWidget {
  // 命名构造函数，与 main_layout 匹配
  const ExpenseListView.expenses({super.key});

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  final _search = DebouncedSearchController();
  List<JsonMap> _items = [];
  List<JsonMap> _categories = [];
  List<JsonMap> _methods = [];
  bool _loading = true;
  
  String _categoryId = 'all';
  String _methodId = 'all';
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  int _page = 1;
  int _pages = 1;

  final String endpoint = '/expenses';
  final String singular = 'Expense';
  final String plural = 'Expenses';
  final Color amountColor = const Color(0xFFEF4444); // 红色
  final int typeId = 1; // 1 代表 Expense

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _startDate.dispose();
    _endDate.dispose();
    super.dispose();
  }

  Future<void> _selectDateFilter(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: SunsetColors.secondary)),
        child: child!,
      ),
    );
    if (date != null) {
      controller.text = date.toIso8601String().split('T')[0];
      _load();
    }
  }

  Future<void> _loadOptions() async {
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('/categories', queryParameters: {'status': 1}),
        ApiClient().dio.get('/payment-methods', queryParameters: {'status': 1}),
      ]);
      final cats = parsePaged(responses[0].data).items;
      final methods = parsePaged(responses[1].data).items;
      if (!mounted) return;
      setState(() {
        _categories = cats.where((c) => fieldInt(c, 'status', 1) == 1 && fieldInt(c, 'type_id', 1) == typeId).toList();
        _methods = methods.where((m) => fieldInt(m, 'status', 1) == 1 && fieldInt(m, 'type_id', 1) == typeId).toList();
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await fetchPaged(endpoint, page: _page, params: {
        if (_search.controller.text.trim().isNotEmpty) 'search': _search.controller.text.trim(),
        if (_categoryId != 'all') 'category_id': _categoryId,
        if (_methodId != 'all') 'payment_method_id': _methodId,
        if (_startDate.text.isNotEmpty) 'start_date': _startDate.text,
        if (_endDate.text.isNotEmpty) 'end_date': _endDate.text,
      });
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _pages = result.totalPages;
      });
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to fetch ${plural.toLowerCase()}.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    _search.controller.clear();
    _startDate.clear();
    _endDate.clear();
    setState(() {
      _categoryId = 'all';
      _methodId = 'all';
      _page = 1;
    });
    _load();
  }

  Future<void> _save({JsonMap? editing}) async {
    final result = await showDialog<_ExpenseFormData>(
      context: context,
      builder: (_) => ExpenseFormDialog(
        title: editing == null ? 'Add $singular' : 'Edit $singular', 
        editing: editing, 
        categories: _categories, 
        methods: _methods
      ),
    );
    if (result == null) return;
    try {
      if (editing == null) {
        await ApiClient().dio.post(endpoint, data: result.toJson());
        if (mounted) SunsetToast.show(context, '$singular added successfully!');
      } else {
        await ApiClient().dio.put('$endpoint/${editing['id']}', data: result.toJson());
        if (mounted) SunsetToast.show(context, '$singular updated successfully!');
      }
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Operation failed.');
    }
  }

  Future<void> _delete(JsonMap item) async {
    final ok = await confirmDeleteDialog(
      context, 
      title: 'Delete $singular', 
      name: '${fieldText(item, 'title')} - RM ${money(item['price'])}', 
      icon: Icons.receipt_long_outlined,
    );
    if (!ok) return;
    try {
      await ApiClient().dio.delete('$endpoint/${item['id']}');
      if (mounted) SunsetToast.show(context, '$singular deleted successfully');
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to delete ${singular.toLowerCase()}');
    }
  }

  void _view(JsonMap item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('$singular Details', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92, height: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF87171), Color(0xFFEF4444)]), 
                  borderRadius: BorderRadius.circular(26)
                ),
                alignment: Alignment.center,
                child: const Text('RM', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 16),
              Text(fieldText(item, 'title'), textAlign: TextAlign.center, style: const TextStyle(color: SunsetColors.dark, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(fieldText(item, 'description', 'No description provided.'), textAlign: TextAlign.center),
              const Divider(height: 28),
              _detailRow('Amount', '-RM ${money(item['price'])}', color: amountColor),
              _detailRow('Date', fieldText(item, 'date')),
              _detailRow('Time', fieldText(item, 'time')),
              _detailRow('Category', nestedText(item, 'category', 'name')),
              _detailRow('Payment Method', nestedText(item, 'payment_method', 'name')),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.dark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Color(0x992D2520), fontWeight: FontWeight.w800))),
          Expanded(child: Text(value, style: TextStyle(color: color ?? SunsetColors.dark, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  // ---------------- 智能响应式组件 ----------------
  InputDecoration _customFilterDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey.shade400) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), 
        borderSide: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: SunsetColors.primary, width: 1.5),
      ),
    );
  }

  Widget _customSearchField() => TextField(controller: _search.controller, onChanged: (_) => _search.onChanged(() { _page = 1; _load(); }), decoration: _customFilterDecoration('Search ${plural.toLowerCase()}...', icon: Icons.search));
  Widget _customDateField(TextEditingController controller, String hint) => TextField(controller: controller, readOnly: true, onTap: () => _selectDateFilter(controller), decoration: _customFilterDecoration(hint));
  
  Widget _customDropdown(String value, String hint, List<JsonMap> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
      decoration: _customFilterDecoration(hint),
      items: [
        DropdownMenuItem(value: 'all', child: Text(hint, style: const TextStyle(fontSize: 13, color: SunsetColors.dark))),
        ...options.map((item) => DropdownMenuItem(value: '${item['id']}', child: Text(fieldText(item, 'name'), style: const TextStyle(fontSize: 13, color: SunsetColors.dark)))),
      ],
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  Widget _customIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10), border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.2), width: 1.5)),
        child: Icon(icon, size: 22, color: SunsetColors.primary),
      ),
    );
  }

  // ---------------- 构建页面主体 ----------------
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return PageScaffold(
      title: plural,
      subtitle: 'Detailed view of your outgoing transactions.',
      action: PrimaryActionButton(label: 'Add $singular', icon: Icons.add, onPressed: () => _save()),
      children: [
        // 核心：所有视图全部包裹在这个统一的大卡片中
        Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24), 
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // 1. 动态过滤区
              Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                child: width >= 1100 
                  ? _buildDesktopFilters() 
                  : (width >= 700 ? _buildTabletFilters() : _buildMobileFilters()),
              ),
              
              // 2. 数据展示区
              if (_loading) 
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator(color: SunsetColors.primary)))
              else if (_items.isEmpty) 
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48), child: _empty())
              else 
                width >= 900 
                  ? Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _tableContent()) 
                  : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _cardsContent()),
              
              // 3. 翻页器
              if (_items.isNotEmpty)
                _buildUnifiedPagination(),
            ],
          ),
        )
      ],
    );
  }

  // ---- 3 种屏幕尺寸的过滤器排版 ----
  Widget _buildDesktopFilters() {
    return Row(
      children: [
        Expanded(flex: 3, child: _customSearchField()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _customDateField(_startDate, 'Start Date')),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _customDateField(_endDate, 'End Date')),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _customDropdown(_categoryId, 'All Categories', _categories, (value) { setState(() { _categoryId = value; _page = 1; }); _load(); })),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _customDropdown(_methodId, 'All Methods', _methods, (value) { setState(() { _methodId = value; _page = 1; }); _load(); })),
        const SizedBox(width: 12),
        _customIconButton(Icons.filter_alt_off_outlined, _clearFilters),
        const SizedBox(width: 8),
        _customIconButton(Icons.sync, _load),
      ],
    );
  }

  Widget _buildTabletFilters() {
    return Column(
      children: [
        Row(children: [ Expanded(child: _customSearchField()), const SizedBox(width: 12), _customIconButton(Icons.filter_alt_off_outlined, _clearFilters), const SizedBox(width: 8), _customIconButton(Icons.sync, _load)]),
        const SizedBox(height: 12),
        Row(children: [ Expanded(child: _customDateField(_startDate, 'Start Date')), const SizedBox(width: 12), Expanded(child: _customDateField(_endDate, 'End Date')) ]),
        const SizedBox(height: 12),
        Row(children: [ Expanded(child: _customDropdown(_categoryId, 'All Categories', _categories, (value) { setState(() { _categoryId = value; _page = 1; }); _load(); })), const SizedBox(width: 12), Expanded(child: _customDropdown(_methodId, 'All Methods', _methods, (value) { setState(() { _methodId = value; _page = 1; }); _load(); })) ]),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        _customSearchField(),
        const SizedBox(height: 12),
        Row(children: [ Expanded(child: _customDateField(_startDate, 'Start Date')), const SizedBox(width: 12), Expanded(child: _customDateField(_endDate, 'End Date')) ]),
        const SizedBox(height: 12),
        _customDropdown(_categoryId, 'All Categories', _categories, (value) { setState(() { _categoryId = value; _page = 1; }); _load(); }),
        const SizedBox(height: 12),
        _customDropdown(_methodId, 'All Methods', _methods, (value) { setState(() { _methodId = value; _page = 1; }); _load(); }),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _customIconButton(Icons.filter_alt_off_outlined, _clearFilters),
            const SizedBox(width: 8),
            _customIconButton(Icons.sync, _load),
          ],
        )
      ],
    );
  }

  // ---- 表格视图 (Desktop) ----
  Widget _tableContent() {
    const double colTitle = 240; const double colDesc = 200; const double colPrice = 140;
    const double colDate = 110; const double colTime = 90; const double colMethod = 120;
    const double colCategory = 120; const double colActions = 120;
    const double totalWidth = colTitle + colDesc + colPrice + colDate + colTime + colMethod + colCategory + colActions + 32;
    const TextStyle headerStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(color: SunsetColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: totalWidth,
              child: Row(
                children: const [
                  SizedBox(width: colTitle, child: Text('Title', style: headerStyle)),
                  SizedBox(width: colDesc, child: Text('Description', style: headerStyle)),
                  SizedBox(width: colPrice, child: Text('Amount (RM)', style: headerStyle)),
                  SizedBox(width: colDate, child: Text('Date', style: headerStyle)),
                  SizedBox(width: colTime, child: Text('Time', style: headerStyle)),
                  SizedBox(width: colMethod, child: Text('Method', style: headerStyle)),
                  SizedBox(width: colCategory, child: Text('Category', style: headerStyle)),
                  SizedBox(width: colActions, child: Text('Actions', style: headerStyle, textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade100), right: BorderSide(color: Colors.grey.shade100), bottom: BorderSide(color: Colors.grey.shade100)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Column(
                children: _items.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final item = entry.value;
                  final bool isLast = index == _items.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
                    child: Row(
                      children: [
                        SizedBox(width: colTitle, child: Row(children: [ Container(width: 36, height: 36, decoration: BoxDecoration(color: SunsetColors.primary, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(initials(fieldText(item, 'title'), 'EX'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))), const SizedBox(width: 12), Expanded(child: Text(fieldText(item, 'title'), style: const TextStyle(fontWeight: FontWeight.bold, color: SunsetColors.dark), overflow: TextOverflow.ellipsis)) ])),
                        SizedBox(width: colDesc, child: Text(fieldText(item, 'description', 'N/A'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        SizedBox(width: colPrice, child: Text('-RM ${money(item['price'])}', style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 14))),
                        SizedBox(width: colDate, child: Text(fieldText(item, 'date'), style: const TextStyle(fontWeight: FontWeight.w600, color: SunsetColors.dark, fontSize: 13))),
                        SizedBox(width: colTime, child: Text(fieldText(item, 'time'), style: const TextStyle(fontWeight: FontWeight.w600, color: SunsetColors.dark, fontSize: 13))),
                        SizedBox(width: colMethod, child: Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: Text(nestedText(item, 'payment_method', 'name'), style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold))))),
                        SizedBox(width: colCategory, child: Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)), child: Text(nestedText(item, 'category', 'name'), style: const TextStyle(color: SunsetColors.primary, fontSize: 11, fontWeight: FontWeight.bold))))),
                        SizedBox(width: colActions, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [ InkWell(onTap: () => _view(item), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.blueAccent))), const SizedBox(width: 8), InkWell(onTap: () => _save(editing: item), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 18, color: Colors.green))), const SizedBox(width: 8), InkWell(onTap: () => _delete(item), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent))) ])),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- 卡片视图 (Tablet & Mobile) ----
  Widget _cardsContent() {
    return Column(
      children: _items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: SunsetColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(initials(fieldText(item, 'title'), 'EX'), style: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fieldText(item, 'title'), style: const TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.w900, fontSize: 15)),
                    Text('${fieldText(item, 'date')} • ${fieldText(item, 'time')}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Text('-RM ${money(item['price'])}', style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(6)), child: Text(nestedText(item, 'category', 'name'), style: const TextStyle(color: SunsetColors.primary, fontSize: 11, fontWeight: FontWeight.bold))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: Text(nestedText(item, 'payment_method', 'name'), style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _cardActionBtn(Icons.remove_red_eye_outlined, 'View', Colors.grey.shade600, () => _view(item)),
                _cardActionBtn(Icons.edit_outlined, 'Edit', Colors.grey.shade600, () => _save(editing: item)),
                _cardActionBtn(Icons.delete_outline, 'Delete', Colors.redAccent, () => _delete(item)),
              ],
            )
          ]),
        );
      }).toList(),
    );
  }

  Widget _cardActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  // ---- 统底部分页器 ----
  Widget _buildUnifiedPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Page $_page of $_pages', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
          Row(
            children: [
              InkWell(onTap: _page > 1 ? () { setState(() => _page--); _load(); } : null, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.chevron_left, size: 18, color: _page > 1 ? SunsetColors.dark : Colors.grey.shade300))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)), child: Text('$_page', style: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.bold, fontSize: 14))),
              const SizedBox(width: 8),
              InkWell(onTap: _page < _pages ? () { setState(() => _page++); _load(); } : null, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.chevron_right, size: 18, color: _page < _pages ? SunsetColors.dark : Colors.grey.shade300))),
            ],
          )
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(child: Text('No ${plural.toLowerCase()} found matching criteria.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800)));
  }
}

class _ExpenseFormData {
  final String title; final String description; final String price; final String date; final String time; final String paymentMethodId; final String categoryId;
  const _ExpenseFormData({required this.title, required this.description, required this.price, required this.date, required this.time, required this.paymentMethodId, required this.categoryId});
  Map<String, dynamic> toJson() => { 'title': title, 'description': description, 'price': price, 'date': date, 'time': time, 'payment_method_id': paymentMethodId, 'category_id': categoryId };
}

class ExpenseFormDialog extends StatefulWidget {
  final String title; final JsonMap? editing; final List<JsonMap> categories; final List<JsonMap> methods;
  const ExpenseFormDialog({super.key, required this.title, this.editing, required this.categories, required this.methods});
  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  late final TextEditingController _title; late final TextEditingController _description; late final TextEditingController _price;
  late final TextEditingController _date; late final TextEditingController _time; 
  late String _categoryId;
  late String _methodId;

  @override
  void initState() {
    super.initState();
    final item = widget.editing ?? {};
    final now = DateTime.now();
    _title = TextEditingController(text: fieldText(item, 'title'));
    _description = TextEditingController(text: fieldText(item, 'description'));
    _price = TextEditingController(text: fieldText(item, 'price'));
    _date = TextEditingController(text: fieldText(item, 'date', now.toIso8601String().substring(0, 10)));
    _time = TextEditingController(text: fieldText(item, 'time', '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}').substring(0, 5));
    
    _categoryId = fieldText(item, 'category_id', widget.categories.isNotEmpty ? '${widget.categories.first['id']}' : '');
    _methodId = fieldText(item, 'payment_method_id', widget.methods.isNotEmpty ? '${widget.methods.first['id']}' : '');
  }

  @override
  void dispose() { _title.dispose(); _description.dispose(); _price.dispose(); _date.dispose(); _time.dispose(); super.dispose(); }

  Future<void> _selectDate() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: SunsetColors.secondary)), child: child!));
    if (date != null) setState(() => _date.text = date.toIso8601String().split('T')[0]);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now(), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: SunsetColors.secondary)), child: child!));
    if (time != null) setState(() => _time.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 460, 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _title, decoration: sunsetFieldDecoration('Title')),
              const SizedBox(height: 14),
              TextField(controller: _price, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: sunsetFieldDecoration('Amount')),
              const SizedBox(height: 14),
              TextField(controller: _date, readOnly: true, onTap: _selectDate, decoration: sunsetFieldDecoration('Date')),
              const SizedBox(height: 14),
              TextField(controller: _time, readOnly: true, onTap: _selectTime, decoration: sunsetFieldDecoration('Time')),
              const SizedBox(height: 14),
              _dropdown(_categoryId, 'Category', widget.categories, (value) => setState(() => _categoryId = value)),
              const SizedBox(height: 14),
              _dropdown(_methodId, 'Payment Method', widget.methods, (value) => setState(() => _methodId = value)),
              const SizedBox(height: 14),
              TextField(controller: _description, maxLines: 3, decoration: sunsetFieldDecoration('Description')),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_title.text.trim().isEmpty || _price.text.trim().isEmpty || _categoryId.isEmpty || _methodId.isEmpty) return;
            Navigator.pop(context, _ExpenseFormData(title: _title.text.trim(), description: _description.text.trim(), price: _price.text.trim(), date: _date.text.trim(), time: _time.text.trim(), paymentMethodId: _methodId, categoryId: _categoryId));
          },
          style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _dropdown(String value, String label, List<JsonMap> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value, decoration: sunsetFieldDecoration(label),
      items: options.map((item) => DropdownMenuItem(value: '${item['id']}', child: Text(fieldText(item, 'name')))).toList(),
      onChanged: (value) { if (value != null) onChanged(value); },
    );
  }
}