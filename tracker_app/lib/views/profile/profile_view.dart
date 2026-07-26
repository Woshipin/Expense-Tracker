import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../shared/crud_helpers.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  JsonMap? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient().dio.get('/me');
      if (!mounted) return;
      setState(() => _user = Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to load profile data');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    
    final result = await showDialog<_ProfileFormData>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (_) => ProfileFormDialog(user: _user!),
    );
    
    if (result == null) return;
    
    try {
      // 🌟 【核心修复】：采用标准的 JSON Payload 提交 Base64，100% 确保图片存入 DB 且不会触发 422 报错
      final Map<String, dynamic> reqData = {
        'full_name': result.fullName,
        'email': result.email,
      };

      if (result.imageBase64 != null) {
        reqData['image_base64'] = result.imageBase64;
      }

      final response = await ApiClient().dio.post('/profile', data: reqData);

      final data = response.data is Map ? response.data['user'] : null;
      if (!mounted) return;
      
      if (data is Map) setState(() => _user = Map<String, dynamic>.from(data));
      SunsetToast.show(context, 'Profile details updated successfully!');
      
      _load();
      
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to update profile');
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<_PasswordFormData>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (_) => const PasswordFormDialog(),
    );
    if (result == null) return;
    try {
      await ApiClient().dio.put('/profile/password', data: result.toJson());
      if (mounted) SunsetToast.show(context, 'Password changed securely.');
    } on DioException catch (e) {
      if (mounted) showApiError(context, e, 'Failed to change password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Profile',
      subtitle: 'Manage your personal information and security settings.',
      children: [
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(64), child: CircularProgressIndicator(color: SunsetColors.primary)))
        else if (_user == null) const Center(child: Text('Profile unavailable.'))
        else _profileCard(_user!),
      ],
    );
  }

  Widget _profileCard(JsonMap user) {
    final provider = fieldText(user, 'provider');
    final hasProvider = provider.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.20), width: 2),
        boxShadow: [BoxShadow(color: SunsetColors.primary.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            
            // 左侧/顶部区域 (用户头像、角色、名字)
            final avatarPane = Container(
              width: wide ? 380 : double.infinity, 
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ), 
                borderRadius: wide ? const BorderRadius.horizontal(left: Radius.circular(24)) : const BorderRadius.vertical(top: Radius.circular(24)),
                border: wide ? Border(right: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10))) : Border(bottom: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10))),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  _avatar(user, size: 140), 
                  const SizedBox(height: 16), 
                  RoleBadge(role: user['role']), 
                  const SizedBox(height: 14),
                  Text(fieldText(user, 'full_name'), textAlign: TextAlign.center, style: const TextStyle(color: SunsetColors.dark, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(fieldText(user, 'email'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0x992D2520), fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            );
            
            // 右侧/底部详情区域 (Provider, System Role, Account Status)
            final detailPane = Padding(
              padding: const EdgeInsets.all(34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  _infoRow(Icons.verified_user_outlined, 'Channel / Provider', ProviderBadge(provider: user['provider'])), 
                  const SizedBox(height: 24),
                  _infoRow(Icons.lock_outline, 'System Role', Text(_roleName(user['role']), style: const TextStyle(color: SunsetColors.dark, fontSize: 16, fontWeight: FontWeight.w900))), 
                  const SizedBox(height: 24),
                  _infoRow(Icons.person_outline, 'Account Status', StatusBadge(status: user['status'])),
                ],
              ),
            );

            return wide ? IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [avatarPane, Expanded(child: detailPane)])) : Column(children: [avatarPane, detailPane]);
          }),
          
          // 底部操作按钮区域
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, 
              border: Border(top: BorderSide(color: SunsetColors.primary.withValues(alpha: 0.10))), 
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              
              Widget btnEdit = ElevatedButton.icon(
                onPressed: _editProfile, 
                icon: const Icon(Icons.person_outline, size: 18), 
                label: const Text('Edit Profile & Avatar', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SunsetColors.secondary, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              );
              
              Widget btnPassword = hasProvider 
                ? OutlinedButton.icon(
                    onPressed: null, // 禁用
                    icon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey), 
                    label: Text('Password Managed via ${provider[0].toUpperCase()}${provider.substring(1)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100, 
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _changePassword, 
                    icon: const Icon(Icons.lock_outline, size: 18, color: SunsetColors.primary), 
                    label: const Text('Change Security Password', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SunsetColors.dark, 
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  );

              if (wide) { 
                return Row(children: [Expanded(child: btnEdit), const SizedBox(width: 14), Expanded(child: btnPassword)]); 
              } else { 
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [btnEdit, const SizedBox(height: 10), btnPassword]); 
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Icon(icon, color: SunsetColors.secondary, size: 20), 
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(label, style: const TextStyle(color: Color(0x662D2520), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)), 
              const SizedBox(height: 6), 
              value
            ]
          ),
        ),
      ]
    );
  }

  // 🌟 核心：为图片链接增加 Cache-Busting 时间戳，确保更新头像后全自动即时刷新
  String _fixImageUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty || originalUrl == 'null') return '';
    
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    if (originalUrl.startsWith('http') && !originalUrl.contains('localhost') && !originalUrl.contains('127.0.0.1') && !originalUrl.contains('192.168.') && !originalUrl.contains('10.200.')) {
      return originalUrl.contains('api/images/') ? '$originalUrl?t=$timeStamp' : originalUrl;
    }

    try {
      final uri = Uri.parse(originalUrl);
      final filename = uri.pathSegments.last;
      String apiBase = ApiClient().currentBaseUrl;
      return '$apiBase/images/$filename?t=$timeStamp';
    } catch (_) {
      return '$originalUrl?t=$timeStamp';
    }
  }

  Widget _avatar(JsonMap user, {double size = 120}) {
    final rawImage = fieldText(user, 'image_path');
    final safeImage = _fixImageUrl(rawImage);

    if (safeImage.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28), 
          child: Image.network(
            safeImage, width: size, height: size, fit: BoxFit.cover, 
            errorBuilder: (context, error, stackTrace) => _avatarFallback(user, size),
          ),
        ),
      );
    }
    return _avatarFallback(user, size);
  }

  Widget _avatarFallback(JsonMap user, double size) {
    return Container(
      width: size, 
      height: size, 
      alignment: Alignment.center, 
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [SunsetColors.primary, SunsetColors.secondary]), 
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6))],
      ), 
      child: Text(
        initials(fieldText(user, 'full_name')), 
        style: TextStyle(color: Colors.white, fontSize: size / 2.6, fontWeight: FontWeight.w900)
      ),
    );
  }

  String _roleName(dynamic role) {
    return switch (role.toString()) { 
      '0' => 'Super Administrator', 
      '1' => 'Administrator', 
      '2' => 'Premium Subscriber', 
      _ => 'Standard Basic User' 
    };
  }
}

