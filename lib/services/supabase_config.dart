// lib/services/supabase_config.dart
//
// Connection info for the real backend (v2 migration — see
// supabase_schema.sql for the table/RLS definitions this points at).
//
// The publishable key is the current Supabase replacement for the old
// "anon key" — low-privilege, scoped entirely by Row Level Security on
// every table, safe to ship inside the compiled app.
//
// The matching *secret* key (service_role-equivalent, bypasses RLS) must
// NEVER appear in this file or anywhere else in the Flutter app — it only
// belongs on a real backend server, which this app deliberately doesn't
// have. If it's ever needed (a future admin tool, a scheduled job), it
// lives in that server's environment only.
class SupabaseConfig {
  static const String url = 'https://eavcdcfpqhmufefmrcwa.supabase.co';
  static const String publishableKey =
      'sb_publishable_pqZ7gxjNIbu6uTabIFwqag_x6qcLfRN';
}
