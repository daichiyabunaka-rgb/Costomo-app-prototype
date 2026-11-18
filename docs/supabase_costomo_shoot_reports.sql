-- ============================================================
-- 0015_costomo_shoot_reports: コスとも！の特別機能を
--   「ゆずりあい・交換」→「撮影報告」に変更する
-- 対象: 共有Supabaseプロジェクト（変換マイグレーション・トランザクション）
--
-- 内容:
--   1. costume_exchanges テーブルを public.shoot_reports にリネーム
--      - kind 制約を give/wanted/trade から shoot/spot/event/art へ差し替え
--        shoot = 撮影（撮ってきたコスプレ写真の報告）
--        spot  = 場所（撮影スポットの報告）
--        event = イベント（イベント会場での撮影報告）
--        art   = 絵（描いた絵・ファンアートの投稿）
--      - 列名・制約・RLS・インデックスはそのまま（総合版アプリとの互換を維持）
--   2. 既存行（ベータ検証で投稿された give/wanted/trade の3件・テストデータ）を削除
--      - 古い kind は新しい制約に適合しないため
--   3. RLS ポリシー名を「撮影報告」用に付け替え（中身は同一）
--   4. delete_my_account() の costume_exchanges→shoot_reports 差し替え
--
-- 注記:
--   - 投稿写真バケットは cosplay-item-photos をそのまま使う
--     （Supabase のバケットリネームは不可のため。パスは <uid>/costomo/item_photo_*.jpg）
--   - 総合版（tomotsuku）の co hub のゆずりあいタブは本テーブルを参照する
--
-- 前提: 0006_costomo が適用済みであること。
--       番号順に適用する運用（提案006）に従うこと。
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. テーブルのリネームと kind 制約の差し替え
-- ------------------------------------------------------------
delete from public.costume_exchanges;  -- ベータ検証のテスト3件（give/wanted/trade）

alter table public.costume_exchanges rename to public.shoot_reports;

alter table public.shoot_reports drop constraint if exists costume_exchanges_kind_check;
alter table public.shoot_reports add constraint shoot_reports_kind_check
  check (kind in ('shoot', 'spot', 'event', 'art'));

create index if not exists shoot_reports_geohash_idx
  on public.shoot_reports (location_geohash);
drop index if exists costume_exchanges_geohash_idx;

-- ------------------------------------------------------------
-- 2. RLS ポリシーの付け替え（中身は同一・名前だけ更新）
-- ------------------------------------------------------------
drop policy if exists "ゆずりあい・交換は誰でも閲覧可" on public.shoot_reports;
drop policy if exists "ゆずりあい・交換の登録は本人のみ" on public.shoot_reports;
drop policy if exists "ゆずりあい・交換の更新は本人のみ" on public.shoot_reports;
drop policy if exists "ゆずりあい・交換の削除は本人のみ" on public.shoot_reports;
drop policy if exists "撮影報告は誰でも閲覧可" on public.shoot_reports;
drop policy if exists "撮影報告の登録は本人のみ" on public.shoot_reports;
drop policy if exists "撮影報告の更新は本人のみ" on public.shoot_reports;
drop policy if exists "撮影報告の削除は本人のみ" on public.shoot_reports;

create policy "撮影報告は誰でも閲覧可" on public.shoot_reports
  for select using (true);
create policy "撮影報告の登録は本人のみ" on public.shoot_reports
  for insert with check (auth.uid() = poster_id);
create policy "撮影報告の更新は本人のみ" on public.shoot_reports
  for update using (auth.uid() = poster_id);
create policy "撮影報告の削除は本人のみ" on public.shoot_reports
  for delete using (auth.uid() = poster_id);

-- ------------------------------------------------------------
-- 3. delete_my_account() の差し替え（costume_exchanges → shoot_reports）
-- ------------------------------------------------------------
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  delete from public.hub_votes where voter_id = auth.uid();
  delete from public.feature_votes where voter_id = auth.uid();
  delete from public.hub_requests where requester_id = auth.uid();
  delete from public.feature_requests where requester_id = auth.uid();
  delete from public.hub_configs where created_by = auth.uid();

  delete from public.community_members where user_id = auth.uid();
  delete from public.event_participants where user_id = auth.uid();
  delete from public.chat_room_members where user_id = auth.uid();
  delete from public.join_applications where applicant_id = auth.uid();
  delete from public.recruitments where host_id = auth.uid();
  delete from public.communities where owner_id = auth.uid();
  delete from public.categories where created_by = auth.uid();
  delete from public.blocks where blocker_id = auth.uid() or blocked_id = auth.uid();
  delete from public.reports where reporter_id = auth.uid();
  delete from public.catch_reports where reporter_id = auth.uid();
  delete from public.protected_dogs where reporter_id = auth.uid();
  delete from public.protected_cats where reporter_id = auth.uid();
  delete from public.shoot_reports where poster_id = auth.uid();
  delete from public.parts_exchanges where poster_id = auth.uid();
  delete from public.gear_exchanges where poster_id = auth.uid();
  delete from public.instrument_exchanges where poster_id = auth.uid();
  delete from public.bath_goods_exchanges where poster_id = auth.uid();
  delete from public.sports_goods_exchanges where poster_id = auth.uid();
  delete from public.mahjong_goods_exchanges where poster_id = auth.uid();
  delete from public.game_goods_exchanges where poster_id = auth.uid();
  delete from public.profiles where id = auth.uid();

  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

commit;
