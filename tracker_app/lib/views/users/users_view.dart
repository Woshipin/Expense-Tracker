import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../shared/crud_helpers.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final _search = DebouncedSearchController();
  List<JsonMap> _items = [];
  bool _loading = true;
  
  String _provider = 'all';
  String _role = 'all';
  String _status = 'all';
  int _page = 1;
  int _pages = 1;

  final String endpoint = '/users';
  final String singular = 'User';
  final String plural = 'Users';

  // 选项定义
  static const Map<String, String> _providerOptions = {'all': 'All Channels', 'standard': 'Standard', 'google': 'Google', 'facebook': 'Facebook'};
  static const Map<String, String> _roleOptions = {'all': 'All Roles', '0': 'SuperAdmin', '1': 'Admin', '2': 'Premium User', '3': 'Basic User'};
  static const Map<String, String> _statusOptions = {'all': 'All Status', '1': 'Active', '0': 'Inactive'};

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
      final result = await fetchPaged(endpoint, page: _page, params: {
        if (_search.controller.text.trim().isNotEmpty) 'search': _search.controller.text.trim(),
        if (_provider != 'all') 'provider': _provider,
        if (_role != 'all') 'role': _role,
        if (_status != 'all') 'status': _status,
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
    setState(() {
      _provider = 'all';
      _role = 'all';
      _status = 'all';
      _page = 1;
    });
    _load();
  }

  Future<void> _save({JsonMap? editing}) async {
    final form = await showDialog<_UserFormData>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (_) => UserFormDialog(editing: editing),
    );
    if (form == null) return;
    try {
      if (editing == null) {
        await ApiClient().dio.post(endpoint, data: form.toJson(includeEmptyPassword: true));
        if (mounted) SunsetToast.show(context, '$singular added successfully!');
      } else {
        await ApiClient().dio.put('$endpoint/${editing['id']}', data: form.toJson(includeEmptyPassword: false));
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
      name: fieldText(item, 'full_name'), 
      icon: Icons.person_outline,
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
              _avatar(item, size: 96),
              const SizedBox(height: 16),
              Text(fieldText(item, 'full_name'), textAlign: TextAlign.center, style: const TextStyle(color: SunsetColors.dark, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(fieldText(item, 'email'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0x992D2520), fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, 
                children: [
                  RoleBadge(role: item['role']), 
                  ProviderBadge(provider: item['provider']), 
                  StatusBadge(status: item['status']),
                ]
              ),
            ]
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
  
  Widget _customDropdown(String value, String hint, Map<String, String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
      decoration: _customFilterDecoration(hint),
      items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13, color: SunsetColors.dark)))).toList(),
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

  Widget _avatar(JsonMap user, {double size = 48}) {
    final image = fieldText(user, 'image_path');
    if (image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4), 
        child: Image.network(image, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(user, size))
      );
    }
    return _avatarFallback(user, size);
  }

  Widget _avatarFallback(JsonMap user, double size) {
    return Container(
      width: size, height: size, alignment: Alignment.center, 
      decoration: BoxDecoration(color: SunsetColors.secondary, borderRadius: BorderRadius.circular(size / 4)), 
      child: Text(initials(fieldText(user, 'full_name')), style: TextStyle(color: Colors.white, fontSize: size / 3, fontWeight: FontWeight.w900))
    );
  }

  // ---------------- 构建页面主体 ----------------
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;

    return PageScaffold(
      title: plural,
      subtitle: 'Manage system users, roles, and status.',
      action: PrimaryActionButton(label: 'Add $singular', icon: Icons.add, onPressed: () => _save()),
      children: [
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
        Expanded(flex: 2, child: _customDropdown(_provider, 'All Channels', _providerOptions, (value) { setState(() { _provider = value; _page = 1; }); _load(); })),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _customDropdown(_role, 'All Roles', _roleOptions, (value) { setState(() { _role = value; _page = 1; }); _load(); })),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _customDropdown(_status, 'All Status', _statusOptions, (value) { setState(() { _status = value; _page = 1; }); _load(); })),
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
        Row(children: [ 
          Expanded(child: _customDropdown(_provider, 'All Channels', _providerOptions, (value) { setState(() { _provider = value; _page = 1; }); _load(); })), 
          const SizedBox(width: 12), 
          Expanded(child: _customDropdown(_role, 'All Roles', _roleOptions, (value) { setState(() { _role = value; _page = 1; }); _load(); })),
          const SizedBox(width: 12), 
          Expanded(child: _customDropdown(_status, 'All Status', _statusOptions, (value) { setState(() { _status = value; _page = 1; }); _load(); })),
        ]),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        _customSearchField(),
        const SizedBox(height: 12),
        _customDropdown(_provider, 'All Channels', _providerOptions, (value) { setState(() { _provider = value; _page = 1; }); _load(); }),
        const SizedBox(height: 12),
        _customDropdown(_role, 'All Roles', _roleOptions, (value) { setState(() { _role = value; _page = 1; }); _load(); }),
        const SizedBox(height: 12),
        _customDropdown(_status, 'All Status', _statusOptions, (value) { setState(() { _status = value; _page = 1; }); _load(); }),
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
    const double colUser = 280; const double colEmail = 220; const double colChannel = 120;
    const double colRole = 140; const double colStatus = 100; const double colActions = 120;
    const double totalWidth = colUser + colEmail + colChannel + colRole + colStatus + colActions + 32;
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
                  SizedBox(width: colUser, child: Text('User', style: headerStyle)),
                  SizedBox(width: colEmail, child: Text('Email', style: headerStyle)),
                  SizedBox(width: colChannel, child: Text('Channel', style: headerStyle)),
                  SizedBox(width: colRole, child: Text('Role', style: headerStyle)),
                  SizedBox(width: colStatus, child: Text('Status', style: headerStyle)),
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
                        SizedBox(
                          width: colUser, 
                          child: Row(children: [ 
                            _avatar(item, size: 38), 
                            const SizedBox(width: 12), 
                            Expanded(child: Text(fieldText(item, 'full_name'), style: const TextStyle(fontWeight: FontWeight.bold, color: SunsetColors.dark), overflow: TextOverflow.ellipsis)) 
                          ])
                        ),
                        SizedBox(width: colEmail, child: Text(fieldText(item, 'email'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        SizedBox(width: colChannel, child: Align(alignment: Alignment.centerLeft, child: ProviderBadge(provider: item['provider']))),
                        SizedBox(width: colRole, child: Align(alignment: Alignment.centerLeft, child: RoleBadge(role: item['role']))),
                        SizedBox(width: colStatus, child: Align(alignment: Alignment.centerLeft, child: StatusBadge(status: item['status']))),
                        SizedBox(width: colActions, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [ 
                          InkWell(onTap: () => _view(item), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.blueAccent))), 
                          const SizedBox(width: 8), 
                          InkWell(onTap: () => _save(editing: item), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 18, color: Colors.green))), 
                          const SizedBox(width: 8), 
                          InkWell(onTap: () => _delete(item), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent))) 
                        ])),
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
              _avatar(item, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fieldText(item, 'full_name'), style: const TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(fieldText(item, 'email'), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              RoleBadge(role: item['role']), 
              ProviderBadge(provider: item['provider']), 
              StatusBadge(status: item['status']),
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

  // ---- 统一底部分页器 ----
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

class _UserFormData {
  final String fullName; final String email; final String password; final int role; final int status;
  const _UserFormData({required this.fullName, required this.email, required this.password, required this.role, required this.status});
  Map<String, dynamic> toJson({required bool includeEmptyPassword}) => { 'full_name': fullName, 'email': email, if (includeEmptyPassword || password.isNotEmpty) 'password': password, 'role': '$role', 'status': '$status' };
}

class UserFormDialog extends StatefulWidget {
  final JsonMap? editing;
  const UserFormDialog({super.key, this.editing});
  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  late final TextEditingController _name; 
  late final TextEditingController _email; 
  late final TextEditingController _password; 
  late int _role; 
  late int _status;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final user = widget.editing ?? {};
    _name = TextEditingController(text: fieldText(user, 'full_name'));
    _email = TextEditingController(text: fieldText(user, 'email'));
    _password = TextEditingController();
    _role = fieldInt(user, 'role', 3);
    _status = fieldInt(user, 'status', 1);
  }

  @override
  void dispose() { 
    _name.dispose(); 
    _email.dispose(); 
    _password.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    // 使用自定义 Dialog 以保证自适应和按钮同行
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
                  Text(widget.editing == null ? 'Add User' : 'Edit User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _name, decoration: sunsetFieldDecoration('Full Name')),
                    const SizedBox(height: 14),
                    TextField(controller: _email, decoration: sunsetFieldDecoration('Email')),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _password, 
                      obscureText: _obscurePassword, 
                      decoration: sunsetFieldDecoration(
                        widget.editing == null ? 'Password' : 'New Password (Optional)',
                        suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _intDropdown(_role, 'Role', const {0: 'SuperAdmin', 1: 'Admin', 2: 'Premium User', 3: 'Basic User'}, (value) => setState(() => _role = value)),
                    const SizedBox(height: 14),
                    _intDropdown(_status, 'Status', const {1: 'Active', 0: 'Inactive'}, (value) => setState(() => _status = value)),
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
                        if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return;
                        Navigator.pop(context, _UserFormData(fullName: _name.text.trim(), email: _email.text.trim(), password: _password.text, role: _role, status: _status));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Save User'),
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

  Widget _intDropdown(int value, String label, Map<int, String> options, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value, decoration: sunsetFieldDecoration(label),
      items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (value) { if (value != null) onChanged(value); },
    );
  }
}