-- =========================================================
-- WebBox — Complete Database Schema
-- Project: xcwcuhjycpshgycnvmyu
-- =========================================================

create extension if not exists "pgcrypto";

-- Cleanup (safe if re-running)
drop table if exists public.app_entries    cascade;
drop table if exists public.published_apps cascade;
drop table if exists public.app_users      cascade;
drop table if exists public.webbox_sync    cascade;
drop function if exists public.app_signup(text, text);
drop function if exists public.app_login(text, text);

-- ============================================================
-- TABLES
-- ============================================================

create table public.webbox_sync (
  sync_key    text primary key,
  user_id     uuid,
  items       jsonb not null default '[]'::jsonb,
  device_name text,
  updated_at  timestamptz default now()
);
create index idx_webbox_sync_user on public.webbox_sync(user_id);

create table public.published_apps (
  id           uuid primary key default gen_random_uuid(),
  slug         text unique not null,
  owner_id     uuid,
  owner_email  text,
  name         text not null default 'Untitled',
  content      text not null,
  icon         text,
  active       boolean default true,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);
create index idx_pub_apps_slug   on public.published_apps(slug);
create index idx_pub_apps_owner  on public.published_apps(owner_id);
create index idx_pub_apps_active on public.published_apps(active);

create table public.app_users (
  id          uuid primary key default gen_random_uuid(),
  mobile      text unique not null,
  pin_hash    text not null,
  created_at  timestamptz default now(),
  last_login  timestamptz
);

create table public.app_entries (
  id         uuid primary key default gen_random_uuid(),
  app_id     uuid not null references public.published_apps(id) on delete cascade,
  user_id    uuid not null references public.app_users(id)      on delete cascade,
  state      jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now(),
  unique(app_id, user_id)
);
create index idx_app_entries_app  on public.app_entries(app_id);
create index idx_app_entries_user on public.app_entries(user_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.published_apps enable row level security;
alter table public.app_users      enable row level security;
alter table public.app_entries    enable row level security;
alter table public.webbox_sync    enable row level security;

create policy "pub_apps_all" on public.published_apps
  for all using (true) with check (true);

create policy "app_users_all" on public.app_users
  for all using (true) with check (true);

create policy "app_entries_all" on public.app_entries
  for all using (true) with check (true);

create policy "webbox_sync_all" on public.webbox_sync
  for all using (true) with check (true);

-- ============================================================
-- RPC: SIGNUP
-- ============================================================
create or replace function public.app_signup(p_mobile text, p_pin text)
returns jsonb language plpgsql security definer as $$
declare v_id uuid; v_exists boolean;
begin
  p_mobile := trim(p_mobile);

  if length(p_mobile) < 6 then
    return jsonb_build_object('ok', false, 'error', 'Mobile number sahi nahi hai');
  end if;
  if length(p_pin) <> 4 or p_pin !~ '^[0-9]{4}$' then
    return jsonb_build_object('ok', false, 'error', 'PIN 4 digit ka hona chahiye');
  end if;

  select exists(select 1 from public.app_users where mobile = p_mobile) into v_exists;
  if v_exists then
    return jsonb_build_object('ok', false, 'error', 'Ye mobile pehle se registered hai');
  end if;

  insert into public.app_users (mobile, pin_hash, last_login)
  values (p_mobile, crypt(p_pin, gen_salt('bf')), now())
  returning id into v_id;

  return jsonb_build_object('ok', true, 'user_id', v_id, 'mobile', p_mobile);
end;
$$;

-- ============================================================
-- RPC: LOGIN
-- ============================================================
create or replace function public.app_login(p_mobile text, p_pin text)
returns jsonb language plpgsql security definer as $$
declare v_id uuid; v_hash text;
begin
  p_mobile := trim(p_mobile);

  select id, pin_hash into v_id, v_hash
  from public.app_users where mobile = p_mobile;

  if v_id is null then
    return jsonb_build_object('ok', false, 'error', 'Mobile registered nahi hai. Pehle Sign Up karein.');
  end if;
  if v_hash <> crypt(p_pin, v_hash) then
    return jsonb_build_object('ok', false, 'error', 'Galat PIN');
  end if;

  update public.app_users set last_login = now() where id = v_id;
  return jsonb_build_object('ok', true, 'user_id', v_id, 'mobile', p_mobile);
end;
$$;

-- ============================================================
-- ADMIN PRE-CREATE (private)
-- ============================================================
insert into public.app_users (mobile, pin_hash)
values ('03176407904', crypt('0786', gen_salt('bf')))
on conflict (mobile) do nothing;

-- ============================================================
-- GRANTS
-- ============================================================
grant usage   on schema   public                      to anon, authenticated;
grant execute on function public.app_signup(text,text) to anon, authenticated;
grant execute on function public.app_login (text,text) to anon, authenticated;
grant select, insert, update, delete on public.webbox_sync    to anon, authenticated;
grant select, insert, update, delete on public.published_apps to anon, authenticated;
grant select, insert, update, delete on public.app_users      to anon, authenticated;
grant select, insert, update, delete on public.app_entries    to anon, authenticated;

-- ============================================================
-- FORCE SCHEMA CACHE RELOAD
-- ============================================================
notify pgrst, 'reload schema';

-- ============================================================
-- VERIFY
-- ============================================================
select 'webbox_sync'    as table_name, count(*) as rows from public.webbox_sync
union all
select 'published_apps', count(*) from public.published_apps
union all
select 'app_users',      count(*) from public.app_users
union all
select 'app_entries',    count(*) from public.app_entries;
