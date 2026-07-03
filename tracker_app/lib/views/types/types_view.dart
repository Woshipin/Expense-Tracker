import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../shared/crud_helpers.dart';

class TypesView extends StatefulWidget {
  const TypesView({super.key});

  @override
  State<TypesView> createState() => _TypesViewState();
}

class _TypesViewState extends State<TypesView> {
  final _search = DebouncedSearchController();
  List<JsonMap> _types = [];
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
      final result = await fetchPaged('/types', page: _page, params: {
        if (_search.controller.text.trim().isNotEmpty) 'search': _search.controller.text.trim(),
        if (_status != 'all') 'status': _status,
      });
      if (!mounted) return;
      setState(() {
        _types = result.items;
        _pages = result.totalPages;
      });
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to fetch types.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({JsonMap? editing}) async {
    final result = await showDialog<_TypeFormData>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (_) => TypeFormDialog(editing: editing),
    );
    if (result == null) return;
    try {
      if (editing == null) {
        await ApiClient().dio.post('/types', data: result.toJson());
        if (mounted) SunsetToast.show(context, 'Type added successfully!');
      } else {
        await ApiClient().dio.put('/types/${editing['id']}', data: result.toJson());
        if (mounted) SunsetToast.show(context, 'Type updated successfully!');
      }
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Operation failed.');
    }
  }

  Future<void> _delete(JsonMap item) async {
    final ok = await confirmDeleteDialog(
      context, title: 'Delete Type', name: fieldText(item, 'name'), icon: Icons.layers_outlined,
    );
    if (!ok) return;
    try {
      await ApiClient().dio.delete('/types/${item['id']}');
      if (mounted) SunsetToast.show(context, 'Type deleted successfully');
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to delete type');
    }
  }

  void _view(JsonMap item) {
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
                child: const Text('Type Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(color: SunsetColors.secondary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.layers_outlined, color: SunsetColors.secondary, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(fieldText(item, 'name'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      StatusBadge(status: item['status']),
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

  // 🌟 核心修复：完全响应式的过滤条
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
            onChanged: (_) => _search.onChanged(() { _page = 1; _load(); }), 
            decoration: sunsetFieldDecoration('Search types...', icon: Icons.search)
          );

          final dropdownField = DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: sunsetFieldDecoration('All Status'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Status')),
              DropdownMenuItem(value: '1', child: Text('Active')),
              DropdownMenuItem(value: '0', child: Text('Inactive')),
            ],
            onChanged: (value) { if (value == null) return; setState(() { _status = value; _page = 1; }); _load(); },
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
      title: 'Transaction Types',
      subtitle: 'Manage global transaction types.',
      action: PrimaryActionButton(label: 'Add Type', icon: Icons.add, onPressed: () => _save()),
      children: [
        _buildResponsiveToolbar(), // 使用响应式组件替代旧的 ToolbarBox
        const SizedBox(height: 20),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: SunsetColors.primary)))
        else if (_types.isEmpty) _empty('No types found.')
        else LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100 ? 4 : constraints.maxWidth >= 760 ? 3 : constraints.maxWidth >= 520 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _types.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 150),
              itemBuilder: (_, index) {
                final item = _types[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: SunsetColors.secondary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.layers_outlined, color: SunsetColors.secondary)),
                        const Spacer(),
                        ActionButtons(onView: () => _view(item), onEdit: () => _save(editing: item), onDelete: () => _delete(item)),
                      ]),
                      const Spacer(),
                      Text(fieldText(item, 'name'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: SunsetColors.dark, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      StatusBadge(status: item['status']),
                    ],
                  ),
                );
              },
            );
          },
        ),
        PaginationBar(currentPage: _page, totalPages: _pages, onPage: (page) { setState(() => _page = page); _load(); }),
      ],
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800)),
    );
  }
}

class _TypeFormData {
  final String name; final int status;
  const _TypeFormData({required this.name, required this.status});
  Map<String, dynamic> toJson() => {'name': name, 'status': '$status'};
}

class TypeFormDialog extends StatefulWidget {
  final JsonMap? editing;
  const TypeFormDialog({super.key, this.editing});
  @override
  State<TypeFormDialog> createState() => _TypeFormDialogState();
}

class _TypeFormDialogState extends State<TypeFormDialog> {
  late final TextEditingController _name; late int _status;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: fieldText(widget.editing ?? {}, 'name'));
    _status = fieldInt(widget.editing ?? {}, 'status', 1);
  }

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Text(widget.editing == null ? 'Add Type' : 'Edit Type', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _name, decoration: sunsetFieldDecoration('Type Name')),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: _status, decoration: sunsetFieldDecoration('Status'),
                      items: const [DropdownMenuItem(value: 1, child: Text('Active')), DropdownMenuItem(value: 0, child: Text('Inactive'))],
                      onChanged: (value) => setState(() => _status = value ?? 1),
                    ),
                  ],
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
                      onPressed: () {
                        if (_name.text.trim().isEmpty) return;
                        Navigator.pop(context, _TypeFormData(name: _name.text.trim(), status: _status));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Save Type'),
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