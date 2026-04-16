-- ============================================================
-- 特定技能支援事業ダッシュボード Supabase セットアップSQL
-- Supabase SQL Editor で実行してください
-- ============================================================

-- 1. tasks テーブル
create table if not exists tasks (
  id bigint primary key generated always as identity,
  phase text not null,
  name text not null,
  detail text default '',
  note text default '',
  owner text default '',
  status text not null default '未着手',
  priority text default '中',
  due text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table tasks enable row level security;
drop policy if exists "認証済みユーザーは全操作可能" on tasks;
create policy "認証済みユーザーは全操作可能" on tasks
  for all using (auth.role() = 'authenticated');

-- 2. weekly_changes テーブル
create table if not exists weekly_changes (
  id bigint primary key generated always as identity,
  date text not null,
  type text not null,
  phase text default '',
  title text not null,
  detail text default '',
  created_at timestamptz default now()
);
alter table weekly_changes enable row level security;
drop policy if exists "認証済みユーザーは全操作可能" on weekly_changes;
create policy "認証済みユーザーは全操作可能" on weekly_changes
  for all using (auth.role() = 'authenticated');

-- 3. approvals テーブル
create table if not exists approvals (
  id bigint primary key generated always as identity,
  date text not null,
  question text not null,
  background text default '',
  options text default '',
  urgency text default '中',
  phase text default '',
  status text default '未回答',
  resolved_note text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table approvals enable row level security;
drop policy if exists "認証済みユーザーは全操作可能" on approvals;
create policy "認証済みユーザーは全操作可能" on approvals
  for all using (auth.role() = 'authenticated');

-- 4. updates テーブル
create table if not exists updates (
  id bigint primary key generated always as identity,
  date text not null,
  tag text not null,
  phase text default '',
  text text not null,
  created_by text default '',
  created_at timestamptz default now()
);
alter table updates enable row level security;
drop policy if exists "認証済みユーザーは全操作可能" on updates;
create policy "認証済みユーザーは全操作可能" on updates
  for all using (auth.role() = 'authenticated');

-- 5. profiles テーブル（ユーザー管理）
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  role text not null default 'member',
  created_at timestamptz default now()
);
alter table profiles enable row level security;
drop policy if exists "自分のプロフィールは読み書き可能" on profiles;
create policy "自分のプロフィールは読み書き可能" on profiles
  for all using (auth.uid() = id);
drop policy if exists "全員が全プロフィールを読める" on profiles;
create policy "全員が全プロフィールを読める" on profiles
  for select using (auth.role() = 'authenticated');

-- 6. Realtime を有効化
alter publication supabase_realtime add table tasks;
alter publication supabase_realtime add table weekly_changes;
alter publication supabase_realtime add table approvals;
alter publication supabase_realtime add table updates;

-- 7. updated_at 自動更新トリガー
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists tasks_updated_at on tasks;
create trigger tasks_updated_at before update on tasks
  for each row execute function update_updated_at();

drop trigger if exists approvals_updated_at on approvals;
create trigger approvals_updated_at before update on approvals
  for each row execute function update_updated_at();
