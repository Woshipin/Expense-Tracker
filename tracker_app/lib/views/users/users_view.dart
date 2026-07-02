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
  List<JsonMap> _users = [];
  bool _loading = true;
  String _provider = 'all';
  String _role = 'all';
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
      final result = await fetchPaged('/users', page: _page, params: {
        if (_search.controller.text.trim().isNotEmpty) 'search': _search.controller.text.trim(),
        if (_provider != 'all') 'provider': _provider,
        if (_role != 'all') 'role': _role,
        if (_status != 'all') 'status': _status,
      });
      if (!mounted) return;
      setState(() {
        _users = result.items;
        _pages = result.totalPages;
      });
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to fetch users.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({JsonMap? editing}) async {
    final form = await showDialog<_UserFormData>(
      context: context,
      builder: (_) => UserFormDialog(editing: editing),
    );
    if (form == null) return;
    try {
      if (editing == null) {
        await ApiClient().dio.post('/users', data: form.toJson(includeEmptyPassword: true));
        if (mounted) SunsetToast.show(context, 'User added successfully!');
      } else {
        await ApiClient().dio.put('/users/${editing['id']}', data: form.toJson(includeEmptyPassword: false));
        if (mounted) SunsetToast.show(context, 'User updated successfully!');
      }
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Operation failed.');
    }
  }

  Future<void> _delete(JsonMap user) async {
    final ok = await confirmDeleteDialog(
      context, title: 'Delete User', name: fieldText(user, 'full_name'), icon: Icons.person_outline,
    );
    if (!ok) return;
    try {
      await ApiClient().dio.delete('/users/${user['id']}');
      if (mounted) SunsetToast.show(context, 'User deleted successfully');
      _load();
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to delete user');
    }
  }

  void _view(JsonMap user) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('User Details', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 560,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _avatar(user, size: 96),
            const SizedBox(height: 16),
            Text(fieldText(user, 'full_name'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(fieldText(user, 'email'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0x992D2520), fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              RoleBadge(role: user['role']), ProviderBadge(provider: user['provider']), StatusBadge(status: user['status']),
            ]),
          ]),
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
    final double fw = MediaQuery.of(context).size.width < 700 ? double.infinity : 220;

    return PageScaffold(
      title: 'Users',
      subtitle: 'Manage system users, roles, and status.',
      action: PrimaryActionButton(label: 'Add User', icon: Icons.add, onPressed: () => _save()),
      children: [
        ToolbarBox(children: [
          SizedBox(width: fw, child: TextField(controller: _search.controller, onChanged: (_) => _search.onChanged(() { _page = 1; _load(); }), decoration: sunsetFieldDecoration('Search users...', icon: Icons.search))),
          SizedBox(width: fw, child: _filter(_provider, 'All Channels', const {'all': 'All Channels', 'standard': 'Standard', 'google': 'Google', 'facebook': 'Facebook'}, (value) { setState(() { _provider = value; _page = 1; }); _load(); })),
          SizedBox(width: fw, child: _filter(_role, 'All Roles', const {'all': 'All Roles', '0': 'SuperAdmin', '1': 'Admin', '2': 'Premium User', '3': 'Basic User'}, (value) { setState(() { _role = value; _page = 1; }); _load(); })),
          SizedBox(width: fw, child: _filter(_status, 'All Status', const {'all': 'All Status', '1': 'Active', '0': 'Inactive'}, (value) { setState(() { _status = value; _page = 1; }); _load(); })),
        ]),
        const SizedBox(height: 20),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: SunsetColors.primary)))
        else if (_users.isEmpty) _empty()
        else LayoutBuilder(builder: (context, constraints) => constraints.maxWidth >= 880 ? _table() : _cards()),
        PaginationBar(currentPage: _page, totalPages: _pages, onPage: (page) { setState(() => _page = page); _load(); }),
      ],
    );
  }

  Widget _filter(String value, String hint, Map<String, String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value, decoration: sunsetFieldDecoration(hint),
      items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (value) { if (value != null) onChanged(value); },
    );
  }

  Widget _cards() {
    return Column(
      children: _users.map((user) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.shade100)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _avatar(user), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fieldText(user, 'full_name'), style: const TextStyle(color: SunsetColors.dark, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(fieldText(user, 'email'), style: const TextStyle(color: Color(0x992D2520), fontWeight: FontWeight.w600)),
              ])),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [RoleBadge(role: user['role']), ProviderBadge(provider: user['provider']), StatusBadge(status: user['status'])]),
            Align(alignment: Alignment.centerRight, child: ActionButtons(onView: () => _view(user), onEdit: () => _save(editing: user), onDelete: () => _delete(user))),
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
          columns: const [DataColumn(label: Text('Full Name')), DataColumn(label: Text('Email')), DataColumn(label: Text('Channel')), DataColumn(label: Text('Role')), DataColumn(label: Text('Status')), DataColumn(label: Text('Actions'))],
          rows: _users.map((user) => DataRow(cells: [
                DataCell(Row(children: [_avatar(user, size: 38), const SizedBox(width: 10), Text(fieldText(user, 'full_name'))])),
                DataCell(Text(fieldText(user, 'email'))), DataCell(ProviderBadge(provider: user['provider'])),
                DataCell(RoleBadge(role: user['role'])), DataCell(StatusBadge(status: user['status'])),
                DataCell(ActionButtons(onView: () => _view(user), onEdit: () => _save(editing: user), onDelete: () => _delete(user))),
              ])).toList(),
        ),
      ),
    );
  }

  Widget _avatar(JsonMap user, {double size = 48}) {
    final image = fieldText(user, 'image_path');
    if (image.isNotEmpty) return ClipRRect(borderRadius: BorderRadius.circular(size / 4), child: Image.network(image, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(user, size)));
    return _avatarFallback(user, size);
  }

  Widget _avatarFallback(JsonMap user, double size) {
    return Container(width: size, height: size, alignment: Alignment.center, decoration: BoxDecoration(color: SunsetColors.secondary, borderRadius: BorderRadius.circular(size / 4)), child: Text(initials(fieldText(user, 'full_name')), style: TextStyle(color: Colors.white, fontSize: size / 3, fontWeight: FontWeight.w900)));
  }

  Widget _empty() { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 48), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)), child: Text('No users found matching criteria.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800))); }
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
  late final TextEditingController _name; late final TextEditingController _email; late final TextEditingController _password; late int _role; late int _status;
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
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.editing == null ? 'Add User' : 'Edit User', style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 460, 
        child: SingleChildScrollView(
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
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return;
            Navigator.pop(context, _UserFormData(fullName: _name.text.trim(), email: _email.text.trim(), password: _password.text, role: _role, status: _status));
          },
          style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Save User'),
        ),
      ],
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