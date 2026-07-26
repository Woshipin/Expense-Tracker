import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../categories/category_view.dart';
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
  List<TypeItem> _types = [];
  List<JsonMap> _methods = [];
  bool _loading = true;
  String _status = 'all';
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // 动态从 DB 加载 Types 和 Payment Methods
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 1. 获取 active 状态的 Types
      final typesRes = await ApiClient().dio.get('/types', queryParameters: {'status': '1'});
      final dynamic rawTypesPayload = typesRes.data;
      final List<dynamic> rawTypes = rawTypesPayload is Map<String, dynamic>
          ? (rawTypesPayload['data'] as List<dynamic>? ?? [])
          : (rawTypesPayload as List<dynamic>? ?? []);
      final types = rawTypes.map((t) => TypeItem.fromJson(Map<String, dynamic>.from(t))).toList();

      // 2. 获取 Payment Methods
      final result = await fetchPaged('/payment-methods', page: _page, params: {
        if (_search.controller.text.trim().isNotEmpty) 'search': _search.controller.text.trim(),
        if (_status != 'all') 'status': _status,
      });
      
      var items = result.items;
      if (_status != 'all') items = items.where((m) => fieldText(m, 'status') == _status).toList();
      
      if (!mounted) return;
      setState(() { 
        _types = types;
        _methods = items; 
        _pages = result.totalPages; 
      });
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to fetch payment methods.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({JsonMap? editing}) async {
    final form = await showDialog<_MethodFormData>(
      context: context, 
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (_) => MethodFormDialog(editing: editing, typesList: _types, icons: icons, colors: colors),
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
      _loadData();
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
      _loadData();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to delete payment method');
    }
  }

  void _view(JsonMap item) {
    final color = colorFromHex(fieldText(item, 'color', '#3b82f6'), const Color(0xFF3B82F6));
    final typeId = fieldInt(item, 'type_id', 1);
    final typeName = _types.firstWhere((t) => t.id == typeId, orElse: () => TypeItem(id: typeId, name: typeId == 2 ? 'Income' : 'Expense', status: 1)).name;
    final isActive = fieldInt(item, 'status', 1) == 1;

    showDialog<void>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text('Method Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 82, height: 96,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                        child: Icon(iconForName(fieldText(item, 'icon', 'CreditCard')), color: color, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(fieldText(item, 'name'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),

                      // 🌟 同时显示 Type 和 Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            label: Text(typeName), 
                            backgroundColor: const Color(0xFFFFF7ED), 
                            labelStyle: const TextStyle(color: SunsetColors.primary, fontWeight: FontWeight.w900, fontSize: 12), 
                            side: BorderSide.none
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(isActive ? 'Active' : 'Inactive'), 
                            backgroundColor: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2), 
                            labelStyle: TextStyle(color: isActive ? const Color(0xFF059669) : Colors.red, fontWeight: FontWeight.w900, fontSize: 12), 
                            side: BorderSide(color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA))
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(fieldText(item, 'description', 'No description provided.'), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.dark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          final searchField = TextField(
            controller: _search.controller, 
            onChanged: (_) => _search.onChanged(() { _page = 1; _loadData(); }), 
            decoration: sunsetFieldDecoration('Search payment methods...', icon: Icons.search)
          );

          final dropdownField = DropdownButtonFormField<String>(
            initialValue: _status, 
            decoration: sunsetFieldDecoration('All Status'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Status')), 
              DropdownMenuItem(value: '1', child: Text('Active')), 
              DropdownMenuItem(value: '0', child: Text('Inactive'))
            ],
            onChanged: (value) { if (value == null) return; setState(() { _status = value; _page = 1; }); _loadData(); },
          );

          if (isMobile) {
            return Column(
              children: [
                searchField,
                const SizedBox(height: 12),
                dropdownField,
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                Expanded(child: dropdownField),
              ],
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Payment Methods',
      subtitle: 'Manage system payment channels and their availability.',
      action: PrimaryActionButton(label: 'Add Method', icon: Icons.add, onPressed: () => _save()),
      children: [
        _buildResponsiveToolbar(),
        const SizedBox(height: 22),
        if (_loading) 
          const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: SunsetColors.primary)))
        else ...[
          if (_types.isEmpty) _buildNoTypesWarningCard(),
          _buildGroupedSections(),
        ],
        PaginationBar(currentPage: _page, totalPages: _pages, onPage: (page) { setState(() => _page = page); _loadData(); }),
      ],
    );
  }

  Widget _buildNoTypesWarningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("No Payment Types Found", style: TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Text("You haven't configured any active transaction types in database yet.", style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 动态多栏分组
  Widget _buildGroupedSections() {
    if (_types.isEmpty) {
      final income = _methods.where((m) => fieldInt(m, 'type_id', 1) == 2).toList();
      final expense = _methods.where((m) => fieldInt(m, 'type_id', 1) == 1).toList();

      return Column(
        children: [
          _section('Income', income, const Color(0xFF059669)),
          const SizedBox(height: 28),
          _section('Expense', expense, SunsetColors.expense),
        ],
      );
    }

    return Column(
      children: _types.map((typeObj) {
        final isIncome = typeObj.name.toLowerCase().contains('income');
        final titleColor = isIncome ? const Color(0xFF059669) : SunsetColors.expense;
        final items = _methods.where((m) => fieldInt(m, 'type_id', 1) == typeObj.id).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 28.0),
          child: _section(typeObj.name, items, titleColor),
        );
      }).toList(),
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
            child: Text('No ${title.toLowerCase()} channels.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800)),
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

  // 卡片带有 Status 胶囊标签
  Widget _card(JsonMap item) {
    final color = colorFromHex(fieldText(item, 'color', '#3b82f6'), const Color(0xFF3B82F6));
    final isActive = fieldInt(item, 'status', 1) == 1;

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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      fieldText(item, 'name'), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w900)
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF059669) : Colors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
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
  final JsonMap? editing; final List<TypeItem> typesList; final List<String> icons; final List<Color> colors;
  const MethodFormDialog({super.key, this.editing, required this.typesList, required this.icons, required this.colors});
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
    
    final defaultType = widget.typesList.isNotEmpty ? widget.typesList.first.id : 1;
    _typeId = fieldInt(item, 'type_id', defaultType);
    _icon = fieldText(item, 'icon', 'CreditCard');
    _color = colorFromHex(fieldText(item, 'color', '#3b82f6'), const Color(0xFF3B82F6));
    _status = fieldInt(item, 'status', 1);
  }

  @override
  void dispose() { _name.dispose(); _description.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.editing == null ? 'Add Method' : 'Edit Method', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    TextField(controller: _name, decoration: sunsetFieldDecoration('Method Name')),
                    const SizedBox(height: 14),

                    // 🌟 无 Type 预警框
                    if (widget.typesList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                            SizedBox(width: 8),
                            Expanded(child: Text("No Type available. Please add a Type first.", style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue: _typeId, 
                        decoration: sunsetFieldDecoration('Type'),
                        items: widget.typesList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
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
                  ]
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context), 
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                      child: const Text('Cancel')
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.typesList.isEmpty ? null : () {
                        if (_name.text.trim().isEmpty) return;
                        Navigator.pop(context, _MethodFormData(name: _name.text.trim(), typeId: _typeId, icon: _icon, color: _color, description: _description.text.trim(), status: _status));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Save Method'),
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}