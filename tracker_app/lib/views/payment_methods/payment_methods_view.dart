import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../shared/crud_helpers.dart';

class PaymentMethodsView extends StatefulWidget {
  const PaymentMethodsView({super.key});

  @override
  State<PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<PaymentMethodsView> {
  static const icons = ['CreditCard', 'Wallet', 'Banknote', 'Landmark', 'QrCode', 'DollarSign', 'Coins', 'Smartphone'];
  static const colors = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFF22C55E), Color(0xFF14B8A6),
    Color(0xFF06B6D4), Color(0xFF4F46E5), Color(0xFF8B5CF6), Color(0xFFEC4899),
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B), Color(0xFF64748B),
  ];

  final _search = DebouncedSearchController();
  List<JsonMap> _methods = [];
  bool _loading = true;
  String _status = 'all';
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await fetchPaged('/payment-methods', page: _page, params: {
        if (_search.controller.text.trim().isNotEmpty) 'search': _search.controller.text.trim(),
        if (_status != 'all') 'status': _status,
      });
      var items = result.items;
      if (_status != 'all') items = items.where((m) => fieldText(m, 'status') == _status).toList();
      if (!mounted) return;
      setState(() { _methods = items; _pages = result.totalPages; });
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to fetch payment methods.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({JsonMap? editing}) async {
    final form = await showDialog<_MethodFormData>(
      context: context, builder: (_) => MethodFormDialog(editing: editing, icons: icons, colors: colors),
    );
    if (form == null) return;
    try {
      if (editing == null) {
        await ApiClient().dio.post('/payment-methods', data: form.toJson());
        if (mounted) SunsetToast.show(context, 'Payment method added successfully!');
      } else {
        await ApiClient().dio.put('/payment-methods/${editing['id']}', data: form.toJson());
        if (mounted) SunsetToast.show(context, 'Payment method updated successfully!');
      }
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Operation failed.');
    }
  }

  Future<void> _delete(JsonMap item) async {
    final ok = await confirmDeleteDialog(
      context, title: 'Delete Method', name: fieldText(item, 'name'), icon: iconForName(fieldText(item, 'icon', 'CreditCard')),
    );
    if (!ok) return;
    try {
      await ApiClient().dio.delete('/payment-methods/${item['id']}');
      if (mounted) SunsetToast.show(context, 'Payment method deleted successfully');
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to delete payment method');
    }
  }

  void _view(JsonMap item) {
    final color = colorFromHex(fieldText(item, 'color', '#3b82f6'), const Color(0xFF3B82F6));
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Method Details', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82, height: 96,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
              child: Icon(iconForName(fieldText(item, 'icon', 'CreditCard')), color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(fieldText(item, 'name'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Chip(label: Text(fieldInt(item, 'type_id', 1) == 2 ? 'Income' : 'Expense'), backgroundColor: const Color(0xFFFFF7ED), labelStyle: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.w900), side: BorderSide.none),
            const SizedBox(height: 12),
            Text(fieldText(item, 'description', 'No description provided.'), textAlign: TextAlign.center),
          ],
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

  @override
  Widget build(BuildContext context) {
    final double fw = MediaQuery.of(context).size.width < 700 ? double.infinity : 260;
    final income = _methods.where((m) => fieldInt(m, 'type_id', 1) == 2).toList();
    final expense = _methods.where((m) => fieldInt(m, 'type_id', 1) == 1).toList();

    return PageScaffold(
      title: 'Payment Methods',
      subtitle: 'Manage system payment channels and their availability.',
      action: PrimaryActionButton(label: 'Add Method', icon: Icons.add, onPressed: () => _save()),
      children: [
        ToolbarBox(children: [
          SizedBox(width: fw, child: TextField(controller: _search.controller, onChanged: (_) => _search.onChanged(() { _page = 1; _load(); }), decoration: sunsetFieldDecoration('Search payment methods...', icon: Icons.search))),
          SizedBox(
            width: fw,
            child: DropdownButtonFormField<String>(
              initialValue: _status, decoration: sunsetFieldDecoration('All Status'),
              items: const [DropdownMenuItem(value: 'all', child: Text('All Status')), DropdownMenuItem(value: '1', child: Text('Active')), DropdownMenuItem(value: '0', child: Text('Inactive'))],
              onChanged: (value) { if (value == null) return; setState(() { _status = value; _page = 1; }); _load(); },
            ),
          ),
        ]),
        const SizedBox(height: 22),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: SunsetColors.primary)))
        else ...[
          _section('Income', income, const Color(0xFF059669)),
          const SizedBox(height: 28),
          _section('Expense', expense, SunsetColors.expense),
        ],
        PaginationBar(currentPage: _page, totalPages: _pages, onPage: (page) { setState(() => _page = page); _load(); }),
      ],
    );
  }

  Widget _section(String title, List<JsonMap> items, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(title, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 8),
          Chip(label: Text('(${items.length})'), backgroundColor: titleColor.withValues(alpha: 0.10), labelStyle: TextStyle(color: titleColor, fontWeight: FontWeight.w900), side: BorderSide.none),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(color: const Color(0x80F8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
            child: Text('No ${title.toLowerCase()} methods.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800)),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 86),
              itemBuilder: (_, index) => _card(items[index]),
            );
          }),
      ],
    );
  }

  Widget _card(JsonMap item) {
    final color = colorFromHex(fieldText(item, 'color', '#3b82f6'), const Color(0xFF3B82F6));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        Container(width: 50, height: 58, decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(17)), child: Icon(iconForName(fieldText(item, 'icon', 'CreditCard')), color: color)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fieldText(item, 'name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(fieldText(item, 'description', 'No description'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x662D2520), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        ActionButtons(onView: () => _view(item), onEdit: () => _save(editing: item), onDelete: () => _delete(item)),
      ]),
    );
  }
}

