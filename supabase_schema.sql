-- =====================================================================
-- Quill.AI — Supabase schema (v2 migration, full-app scope)
-- =====================================================================
-- Design choice, stated explicitly so it isn't silently baked in:
-- nested/list fields (subtasks, recurrence, occurrences, habit check-ins,
-- note blocks) are stored as JSONB columns that mirror each Dart model's
-- own toJson() shape 1:1, instead of being split into extra join tables.
-- This is a deliberate trade-off for a solo dev on a deadline: the sync
-- layer becomes "row = model.toJson(); upsert" and "model = Model.fromJson(row)"
-- with almost no translation logic, at the cost of not being able to query
-- inside those fields in plain SQL. For this app's size that trade is fine.
-- Only genuinely relational, cross-user data (classrooms, membership,
-- diffused tasks) gets real foreign keys — because that's exactly the part
-- that needs real relational guarantees (RLS, ownership, fan-out).
--
-- Run this once in Supabase → SQL Editor, top to bottom.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Extensions
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- ---------------------------------------------------------------------
-- 1. profiles — one row per real Supabase Auth user
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  phone text,
  is_teacher boolean not null default false,
  created_at timestamptz not null default now()
);

-- Auto-create a profile row the moment someone signs up, so the app never
-- has to handle "authenticated but no profile yet".
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------
-- 2. classrooms + membership — the real, multi-device version of
--    lib/models/classroom.dart. Replaces the local-only `roster` list.
-- ---------------------------------------------------------------------
create table public.classrooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null default 'peer',        -- 'peer' | 'teacherClass'
  color_value integer not null default 4279548070,
  join_code text not null unique,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);
-- color_value defaults below (4279548070) = 0xFF14B8A6 = AppColors.teal,
-- same default every color-owning Dart model already uses.

create table public.classroom_members (
  classroom_id uuid not null references public.classrooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (classroom_id, user_id)
);

-- Lets a user join by code without first being able to SELECT the whole
-- classrooms table (which RLS below otherwise blocks for non-members).
-- SECURITY DEFINER bypasses RLS just for this one lookup+insert.
create function public.join_classroom_by_code(p_code text)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_classroom_id uuid;
begin
  select id into v_classroom_id from public.classrooms where join_code = p_code;
  if v_classroom_id is null then
    raise exception 'Invalid join code';
  end if;
  insert into public.classroom_members (classroom_id, user_id)
  values (v_classroom_id, auth.uid())
  on conflict do nothing;
  return v_classroom_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 3. tasks — mirrors lib/models/task.dart. classroom_id + source_task_id
--    implement the "prof diffuse -> copie chez chaque membre" fan-out:
--    the teacher's original has classroom_id set and source_task_id null;
--    each member's copy has source_task_id pointing back to it.
-- ---------------------------------------------------------------------
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  classroom_id uuid references public.classrooms(id) on delete set null,
  source_task_id uuid references public.tasks(id) on delete set null,

  title text not null,
  subject text not null default '',
  estimated_minutes integer not null default 0,
  pomodoros_planned integer not null default 0,
  priority text not null default 'medium',
  type text not null default 'timeBased',
  status text not null default 'pending',
  due_label text,
  due_date timestamptz,
  is_teacher boolean not null default false,
  completed_at timestamptz,
  description text not null default '',
  has_time boolean not null default false,
  tag_label text,
  tag_color_value integer,
  recurrence jsonb not null default '{}'::jsonb,
  completed_occurrences jsonb not null default '[]'::jsonb,
  skipped_occurrences jsonb not null default '[]'::jsonb,
  reminder_minutes_before integer,
  subtasks jsonb not null default '[]'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 4. focus_sessions — mirrors lib/models/focus_session.dart
-- ---------------------------------------------------------------------
create table public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null,
  task_title text not null default '',
  planned_minutes integer not null default 0,
  actual_seconds integer not null default 0,
  pause_count integer not null default 0,
  outcome text not null default 'completed', -- completed | interrupted | abandoned
  completed_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 5. habits — mirrors lib/models/habit.dart (checkIns kept as JSONB
--    array of {date,count}, same shape as Habit.toJson()).
-- ---------------------------------------------------------------------
create table public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  icon_key text not null default 'water',
  color_value integer not null default 4279548070,
  type text not null default 'yesNo',
  target_count integer not null default 1,
  frequency jsonb not null default '{}'::jsonb,
  reminder_hour integer,
  reminder_minute integer,
  archived boolean not null default false,
  check_ins jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 6. notebooks + notes — mirrors lib/models/notebook.dart