class _ProfileFormData {
  final String fullName; 
  final String email;
  final String? imageBase64;
  final Uint8List? imageBytes;

  const _ProfileFormData({required this.fullName, required this.email, this.imageBase64, this.imageBytes});
}

class ProfileFormDialog extends StatefulWidget {
  final JsonMap user;
  const ProfileFormDialog({super.key, required this.user});
  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog> {
  late final TextEditingController _name; 
  late final TextEditingController _email;
  String _imageName = ''; 
  Uint8List? _imageBytes; 
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: fieldText(widget.user, 'full_name'));
    _email = TextEditingController(text: fieldText(widget.user, 'email'));
  }

  @override
  void dispose() { _name.dispose(); _email.dispose(); super.dispose(); }
  
  // 选择图片并生成 100% 稳定的 Base64 编码格式
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 1024, 
        maxHeight: 1024, 
        imageQuality: 85
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() { 
          _imageName = image.name; 
          _imageBytes = bytes; 
          _imageBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) SunsetToast.show(context, 'Failed to pick image', type: SunsetToastType.error);
    }
  }

  String _fixImageUrl(String originalUrl) {
    if (originalUrl.isEmpty || originalUrl == 'null') return '';
    try {
      final uri = Uri.parse(originalUrl);
      final filename = uri.pathSegments.last;
      return '${ApiClient().currentBaseUrl}/images/$filename';
    } catch (_) { return originalUrl; }
  }

  Widget _buildAvatarPreview() {
    if (_imageBytes != null) return ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.memory(_imageBytes!, width: 80, height: 80, fit: BoxFit.cover));
    final rawOldImage = fieldText(widget.user, 'image_path');
    final safeOldImage = _fixImageUrl(rawOldImage);
    if (safeOldImage.isNotEmpty) return ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.network(safeOldImage, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildEmptyPlaceholder()));
    return _buildEmptyPlaceholder();
  }

  Widget _buildEmptyPlaceholder() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28), const SizedBox(height: 4), Text('Empty', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold))]);
  }

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
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: SunsetColors.dark)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)), child: _buildAvatarPreview()),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('UPDATE AVATAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickImage, 
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(border: Border.all(color: SunsetColors.primary.withValues(alpha: 0.80)), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)), child: const Text('选择文件', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(_imageName.isEmpty ? '未选择任何文件' : _imageName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('FULL NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)), 
                    const SizedBox(height: 6),
                    TextField(controller: _name, decoration: sunsetFieldDecoration('')),
                    
                    const SizedBox(height: 20),
                    const Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.8)), 
                    const SizedBox(height: 6),
                    TextField(controller: _email, decoration: sunsetFieldDecoration('')),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context), 
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold))
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) return;
                        Navigator.pop(context, _ProfileFormData(fullName: _name.text.trim(), email: _email.text.trim(), imageBase64: _imageBase64, imageBytes: _imageBytes));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: SunsetColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _PasswordFormData {
  final String current; final String password; final String confirm;
  const _PasswordFormData({required this.current, required this.password, required this.confirm});
  Map<String, dynamic> toJson() => { 'current_password': current, 'new_password': password, 'new_password_confirmation': confirm };
}

