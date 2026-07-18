import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/qai_theme.dart';
import '../widgets/ shared_widgets.dart';

const _countries = [
  {'id': 'MA', 'name': 'Morocco', 'flag': '🇲🇦', 'suggested': true},
  {'id': 'DZ', 'name': 'Algeria', 'flag': '🇩🇿'},
  {'id': 'TN', 'name': 'Tunisia', 'flag': '🇹🇳'},
  {'id': 'EG', 'name': 'Egypt', 'flag': '🇪🇬'},
  {'id': 'SA', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
  {'id': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪'},
  {'id': 'FR', 'name': 'France', 'flag': '🇫🇷'},
  {'id': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
  {'id': 'US', 'name': 'United States', 'flag': '🇺🇸'},
  {'id': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
  {'id': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
  {'id': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
  {'id': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
  {'id': 'TR', 'name': 'Turkey', 'flag': '🇹🇷'},
  {'id': 'XX', 'name': 'Other…', 'flag': ''},
];

const _academicLevels = [
  'High School',
  'Undergraduate — 1st Year',
  'Undergraduate — 2nd Year',
  'Undergraduate — 3rd Year',
  'Undergraduate — 4th Year',
  "Master's Degree",
  'PhD / Doctorate',
  'Postdoctoral',
  'Professional Certification',
  'Other',
];

// ─── Bottom Sheet helper ──────────────────────────────────────
void showQBottomSheet({
  required BuildContext context,
  required String title,
  required Widget body,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, ctrl) => Column(
        children: [
          // Grabber
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: QAI.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: QAI.ink,
                      letterSpacing: -0.015 * 16,
                    )),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2EC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.close, size: 14, color: QAI.ink),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: QAI.border),
          Expanded(
            child: ListView(controller: ctrl, children: [body]),
          ),
        ],
      ),
    ),
  );
}

// ─── Demographics ─────────────────────────────────────────────
class DemographicsScreen extends StatefulWidget {
  final String country;
  final String institution;
  final String level;
  final void Function(String, String, String) onChange;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const DemographicsScreen({
    super.key,
    required this.country,
    required this.institution,
    required this.level,
    required this.onChange,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<DemographicsScreen> createState() => _DemographicsScreenState();
}

class _DemographicsScreenState extends State<DemographicsScreen> {
  late String _country;
  late String _institution;
  late String _level;

  @override
  void initState() {
    super.initState();
    _country = widget.country;
    _institution = widget.institution;
    _level = widget.level;
  }

  void _update({String? c, String? i, String? l}) {
    setState(() {
      if (c != null) _country = c;
      if (i != null) _institution = i;
      if (l != null) _level = l;
    });
    widget.onChange(_country, _institution, _level);
  }

  void _openCountrySheet() {
    showQBottomSheet(
      context: context,
      title: 'Select Country',
      body: _CountrySheetBody(
        value: _country,
        onSelect: (v) {
          Navigator.pop(context);
          _update(c: v);
        },
      ),
    );
  }

  void _openLevelSheet() {
    showQBottomSheet(
      context: context,
      title: 'Academic Level',
      body: _LevelSheetBody(
        value: _level,
        onSelect: (v) {
          Navigator.pop(context);
          _update(l: v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = _country.isNotEmpty && _institution.isNotEmpty && _level.isNotEmpty;
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: widget.onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Your Academic Context.',
              subtitle: 'Tell us where you study or teach.',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _openCountrySheet,
                      child: QField(
                        label: 'Country',
                        value: _country,
                        readOnly: true,
                        trailing: const Icon(Icons.expand_more,
                            size: 18, color: QAI.muted),
                      ),
                    ),
                    const SizedBox(height: 14),
                    QField(
                      label: 'Institution Name',
                      value: _institution,
                      onChange: (v) => _update(i: v),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _openLevelSheet,
                      child: QField(
                        label: 'Academic Level',
                        value: _level,
                        readOnly: true,
                        trailing: const Icon(Icons.expand_more,
                            size: 18, color: QAI.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            QFooter(
                child: PrimaryButton(
                    label: 'Continue',
                    onPressed: widget.onNext,
                    disabled: !valid)),
          ],
        ),
      ),
    );
  }
}

class _CountrySheetBody extends StatefulWidget {
  final String value;
  final ValueChanged<String> onSelect;
  const _CountrySheetBody({required this.value, required this.onSelect});
  @override
  State<_CountrySheetBody> createState() => _CountrySheetBodyState();
}

class _CountrySheetBodyState extends State<_CountrySheetBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _countries.where((c) {
      final q = _query.trim().toLowerCase();
      return q.isEmpty ||
          (c['name'] as String).toLowerCase().contains(q);
    }).toList();
    final suggested = filtered.where((c) => c['suggested'] == true).toList();
    final rest = filtered.where((c) => c['suggested'] != true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2EC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: QAI.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search countries',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14, color: QAI.muted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(fontSize: 14, color: QAI.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (suggested.isNotEmpty) ...[
          _SheetSectionLabel('Suggested'),
          ...suggested.map((c) => _CountryRow(
              country: c, selected: widget.value == c['name'], onTap: widget.onSelect)),
        ],
        if (rest.isNotEmpty) ...[
          if (suggested.isNotEmpty) _SheetSectionLabel('All Countries'),
          ...rest.map((c) => _CountryRow(
              country: c, selected: widget.value == c['name'], onTap: widget.onSelect)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: QAI.hint,
          letterSpacing: 0.08 * 11,
        ),
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  final Map<String, Object?> country;
  final bool selected;
  final ValueChanged<String> onTap;
  const _CountryRow(
      {required this.country, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(country['name'] as String),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: QAI.border, width: 1)),
        ),
        child: Row(
          children: [
            if ((country['flag'] as String).isNotEmpty)
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F5F0),
                  shape: BoxShape.circle,
                ),
                child: Text(country['flag'] as String,
                    style: const TextStyle(fontSize: 16)),
              )
            else
              const SizedBox(width: 28, height: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                country['name'] as String,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: QAI.ink,
                  letterSpacing: -0.005,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: QAI.ink),
          ],
        ),
      ),
    );
  }
}