-- ---------------------------------------------------------------------
create table public.notebooks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  icon_key text not null default 'book',
  color_value integer not null default 4279548070,
  created_at timestamptz not null default now()
);

create table public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  notebook_id uuid not null references public.notebooks(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null,
  title text not null default '',
  blocks jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 7. flashcards + card_reviews — mirrors lib/models/flashcard.dart
-- ---------------------------------------------------------------------
create table public.flashcards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  note_id uuid references public.notes(id) on delete set null,
  notebook_id uuid references public.notebooks(id) on delete set null,
  question text not null,
  answer text not null,
  box integer not null default 1,
  next_review_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.card_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid not null references public.flashcards(id) on delete cascade,
  correct boolean not null,
  reviewed_at timestamptz not null default now()
);

-- =====================================================================
-- ROW LEVEL SECURITY — every table is private-by-default: a user only
-- ever sees their own rows, except the classroom exceptions below (a
-- member needs to read the classroom + roommates' membership rows, and a
-- teacher needs to read progress on tasks they diffused).
-- =====================================================================

alter table public.profiles enable row level security;
alter table public.classrooms enable row level security;
alter table public.classroom_members enable row level security;
alter table public.tasks enable row level security;
alter table public.focus_sessions enable row level security;
alter table public.habits enable row level security;
alter table public.notebooks enable row level security;
alter table public.notes enable row level security;
alter table public.flashcards enable row level security;
alter table public.card_reviews enable row level security;

-- profiles: anyone signed in can read a display name (needed to show
-- classroom rosters); a user can only edit their own row.
create policy "profiles are readable by any signed-in user"
  on public.profiles for select using (auth.role() = 'authenticated');
create policy "users can update their own profile"
  on public.profiles for update using (auth.uid() = id);

-- classrooms: members can read; only the owner can create/update/delete.
create policy "members can read their classrooms"
  on public.classrooms for select using (
    owner_id = auth.uid()
    or id in (select classroom_id from public.classroom_members where user_id = auth.uid())
  );
create policy "owner manages the classroom"
  on public.classrooms for insert with check (owner_id = auth.uid());
create policy "owner updates the classroom"
  on public.classrooms for update using (owner_id = auth.uid());
create policy "owner deletes the classroom"
  on public.classrooms for delete using (owner_id = auth.uid());

-- classroom_members: members can see the roster of classrooms they're in;
-- joining itself goes through join_classroom_by_code() (SECURITY DEFINER),
-- not a direct insert, so no general insert policy is needed here.
create policy "members can read the roster"
  on public.classroom_members for select using (
    user_id = auth.uid()
    or classroom_id in (select id from public.classrooms where owner_id = auth.uid())
  );
create policy "members can leave"
  on public.classroom_members for delete using (user_id = auth.uid());

-- tasks: a user reads/writes their own tasks; a classroom owner can also
-- read (not write) the fanned-out copies to build the progress dashboard.
create policy "users manage their own tasks"
  on public.tasks for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "teacher reads diffused task copies"
  on public.tasks for select using (
    classroom_id in (select id from public.classrooms where owner_id = auth.uid())
  );

-- focus_sessions, habits, notebooks, notes, flashcards, card_reviews:
-- strictly private, no cross-user exception needed anywhere yet.
create policy "users manage their own focus sessions"
  on public.focus_sessions for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage their own habits"
  on public.habits for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage their own notebooks"
  on public.notebooks for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage their own notes"
  on public.notes for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage their own flashcards"
  on public.flashcards for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "users manage their own card reviews"
  on public.card_reviews for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- 8. Helpful indexes for the queries the app will actually run
-- ---------------------------------------------------------------------
create index tasks_user_due_idx on public.tasks (user_id, due_date);
create index tasks_classroom_idx on public.tasks (classroom_id);
create index focus_sessions_user_idx on public.focus_sessions (user_id, completed_at);
create index notes_notebook_idx on public.notes (notebook_id);
create index flashcards_user_due_idx on public.flashcards (user_id, next_review_at);
create index classroom_members_user_idx on public.classroom_members (user_id);
