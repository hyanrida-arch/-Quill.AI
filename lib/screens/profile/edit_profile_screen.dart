// lib/screens/profile/edit_profile_screen.dart
//
// Reached from Account -> ⋮ -> Account. Real writes to Supabase now that
// accounts are real (see AuthService) — previously that menu item just
// showed a "coming soon" snackbar with no screen behind it at all.
//
// Name + phone save through AuthService.updateProfile (profiles table).
// The password section is optional and separate — left blank, it's simply
// not touched; filled in, it goes through AuthService.updatePassword,
// which relies on the current session as proof of identity rather than
// asking for the old password (same pattern as most apps' in-session
// "change password", as opposed to the emailed reset-link flow).
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final ValueChanged<String> onSaved;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.onSaved,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  final _phoneCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _showPwd = false;
  bool _loading = false;
  String? _error;
  bool _loadingPhone = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    final profile = await AuthService.fetchProfile();
    if (!mounted) return;
    setState(() {
      _phoneCtrl.text = (profile?['phone'] as String?) ?? '';
      _loadingPhone = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  bool get _wantsPasswordChange =>
      _newPwdCtrl.text.isNotEmpty || _confirmPwdCtrl.text.isNotEmpty;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name can\'t be empty.');
      return;
    }
    if (_wantsPasswordChange) {
      if (_newPwdCtrl.text.length < 6) {
        setState(() => _error = 'New password must be at least 6 characters.');
        return;
      }
      if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
        setState(() => _error = 'Passwords don\'t match.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final profileResult = await AuthService.updateProfile(
      displayName: name,
      phone: _phoneCtrl.text.trim(),
    );
    if (!profileResult.success) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = profileResult.error;
      });
      return;
    }

    if (_wantsPasswordChange) {
      final pwdResult = await AuthService.updatePassword(_newPwdCtrl.text);
      if (!pwdResult.success) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = pwdResult.error;
        });
        return;
      }
    }

    if (!mounted) return;
    widget.onSaved(name);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.deepNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const Text('Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
            const SizedBox(height: 12),
            _field(label: 'Full Name', controller: _nameCtrl),
            const SizedBox(height: 14),
            _field(
              label: 'Phone',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              hint: _loadingPhone ? 'Loading…' : 'e.g. +212 6 12 34 56 78',
            ),
            const SizedBox(height: 14),
            _readOnlyField(label: 'Email', value: widget.currentEmail),
            const SizedBox(height: 28),
            const Text('Change Password',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
            const SizedBox(height: 4),
            const Text('Leave blank to keep your current password.',
                style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
            const SizedBox(height: 12),
            _field(
              label: 'New Password',
              controller: _newPwdCtrl,
              obscure: !_showPwd,
              trailing: IconButton(
                icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18, color: AppColors.slateGray),
                onPressed: () => setState(() => _showPwd = !_showPwd),
              ),
            ),
            const SizedBox(height: 14),
            _field(label: 'Confirm New Password', controller: _confirmPwdCtrl, obscure: !_showPwd),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepNavy,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(_loading ? 'Saving…' : 'Save Changes',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType? keyboardType,
    String? hint,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.subtleGray,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: trailing,
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slateGray)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: AppColors.subtleGray, borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.slateGray)),
        ),
      ],
    );
  }
}
