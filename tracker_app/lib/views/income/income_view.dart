import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../shared/crud_helpers.dart';

class IncomeView extends StatefulWidget {
  const IncomeView({super.key});

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
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

  // Income 的专属配置
  final String endpoint = '/incomes';
  final String singular = 'Income';
  final String plural = 'Income';
  final Color amountColor = const Color(0xFF059669); // 绿色主题
  final int typeId = 2; // 2 代表 Income

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
    final result = await showDialog<_IncomeFormData>(
      context: context,
      builder: (_) => IncomeFormDialog(
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
      icon: Icons.account_balance_wallet_outlined,
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
                  gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]), 
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
              _detailRow('Amount', 'RM ${money(item['price'])}', color: amountColor),
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

  @override
  Widget build(BuildContext context) {
    final double fw = MediaQuery.of(context).size.width < 700 ? double.infinity : 260;

    return PageScaffold(
      title: plural,
      subtitle: 'Detailed view of your incoming transactions.',
      action: PrimaryActionButton(label: 'Add $singular', icon: Icons.add, onPressed: () => _save()),
      children: [
        ToolbarBox(children: [
          SizedBox(width: fw, child: TextField(controller: _search.controller, onChanged: (_) => _search.onChanged(() { _page = 1; _load(); }), decoration: sunsetFieldDecoration('Search ${plural.toLowerCase()}...', icon: Icons.search))),
          SizedBox(width: fw, child: TextField(controller: _startDate, readOnly: true, onTap: () => _selectDateFilter(_startDate), decoration: sunsetFieldDecoration('Start Date'))),
          SizedBox(width: fw, child: TextField(controller: _endDate, readOnly: true, onTap: () => _selectDateFilter(_endDate), decoration: sunsetFieldDecoration('End Date'))),
          SizedBox(width: fw, child: _optionDropdown(_categoryId, 'All Categories', _categories, (value) { setState(() { _categoryId = value; _page = 1; }); _load(); })),
          SizedBox(width: fw, child: _optionDropdown(_methodId, 'All Payment Methods', _methods, (value) { setState(() { _methodId = value; _page = 1; }); _load(); })),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(onPressed: _clearFilters, icon: const Icon(Icons.filter_alt_off_outlined), tooltip: 'Clear filters'),
              const SizedBox(width: 12),
              IconButton.filledTonal(onPressed: _load, icon: Icon(_loading ? Icons.sync : Icons.refresh), tooltip: 'Refresh'),
            ],
          )
        ]),
        const SizedBox(height: 20),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: SunsetColors.primary)))
        else if (_items.isEmpty) _empty()
        else LayoutBuilder(builder: (context, constraints) {
          return constraints.maxWidth >= 900 ? _table() : _cards();
        }),
        PaginationBar(currentPage: _page, totalPages: _pages, onPage: (page) { setState(() => _page = page); _load(); }),
      ],
    );
  }

  Widget _optionDropdown(String value, String allLabel, List<JsonMap> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: sunsetFieldDecoration(allLabel),
      items: [
        DropdownMenuItem(value: 'all', child: Text(allLabel)),
        ...options.map((item) => DropdownMenuItem(value: '${item['id']}', child: Text(fieldText(item, 'name')))),
      ],
      onChanged: (value) { if (value != null) onChanged(value); },
    );
  }

  Widget _cards() {
    return Column(
      children: _items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade100)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: amountColor.withValues(alpha: 0.12), foregroundColor: amountColor, child: Text(initials(fieldText(item, 'title'), 'IN'))),
              const SizedBox(width: 12),
              Expanded(child: Text(fieldText(item, 'title'), style: const TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.w900, fontSize: 16))),
              Text('RM ${money(item['price'])}', style: TextStyle(color: amountColor, fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
            const SizedBox(height: 10),
            Text('${fieldText(item, 'date')}  ${fieldText(item, 'time')}', style: const TextStyle(color: Color(0x992D2520), fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(label: Text(nestedText(item, 'category', 'name')), backgroundColor: const Color(0xFFFFF7ED), side: BorderSide.none),
              Chip(label: Text(nestedText(item, 'payment_method', 'name')), backgroundColor: const Color(0xFFF1F5F9), side: BorderSide.none),
            ]),
            Align(alignment: Alignment.centerRight, child: ActionButtons(onView: () => _view(item), onEdit: () => _save(editing: item), onDelete: () => _delete(item))),
          ]),
        );
      }).toList(),
    );
  }

  Widget _table() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(SunsetColors.secondary),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          columns: const [
            DataColumn(label: Text('Title')), DataColumn(label: Text('Description')), DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Date')), DataColumn(label: Text('Time')), DataColumn(label: Text('Method')),
            DataColumn(label: Text('Category')), DataColumn(label: Text('Actions')),
          ],
          rows: _items.map((item) {
            return DataRow(cells: [
              DataCell(Text(fieldText(item, 'title'), overflow: TextOverflow.ellipsis)),
              DataCell(SizedBox(width: 170, child: Text(fieldText(item, 'description', 'N/A'), overflow: TextOverflow.ellipsis))),
              DataCell(Text('RM ${money(item['price'])}', style: TextStyle(color: amountColor, fontWeight: FontWeight.w900))),
              DataCell(Text(fieldText(item, 'date'))),
              DataCell(Text(fieldText(item, 'time'))),
              DataCell(Text(nestedText(item, 'payment_method', 'name'))),
              DataCell(Text(nestedText(item, 'category', 'name'))),
              DataCell(ActionButtons(onView: () => _view(item), onEdit: () => _save(editing: item), onDelete: () => _delete(item))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Text('No ${plural.toLowerCase()} found matching criteria.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800)),
    );
  }
}

class _IncomeFormData {
  final String title; final String description; final String price; final String date; final String time; final String paymentMethodId; final String categoryId;
  const _IncomeFormData({required this.title, required this.description, required this.price, required this.date, required this.time, required this.paymentMethodId, required this.categoryId});
  Map<String, dynamic> toJson() => { 'title': title, 'description': description, 'price': price, 'date': date, 'time': time, 'payment_method_id': paymentMethodId, 'category_id': categoryId };
}

class IncomeFormDialog extends StatefulWidget {
  final String title; final JsonMap? editing; final List<JsonMap> categories; final List<JsonMap> methods;
  const IncomeFormDialog({super.key, required this.title, this.editing, required this.categories, required this.methods});
  @override
  State<IncomeFormDialog> createState() => _IncomeFormDialogState();
}

class _IncomeFormDialogState extends State<IncomeFormDialog> {
  late final TextEditingController _title; late final TextEditingController _description; late final TextEditingController _price;
  late final TextEditingController _date; late final TextEditingController _time; 
  late String _categoryId; // 恢复：使用 late String
  late String _methodId;   // 恢复：使用 late String

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
    
    // 恢复：和 ExpenseFormDialog 结构完全保持 100% 相同
    _categoryId = fieldText(item, 'category_id', widget.categories.isNotEmpty ? '${widget.categories.first['id']}' : '');
    _methodId = fieldText(item, 'payment_method_id', widget.methods.isNotEmpty ? '${widget.methods.first['id']}' : '');
  }

  @override
  void dispose() { _title.dispose(); _description.dispose(); _price.dispose(); _date.dispose(); _time.dispose(); super.dispose(); }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: SunsetColors.secondary)), child: child!),
    );
    if (date != null) setState(() => _date.text = date.toIso8601String().split('T')[0]);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: SunsetColors.secondary)), child: child!),
    );
    if (time != null) {
      setState(() => _time.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    }
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
            Navigator.pop(context, _IncomeFormData(title: _title.text.trim(), description: _description.text.trim(), price: _price.text.trim(), date: _date.text.trim(), time: _time.text.trim(), paymentMethodId: _methodId, categoryId: _categoryId));
          },
          style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Save'),
        ),
      ],
    );
  }

  // 恢复：和 ExpenseFormDialog 结构完全保持 100% 相同
  Widget _dropdown(String value, String label, List<JsonMap> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value, decoration: sunsetFieldDecoration(label),
      items: options.map((item) => DropdownMenuItem(value: '${item['id']}', child: Text(fieldText(item, 'name')))).toList(),
      onChanged: (value) { if (value != null) onChanged(value); },
    );
  }
}