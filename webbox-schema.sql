-- =========================================================
-- WebBox Publish System
-- Run in Supabase SQL Editor (project: uhemlvqwulybmczsuige)
-- =========================================================

create extension if not exists "pgcrypto";

-- ---------- TABLES ----------
create table if not exists public.published_apps (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  owner_id uuid,
  owner_email text,
  name text not null,
  content text not null,
  icon text,
  active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_pub_apps_slug  on public.published_apps(slug);
create index if not exists idx_pub_apps_owner on public.published_apps(owner_id);

create table if not exists public.app_users (
  id uuid primary key default gen_random_uuid(),
  mobile text unique not null,
  pin_hash text not null,
  created_at timestamptz default now(),
  last_login timestamptz
);

create table if not exists public.app_entries (
  id uuid primary key default gen_random_uuid(),
  app_id  uuid not null references public.published_apps(id) on delete cascade,
  user_id uuid not null references public.app_users(id)     on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now(),
  unique(app_id, user_id)
);
create index if not exists idx_app_entries_app  on public.app_entries(app_id);
create index if not exists idx_app_entries_user on public.app_entries(user_id);

-- ---------- RLS ----------
alter table public.published_apps enable row level security;
alter table public.app_users      enable row level security;
alter table public.app_entries    enable row level security;

drop policy if exists "pub_apps_all" on public.published_apps;
create policy "pub_apps_all" on public.published_apps
  for all using (true) with check (true);

drop policy if exists "app_users_all" on public.app_users;
create policy "app_users_all" on public.app_users
  for all using (true) with check (true);

drop policy if exists "app_entries_all" on public.app_entries;
create policy "app_entries_all" on public.app_entries
  for all using (true) with check (true);

-- ---------- RPC: signup ----------
create or replace function public.app_signup(p_mobile text, p_pin text)
returns jsonb language plpgsql security definer as $$
declare v_id uuid; v_exists boolean;
begin
  p_mobile := trim(p_mobile);
  if length(p_mobile) < 6 then
    return jsonb_build_object('ok', false, 'error', 'Mobile invalid');
  end if;
  if length(p_pin) <> 4 or p_pin !~ '^[0-9]{4}$' then
    return jsonb_build_object('ok', false, 'error', 'PIN 4 digit hona chahiye');
  end if;
  select exists(select 1 from app_users where mobile = p_mobile) into v_exists;
  if v_exists then
    return jsonb_build_object('ok', false, 'error', 'Ye mobile pehle se registered hai');
  end if;
  insert into app_users (mobile, pin_hash, last_login)
  values (p_mobile, crypt(p_pin, gen_salt('bf')), now())
  returning id into v_id;
  return jsonb_build_object('ok', true, 'user_id', v_id, 'mobile', p_mobile);
end; $$;

-- ---------- RPC: login ----------
create or replace function public.app_login(p_mobile text, p_pin text)
returns jsonb language plpgsql security definer as $$
declare v_id uuid; v_hash text;
begin
  p_mobile := trim(p_mobile);
  select id, pin_hash into v_id, v_hash from app_users where mobile = p_mobile;
  if v_id is null then
    return jsonb_build_object('ok', false, 'error', 'Mobile registered nahi hai');
  end if;
  if v_hash <> crypt(p_pin, v_hash) then
    return jsonb_build_object('ok', false, 'error', 'Galat PIN');
  end if;
  update app_users set last_login = now() where id = v_id;
  return jsonb_build_object('ok', true, 'user_id', v_id, 'mobile', p_mobile);
end; $$;

-- ---------- ADMIN PRE-CREATE ----------
insert into app_users (mobile, pin_hash)
values ('03176407904', crypt('0786', gen_salt('bf')))
on conflict (mobile) do nothing;

grant execute on function public.app_signup(text, text) to anon, authenticated;
grant execute on function public.app_login (text, text) to anon, authenticated;