class _LevelSheetBody extends StatelessWidget {
  final String value;
  final ValueChanged<String> onSelect;
  const _LevelSheetBody({required this.value, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._academicLevels.map((lvl) => InkWell(
          onTap: () => onSelect(lvl),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              border:
              Border(bottom: BorderSide(color: QAI.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lvl,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: value == lvl
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: QAI.ink,
                      letterSpacing: -0.005,
                    ),
                  ),
                ),
                if (value == lvl)
                  const Icon(Icons.check, size: 18, color: QAI.ink),
              ],
            ),
          ),
        )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Sign Up ─────────────────────────────────────────────────
class SignUpScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String password;
  final void Function(String, String, String) onChange;
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final VoidCallback onSignIn;
  // Surfaced from the real Supabase signUp() call in FlowController —
  // null when there's nothing to show. loading disables the button and
  // swaps its label so a slow network doesn't look like a dead tap.
  final String? errorText;
  final bool loading;

  const SignUpScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.password,
    required this.onChange,
    required this.onBack,
    required this.onCreate,
    required this.onSignIn,
    this.errorText,
    this.loading = false,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late String _name, _email, _pwd;
  bool _showPwd = false;

  @override
  void initState() {
    super.initState();
    _name = widget.fullName;
    _email = widget.email;
    _pwd = widget.password;
  }

  void _update({String? n, String? e, String? p}) {
    setState(() {
      if (n != null) _name = n;
      if (e != null) _email = e;
      if (p != null) _pwd = p;
    });
    widget.onChange(_name, _email, _pwd);
  }

  @override
  Widget build(BuildContext context) {
    final valid = _name.isNotEmpty && _email.contains('@') && _pwd.length >= 6;
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: widget.onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Create Your Account.',
              subtitle: 'Set up your secure Quill.AI account.',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  children: [
                    QField(label: 'Full Name', value: _name, onChange: (v) => _update(n: v)),
                    const SizedBox(height: 14),
                    QField(
                        label: 'Email',
                        value: _email,
                        onChange: (v) => _update(e: v),
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    QField(
                      label: 'Password',
                      value: _pwd,
                      onChange: (v) => _update(p: v),
                      obscure: !_showPwd,
                      trailing: GestureDetector(
                        onTap: () => setState(() => _showPwd = !_showPwd),
                        child: Icon(
                          _showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: QAI.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            QFooter(
              child: Column(
                children: [
                  if (widget.errorText != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        widget.errorText!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                  PrimaryButton(
                      label: widget.loading ? 'Creating…' : 'Create Account',
                      onPressed: widget.onCreate,
                      disabled: !valid || widget.loading),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: GoogleFonts.inter(fontSize: 13, color: QAI.muted)),
                      GestureDetector(
                        onTap: widget.onSignIn,
                        child: Text('Sign In',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: QAI.ink,
                            )),
                      ),
                    ],
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

// ─── Sign In ─────────────────────────────────────────────────
class SignInScreen extends StatefulWidget {
  final String email;
  final String password;
  final void Function(String, String) onChange;
  final VoidCallback? onBack;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onForgot;
  final String? errorText;
  final bool loading;

  const SignInScreen({
    super.key,
    required this.email,
    required this.password,
    required this.onChange,
    this.onBack,
    required this.onSignIn,
    required this.onSignUp,
    required this.onForgot,
    this.errorText,
    this.loading = false,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late String _email, _pwd;
  bool _showPwd = false;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _pwd = widget.password;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _email.contains('@') && _pwd.length >= 6;
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: widget.onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Welcome Back.',
              subtitle: 'Sign in to continue your academic journey.',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  children: [
                    QField(
                      label: 'Email',
                      value: _email,
                      onChange: (v) {
                        setState(() => _email = v);
                        widget.onChange(_email, _pwd);
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    QField(
                      label: 'Password',
                      value: _pwd,
                      onChange: (v) {
                        setState(() => _pwd = v);
                        widget.onChange(_email, _pwd);
                      },
                      obscure: !_showPwd,
                      trailing: GestureDetector(
                        onTap: () => setState(() => _showPwd = !_showPwd),
                        child: Icon(
                          _showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: QAI.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: widget.onForgot,
                        child: Text('Forgot Password?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: QAI.ink,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            QFooter(
              child: Column(
                children: [
                  if (widget.errorText != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        widget.errorText!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                  PrimaryButton(
                      label: widget.loading ? 'Signing in…' : 'Sign In',
                      onPressed: widget.onSignIn,
                      disabled: !valid || widget.loading),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: GoogleFonts.inter(fontSize: 13, color: QAI.muted)),
                      GestureDetector(
                        onTap: widget.onSignUp,
                        child: Text('Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: QAI.ink,
                            )),
                      ),
                    ],
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