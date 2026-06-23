import 'package:flutter/material.dart';
import 'theme/qai_theme.dart';
import 'screens/app_data.dart';
import 'screens/screens_onboarding.dart';
import 'screens/screens_identity.dart';
import 'screens/screens_calibration.dart';
import 'screens/screens_auth.dart';
import 'screens/screens_recovery.dart';
import 'screens/home/app_shell.dart';

void main() {
  runApp(const QuillAIApp());
}

class QuillAIApp extends StatelessWidget {
  const QuillAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quill.AI',
      debugShowCheckedModeBanner: false,
      theme: QAI.theme(),
      home: const FlowController(),
    );
  }
}

// ─── Flow Controller — the single state machine ───────────────
class FlowController extends StatefulWidget {
  const FlowController({super.key});

  @override
  State<FlowController> createState() => _FlowControllerState();
}

class _FlowControllerState extends State<FlowController> {
  String _route = Routes.splash;
  final List<String> _history = [];
  final QuillUserData _data = QuillUserData();

  void _go(String route) {
    setState(() {
      _history.add(_route);
      _route = route;
    });
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() {
      _route = _history.removeLast();
    });
  }

  String _nextAfter(String route) {
    final flow = _data.role == 'teacher'
        ? [Routes.workload, Routes.challenges, Routes.aiPref]
        : [Routes.focusSpan, Routes.learningStyle, Routes.workflow];

    switch (route) {
      case Routes.splash: return Routes.onbFocus;
      case Routes.onbFocus: return Routes.onbAdapt;
      case Routes.onbAdapt: return Routes.onbControl;
      case Routes.onbControl: return Routes.gender;
      case Routes.gender: return Routes.age;
      case Routes.age: return Routes.role;
      case Routes.role: return flow[0];
      case Routes.focusSpan: return Routes.learningStyle;
      case Routes.learningStyle: return Routes.workflow;
      case Routes.workflow: return Routes.demographics;
      case Routes.workload: return Routes.challenges;
      case Routes.challenges: return Routes.aiPref;
      case Routes.aiPref: return Routes.demographics;
      case Routes.demographics: return Routes.signUp;
      case Routes.signUp: return Routes.home;
      case Routes.forgot: return Routes.otp;
      case Routes.otp: return Routes.reset;
      case Routes.reset: return Routes.success;
      case Routes.success: return Routes.signIn;
      default: return route;
    }
  }

  void _advance() => _go(_nextAfter(_route));

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_route) {
      case Routes.splash:
        return SplashScreen(
            key: const ValueKey('splash'), onContinue: _advance);

      case Routes.onbFocus:
        return OnboardingScreen(
          key: const ValueKey('onb-focus'),
          index: 0,
          hero: CustomPaint(
            size: const Size(210, 210),
            painter: HeroFocusPainter(),
          ),
          title: 'Achieve Deep Focus.',
          subtitle:
              'AI that adapts to your cognitive patterns to eliminate distractions.',
          ctaLabel: 'Next',
          onNext: _advance,
          onSkip: () => _go(Routes.signIn),
        );

      case Routes.onbAdapt:
        return OnboardingScreen(
          key: const ValueKey('onb-adapt'),
          index: 1,
          hero: CustomPaint(
            size: const Size(210, 210),
            painter: HeroNetworkPainter(),
          ),
          title: 'Smart Adaptation.',
          subtitle:
              'Tailored study paths designed for your unique learning style.',
          ctaLabel: 'Next',
          onNext: _advance,
          onSkip: () => _go(Routes.signIn),
        );

      case Routes.onbControl:
        return OnboardingScreen(
          key: const ValueKey('onb-control'),
          index: 2,
          hero: CustomPaint(
            size: const Size(210, 210),
            painter: HeroControlPainter(),
          ),
          title: 'Absolute Control.',
          subtitle:
              'Manage your academic workload with scientific precision.',
          ctaLabel: 'Get Started',
          onNext: _advance,
          onSkip: () => _go(Routes.signIn),
        );

      case Routes.gender:
        return GenderScreen(
          key: const ValueKey('gender'),
          value: _data.gender,
          onChange: (v) => setState(() => _data.gender = v),
          onBack: _back,
          onNext: _advance,
          onSkip: () => _go(Routes.signIn),
        );

      case Routes.age:
        return AgeScreen(
          key: const ValueKey('age'),
          value: _data.age,
          onChange: (v) => setState(() => _data.age = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.role:
        return RoleScreen(
          key: const ValueKey('role'),
          value: _data.role,
          onChange: (v) => setState(() => _data.role = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.focusSpan:
        return FocusSpanScreen(
          key: const ValueKey('focus-span'),
          value: _data.focusSpan,
          onChange: (v) => setState(() => _data.focusSpan = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.learningStyle:
        return LearningStyleScreen(
          key: const ValueKey('learning-style'),
          value: _data.learningStyle,
          onChange: (v) => setState(() => _data.learningStyle = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.workflow:
        return WorkflowScreen(
          key: const ValueKey('workflow'),
          value: _data.workflow,
          onChange: (v) => setState(() => _data.workflow = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.workload:
        return WorkloadScreen(
          key: const ValueKey('workload'),
          value: _data.workload,
          onChange: (v) => setState(() => _data.workload = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.challenges:
        return ChallengesScreen(
          key: const ValueKey('challenges'),
          value: _data.challenges,
          onChange: (v) => setState(() => _data.challenges = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.aiPref:
        return AIPrefScreen(
          key: const ValueKey('ai-pref'),
          value: _data.aiPref,
          onChange: (v) => setState(() => _data.aiPref = v),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.demographics:
        return DemographicsScreen(
          key: const ValueKey('demographics'),
          country: _data.country,
          institution: _data.institution,
          level: _data.level,
          onChange: (c, i, l) => setState(() {
            _data.country = c;
            _data.institution = i;
            _data.level = l;
          }),
          onBack: _back,
          onNext: _advance,
        );

      case Routes.signUp:
        return SignUpScreen(
          key: const ValueKey('signup'),
          fullName: _data.fullName,
          email: _data.email,
          password: _data.password,
          onChange: (n, e, p) => setState(() {
            _data.fullName = n;
            _data.email = e;
            _data.password = p;
          }),
          onBack: _back,
          onCreate: () {
            setState(() {
              _history.clear();
              _route = Routes.home;
            });
          },
          onSignIn: () => _go(Routes.signIn),
        );

      case Routes.signIn:
        return SignInScreen(
          key: const ValueKey('signin'),
          email: _data.signInEmail,
          password: _data.signInPassword,
          onChange: (e, p) => setState(() {
            _data.signInEmail = e;
            _data.signInPassword = p;
          }),
          onBack: _history.isNotEmpty ? _back : null,
          onSignIn: () {
            setState(() {
              _history.clear();
              _route = Routes.home;
            });
          },
          onSignUp: () => _go(Routes.signUp),
          onForgot: () => _go(Routes.forgot),
        );

      case Routes.forgot:
        return ForgotScreen(
          key: const ValueKey('forgot'),
          email: _data.forgotEmail,
          onChange: (v) => setState(() => _data.forgotEmail = v),
          onBack: _back,
          onSend: _advance,
        );

      case Routes.otp:
        return OTPScreen(
          key: const ValueKey('otp'),
          code: _data.otp,
          onChange: (v) => setState(() => _data.otp = v),
          onBack: _back,
          onVerify: _advance,
        );

      case Routes.reset:
        return ResetPasswordScreen(
          key: const ValueKey('reset'),
          pwd: _data.newPassword,
          confirm: _data.confirmPassword,
          onPwd: (v) => setState(() => _data.newPassword = v),
          onConfirm: (v) => setState(() => _data.confirmPassword = v),
          onBack: _back,
          onReset: _advance,
        );

      case Routes.success:
        return SuccessScreen(
          key: const ValueKey('success'),
          onSignIn: () => _go(Routes.signIn),
        );

      // Post-auth: AppShell owns the Scaffold, Drawer, Header, FAB and
      // switches between Home / Tasks sections internally.
      case Routes.home:
        return AppShell(
          key: const ValueKey('home'),
          userName: _data.fullName,
          userEmail:
              _data.email.isNotEmpty ? _data.email : _data.signInEmail,
          isTeacher: _data.role == 'teacher',
          onSignOut: () {
            setState(() {
              _history.clear();
              _route = Routes.signIn;
            });
          },
        );

      default:
        return const Scaffold(body: Center(child: Text('Unknown route')));
    }
  }
}