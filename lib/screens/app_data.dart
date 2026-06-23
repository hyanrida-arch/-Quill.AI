import 'package:flutter/material.dart';

// ─── User data collected across the flow ─────────────────────
class QuillUserData {
  String? gender;
  int age = 20;
  String? role;

  // Student calibration
  int focusSpan = 2;
  String? learningStyle;
  String? workflow;

  // Teacher calibration
  int workload = 1;
  String? challenges;
  String? aiPref;

  // Demographics
  String country = '';
  String institution = '';
  String level = '';

  // Auth
  String fullName = '';
  String email = '';
  String password = '';
  String signInEmail = '';
  String signInPassword = '';
  String forgotEmail = '';
  String otp = '';
  String newPassword = '';
  String confirmPassword = '';
}

// ─── Named routes ─────────────────────────────────────────────
class Routes {
  static const splash = '/';
  static const onbFocus = '/onb-focus';
  static const onbAdapt = '/onb-adapt';
  static const onbControl = '/onb-control';
  static const gender = '/gender';
  static const age = '/age';
  static const role = '/role';
  static const focusSpan = '/focus-span';
  static const learningStyle = '/learning-style';
  static const workflow = '/workflow';
  static const workload = '/workload';
  static const challenges = '/challenges';
  static const aiPref = '/ai-pref';
  static const demographics = '/demographics';
  static const signUp = '/signup';
  static const signIn = '/signin';
  static const forgot = '/forgot';
  static const otp = '/otp';
  static const reset = '/reset';
  static const success = '/success';
  static const home = '/home';
 }