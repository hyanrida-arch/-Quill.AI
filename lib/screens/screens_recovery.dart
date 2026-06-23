import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/qai_theme.dart';
import '../widgets/ shared_widgets.dart';

// ─── Forgot Password ─────────────────────────────────────────
class ForgotScreen extends StatefulWidget {
  final String email;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onSend;

  const ForgotScreen({
    super.key,
    required this.email,
    required this.onChange,
    required this.onBack,
    required this.onSend,
  });

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  late String _email;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _email.contains('@');
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: widget.onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Reset Your Password.',
              subtitle: "Enter your email and we'll send you a verification code.",
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: QField(
                  label: 'Email',
                  value: _email,
                  onChange: (v) {
                    setState(() => _email = v);
                    widget.onChange(v);
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ),
            QFooter(
                child: PrimaryButton(
                    label: 'Send Code',
                    onPressed: widget.onSend,
                    disabled: !valid)),
          ],
        ),
      ),
    );
  }
}

// ─── OTP Screen ───────────────────────────────────────────────
class OTPScreen extends StatefulWidget {
  final String code;
  final ValueChanged<String> onChange;
  final VoidCallback onBack;
  final VoidCallback onVerify;

  const OTPScreen({
    super.key,
    required this.code,
    required this.onChange,
    required this.onBack,
    required this.onVerify,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _ctrls =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  int _resend = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Pre-fill if code given
    for (int i = 0; i < widget.code.length && i < 6; i++) {
      _ctrls[i].text = widget.code[i];
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resend <= 0) {
        t.cancel();
      } else {
        setState(() => _resend--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onDigit(int i, String v) {
    final digit = v.replaceAll(RegExp(r'\D'), '');
    if (digit.isEmpty) {
      _ctrls[i].text = '';
      if (i > 0) _nodes[i - 1].requestFocus();
    } else {
      _ctrls[i].text = digit[digit.length - 1];
      if (i < 5) _nodes[i + 1].requestFocus();
    }
    final full = _ctrls.map((c) => c.text).join();
    widget.onChange(full);
  }

  bool get _filled =>
      _ctrls.every((c) => c.text.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: widget.onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Enter Verification Code.',
              subtitle: 'We sent a 6-digit code to your email.',
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: List.generate(6, (i) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                      child: AspectRatio(
                        aspectRatio: 0.9,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _ctrls[i].text.isNotEmpty
                                  ? QAI.ink
                                  : QAI.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _ctrls[i],
                              focusNode: _nodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (v) => _onDigit(i, v),
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: QAI.ink,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 22),
            _resend > 0
                ? RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    fontSize: 13, color: QAI.muted),
                children: [
                  const TextSpan(text: 'Resend code in '),
                  TextSpan(
                    text:
                    '0:${_resend.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: QAI.ink),
                  ),
                ],
              ),
            )
                : GestureDetector(
              onTap: () {
                setState(() => _resend = 45);
                _startTimer();
              },
              child: Text(
                'Resend code',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: QAI.ink,
                ),
              ),
            ),
            const Spacer(),
            QFooter(
                child: PrimaryButton(
                    label: 'Verify',
                    onPressed: widget.onVerify,
                    disabled: !_filled)),
          ],
        ),
      ),
    );
  }
}

// ─── Reset Password ───────────────────────────────────────────
int _passwordStrength(String pwd) {
  if (pwd.isEmpty) return 0;
  int s = 0;
  if (pwd.length >= 8) s++;
  if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) s++;
  if (RegExp(r'\d').hasMatch(pwd) || RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) s++;
  return s;
}

class ResetPasswordScreen extends StatefulWidget {
  final String pwd;
  final String confirm;
  final ValueChanged<String> onPwd;
  final ValueChanged<String> onConfirm;
  final VoidCallback onBack;
  final VoidCallback onReset;

  const ResetPasswordScreen({
    super.key,
    required this.pwd,
    required this.confirm,
    required this.onPwd,
    required this.onConfirm,
    required this.onBack,
    required this.onReset,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late String _pwd, _confirm;
  bool _show1 = false, _show2 = false;

  @override
  void initState() {
    super.initState();
    _pwd = widget.pwd;
    _confirm = widget.confirm;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _passwordStrength(_pwd);
    final match = _pwd.isNotEmpty && _pwd == _confirm;
    final valid = strength >= 2 && match;
    final strengthLabels = ['', 'Weak', 'Good', 'Strong'];

    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            QTopBar(onBack: widget.onBack),
            const SizedBox(height: 24),
            const QHeadline(
              title: 'Create New Password.',
              subtitle:
              'Choose a strong password — at least 8 characters with a mix of letters and numbers.',
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  QField(
                    label: 'New Password',
                    value: _pwd,
                    onChange: (v) {
                      setState(() => _pwd = v);
                      widget.onPwd(v);
                    },
                    obscure: !_show1,
                    trailing: GestureDetector(
                      onTap: () => setState(() => _show1 = !_show1),
                      child: Icon(
                        _show1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: QAI.muted,
                      ),
                    ),
                  ),
                  if (_pwd.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ...List.generate(3, (i) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 3,
                              decoration: BoxDecoration(
                                color: i < strength ? QAI.ink : QAI.trackBg,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        )),
                        const SizedBox(width: 10),
                        Text(
                          strengthLabels[strength],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: QAI.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  QField(
                    label: 'Confirm Password',
                    value: _confirm,
                    onChange: (v) {
                      setState(() => _confirm = v);
                      widget.onConfirm(v);
                    },
                    obscure: !_show2,
                    error: _confirm.isNotEmpty && !match
                        ? "Passwords don't match"
                        : null,
                    trailing: GestureDetector(
                      onTap: () => setState(() => _show2 = !_show2),
                      child: Icon(
                        _show2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: QAI.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            QFooter(
                child: PrimaryButton(
                    label: 'Reset Password',
                    onPressed: widget.onReset,
                    disabled: !valid)),
          ],
        ),
      ),
    );
  }
}

// ─── Success ─────────────────────────────────────────────────
class SuccessScreen extends StatelessWidget {
  final VoidCallback onSignIn;

  const SuccessScreen({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QAI.bg,
      body: SafeArea(
        child: Column(
          children: [
            const QTopBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: QAI.teal, width: 1.5),
                          color: QAI.teal.withOpacity(0.06),
                        ),
                        child: const Icon(Icons.check,
                            size: 42, color: QAI.teal),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Password Reset Successfully.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: QAI.ink,
                          letterSpacing: -0.025 * 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You can now sign in with your new password.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: QAI.muted,
                          height: 1.5,
                          letterSpacing: -0.005,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            QFooter(
                child: PrimaryButton(label: 'Back to Sign In', onPressed: onSignIn)),
          ],
        ),
      ),
    );
  }
}