class PasswordFormDialog extends StatefulWidget {
  const PasswordFormDialog({super.key});
  @override
  State<PasswordFormDialog> createState() => _PasswordFormDialogState();
}

class _PasswordFormDialogState extends State<PasswordFormDialog> {
  final _current = TextEditingController(); final _password = TextEditingController(); final _confirm = TextEditingController();
  bool _obsCurrent = true; bool _obsNew = true; bool _obsConfirm = true;

  @override
  void dispose() { _current.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

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
              child: const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: SunsetColors.dark)),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: _current, obscureText: _obsCurrent, decoration: sunsetFieldDecoration('Current Password', suffixIcon: _eyeIcon(_obsCurrent, () => setState(() => _obsCurrent = !_obsCurrent)))),
                    const SizedBox(height: 14),
                    TextField(controller: _password, obscureText: _obsNew, decoration: sunsetFieldDecoration('New Password', suffixIcon: _eyeIcon(_obsNew, () => setState(() => _obsNew = !_obsNew)))),
                    const SizedBox(height: 14),
                    TextField(controller: _confirm, obscureText: _obsConfirm, decoration: sunsetFieldDecoration('Confirm New Password', suffixIcon: _eyeIcon(_obsConfirm, () => setState(() => _obsConfirm = !_obsConfirm)))),
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
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold))
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_current.text.isEmpty || _password.text.isEmpty || _confirm.text.isEmpty) return;
                        Navigator.pop(context, _PasswordFormData(current: _current.text, password: _password.text, confirm: _confirm.text));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _eyeIcon(bool isObscured, VoidCallback onTap) {
    return IconButton(icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: onTap);
  }
}