class _MethodFormData {
  final String name; final int typeId; final String icon; final Color color; final String description; final int status;
  const _MethodFormData({required this.name, required this.typeId, required this.icon, required this.color, required this.description, required this.status});
  Map<String, dynamic> toJson() => { 'name': name, 'type_id': '$typeId', 'icon': icon, 'color': hexFromColor(color), 'description': description, 'status': '$status' };
}

class MethodFormDialog extends StatefulWidget {
  final JsonMap? editing; final List<String> icons; final List<Color> colors;
  const MethodFormDialog({super.key, this.editing, required this.icons, required this.colors});
  @override
  State<MethodFormDialog> createState() => _MethodFormDialogState();
}

class _MethodFormDialogState extends State<MethodFormDialog> {
  late final TextEditingController _name; late final TextEditingController _description; late int _typeId; late String _icon; late Color _color; late int _status;

  @override
  void initState() {
    super.initState();
    final item = widget.editing ?? {};
    _name = TextEditingController(text: fieldText(item, 'name'));
    _description = TextEditingController(text: fieldText(item, 'description'));
    _typeId = fieldInt(item, 'type_id', 1);
    _icon = fieldText(item, 'icon', 'CreditCard');
    _color = colorFromHex(fieldText(item, 'color', '#3b82f6'), const Color(0xFF3B82F6));
    _status = fieldInt(item, 'status', 1);
  }

  @override
  void dispose() { _name.dispose(); _description.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.editing == null ? 'Add Payment Method' : 'Edit Payment Method', style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 460, 
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _name, decoration: sunsetFieldDecoration('Method Name')),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _typeId, decoration: sunsetFieldDecoration('Type'),
              items: const [DropdownMenuItem(value: 1, child: Text('Expense')), DropdownMenuItem(value: 2, child: Text('Income'))],
              onChanged: (value) => setState(() => _typeId = value ?? 1),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: widget.icons.map((name) {
                final selected = _icon == name;
                return InkWell(
                  onTap: () => setState(() => _icon = name), borderRadius: BorderRadius.circular(13),
                  child: Container(width: 44, height: 44, decoration: BoxDecoration(color: selected ? SunsetColors.secondary : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(13)), child: Icon(iconForName(name), color: selected ? Colors.white : SunsetColors.dark)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: widget.colors.map((color) {
                final selected = _color == color;
                return InkWell(
                  onTap: () => setState(() => _color = color), borderRadius: BorderRadius.circular(99),
                  child: Container(width: 34, height: 34, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: selected ? SunsetColors.secondary : Colors.transparent, width: 3)), child: selected ? const Icon(Icons.circle, color: Colors.white, size: 10) : null),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(controller: _description, decoration: sunsetFieldDecoration('Brief description...')),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _status, decoration: sunsetFieldDecoration('Status'),
              items: const [DropdownMenuItem(value: 1, child: Text('Active')), DropdownMenuItem(value: 0, child: Text('Inactive'))],
              onChanged: (value) => setState(() => _status = value ?? 1),
            ),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(context, _MethodFormData(name: _name.text.trim(), typeId: _typeId, icon: _icon, color: _color, description: _description.text.trim(), status: _status));
          },
          style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Save Method'),
        ),
      ],
    );
  }
}