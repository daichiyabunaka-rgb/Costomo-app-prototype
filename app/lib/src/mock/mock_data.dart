import 'dart:math' as math;

import '../models.dart';

/// モックユーザーは「anchor（中心点）からの相対距離」で配置する。
/// anchor には実 GPS で取得した現在地が入り、どこにいても近くのコスとも候補が並ぶ。
class _MockSpec {
  final String id;
  final String nickname;
  final String decade;
  final String gender;
  final String iconCategoryId;
  final List<String> interestIds;
  final String bio;
  final double northKm; // anchor からの北方向距離
  final double eastKm; // anchor からの東方向距離

  const _MockSpec(this.id, this.nickname, this.decade, this.gender,
      this.iconCategoryId, this.interestIds, this.bio, this.northKm,
      this.eastKm);
}

const List<_MockSpec> _specs = [
  _MockSpec(
    'u-anime-rei',
    'アニメコスのれい',
    '20代',
    'female',
    'anime',
    ['anime', 'photo', 'edit'],
    '週末は撮影会に出かけるのが楽しみ。加工も自分でやります。初コスから3年目。',
    0.6,
    0.2,
  ),
  _MockSpec(
    'u-game-yuta',
    'ゲームコスのゆうた',
    '20代',
    'male',
    'game',
    ['game', 'photo', 'event'],
    'FPSとRPGのコスを交互にやっています。イベントは年4回くらい参加。',
    -0.3,
    -0.1,
  ),
  _MockSpec(
    'u-comic-nana',
    '漫画コスのなな',
    '10代',
    'female',
    'comic',
    ['comic', 'anime', 'wigmaking'],
    'ジャンプ系の漫画が好き。ウィッグは自分でセットする派です。',
    0.15,
    -0.4,
  ),
  _MockSpec(
    'u-tokusatsu-sora',
    '特撮好きのそら',
    '30代',
    'undisclosed',
    'tokusatsu',
    ['tokusatsu', 'photo', 'dance'],
    'ヒーローもののコス歴10年。スーツのメンテも自分でやります。',
    -0.7,
    0.5,
  ),
  _MockSpec(
    'u-vtuber-miu',
    'ぼいちょコスのみう',
    '20代',
    'female',
    'vtuber',
    ['vtuber', 'vocaloid', 'edit'],
    '配信者のコスをよくやります。衣装は既製品派です。',
    1.2,
    -0.9,
  ),
  _MockSpec(
    'u-vocaloid-kei',
    'ボカロコスのけい',
    '20代',
    'undisclosed',
    'vocaloid',
    ['vocaloid', 'dance', 'photo'],
    'ボカロ曲のコス動画撮影が趣味。ダンスの練習もしています。',
    -1.1,
    1.0,
  ),
  _MockSpec(
    'u-wigmaya-hina',
    ' wig自作のひな',
    '30代',
    'female',
    'wigmaking',
    ['wigmaking', 'anime', 'event'],
    'ウィッグを自分でくり抜いてスタイリングしています。自作衣装も少数制作。',
    0.9,
    0.35,
  ),
  _MockSpec(
    'u-photo-kyo',
    '撮影担当のきょう',
    '40代',
    'male',
    'photo',
    ['photo', 'edit', 'event'],
    'コスプレ撮影のカメラ担当です。撮る側もやる側も両方やります。',
    0.45,
    -1.3,
  ),
];

class _BusinessSpec {
  final String id;
  final String nickname;
  final String iconCategoryId;
  final String storeType;
  final String bio;
  final double northKm;
  final double eastKm;

  const _BusinessSpec(this.id, this.nickname, this.iconCategoryId,
      this.storeType, this.bio, this.northKm, this.eastKm);
}

const List<_BusinessSpec> _businessSpecs = [
  _BusinessSpec(
    'b-studio-kira',
    'スタジオ キラキラ',
    'photo',
    'フォトスタジオ',
    'コスプレ撮影向けのスタジオ。背景紙とライティング常設。撮影パックも好評です。',
    0.8,
    0.9,
  ),
  _BusinessSpec(
    'b-wig-atelier',
    'ウィッグアトリエ ふわふわ',
    'wigmaking',
    'ウィッグ・衣装制作',
    'オーダーメイドウィッグと衣装の工房。イベント前の込み込みもご相談ください。',
    -0.5,
    1.1,
  ),
  _BusinessSpec(
    'b-edit-cafe',
    'レタッチカフェ',
    'edit',
    '撮影・レタッチ',
    '撮影と現像・レタッチまでまとめて頼めるお店。簡単な加工から凝った作画まで。',
    1.5,
    -0.6,
  ),
  _BusinessSpec(
    'b-event-hall',
    'イベントホール サクラ',
    'event',
    'イベント会場',
    '小規模コスプレイベントや撮影会を開催するレンタルスペース運営です。',
    -1.4,
    -0.8,
  ),
];

const double _kmPerDegLat = 111.32;

AppUser _specToUser(_MockSpec s, double anchorLat, double anchorLng) {
  final cos =
      math.cos(anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return AppUser(
    id: s.id,
    nickname: s.nickname,
    decade: s.decade,
    gender: s.gender,
    iconCategoryId: s.iconCategoryId,
    interestIds: s.interestIds,
    bio: s.bio,
    lat: anchorLat + s.northKm / _kmPerDegLat,
    lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
  );
}

BusinessUser _specToBusiness(
    _BusinessSpec s, double anchorLat, double anchorLng) {
  final cos =
      math.cos(anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return BusinessUser(
    id: s.id,
    nickname: s.nickname,
    decade: '経営者',
    gender: 'undisclosed',
    iconCategoryId: s.iconCategoryId,
    interestIds: const [],
    bio: s.bio,
    lat: anchorLat + s.northKm / _kmPerDegLat,
    lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
    storeType: s.storeType,
  );
}

/// 現在地を中心にモックユーザー（一般 + ビジネス）を配置する。
List<AppUser> buildMockUsers(double anchorLat, double anchorLng) {
  return [
    for (final s in _specs) _specToUser(s, anchorLat, anchorLng),
    for (final s in _businessSpecs) _specToBusiness(s, anchorLat, anchorLng),
  ];
}

/// シード募集（起動時刻からの残り時間で作るので、いつ開いても「今から」感が出る）。
/// host は generalUsers（モック一般ユーザー）から id で引く。
List<Recruitment> seedRecruitments(DateTime now, List<AppUser> generalUsers) {
  Recruitment make({
    required String hostId,
    required String genreId,
    required String title,
    required String body,
    required String meetup,
    required int capacity,
    required int minutesLeft,
  }) {
    return Recruitment(
      id: 'r-$hostId',
      hostId: hostId,
      genreId: genreId,
      title: title,
      body: body,
      meetup: meetup,
      capacity: capacity,
      createdAt: now.subtract(const Duration(minutes: 15)),
      expiresAt: now.add(Duration(minutes: minutesLeft)),
      memberIds: [hostId],
    );
  }

  return [
    make(
      hostId: 'u-anime-rei',
      genreId: 'shooting',
      title: '今から駅前の公園で撮影会しませんか',
      body: 'アニメのコスで撮影にきました。カメラさんと撮れる方を探しています。初心者も歓迎。',
      meetup: '中央公園 噴水前',
      capacity: 3,
      minutesLeft: 105,
    ),
    make(
      hostId: 'u-game-yuta',
      genreId: 'event',
      title: '次のイベント、合同でサークル参加しませんか',
      body: 'ゲーム系のコスでサークル参加できる方を探しています。打ち合わせもしたいです。',
      meetup: 'イベント待合スペース',
      capacity: 3,
      minutesLeft: 70,
    ),
    make(
      hostId: 'u-photo-kyo',
      genreId: 'shooting',
      title: '日曜午後、撮り手募集しています',
      body: '撮影場所の近くで誰か撮ってくれる方いませんか。データは後日お渡しします。',
      meetup: 'リバーサイド公園 駐車場',
      capacity: 4,
      minutesLeft: 160,
    ),
    make(
      hostId: 'u-vtuber-miu',
      genreId: 'exchange',
      title: '配信見ながら雑談しませんか',
      body: '推し配信の同時視聴会をやります。まったり雑談できる方、大歓迎です。',
      meetup: '近くのファミレス',
      capacity: 2,
      minutesLeft: 95,
    ),
    make(
      hostId: 'u-vocaloid-kei',
      genreId: 'exchange',
      title: 'ダンス練習の練習相手を探しています',
      body: 'ボカロ曲のコスでダンスを練習中。一緒に練習できる方だ嬉しいです。',
      meetup: '公共の練習スペース',
      capacity: 4,
      minutesLeft: 130,
    ),
    make(
      hostId: 'u-wigmaya-hina',
      genreId: 'event',
      title: '次のイベント、合同で参加しませんか',
      body: '衣装・ウィッグの相談もできるので初めての方も安心です。',
      meetup: '会場最寄り駅',
      capacity: 3,
      minutesLeft: 45,
    ),
  ];
}

/// ゆずりあい・交換のシード。anchor（現在地）からの相対距離で配置する。
/// id が 'cx-seed-' 始まりのものは GPS 更新のたびに再配置される
/// （AppState.applyGps を参照）。
class _ExchangeSeedSpec {
  final String id;
  final String posterId;
  final String kind;
  final String itemDescription;
  final String areaName;
  final String detail;
  final double northKm;
  final double eastKm;
  final Duration age;
  const _ExchangeSeedSpec(this.id, this.posterId, this.kind,
      this.itemDescription, this.areaName, this.detail, this.northKm,
      this.eastKm, this.age);
}

const List<_ExchangeSeedSpec> _exchangeSeedSpecs = [
  _ExchangeSeedSpec(
    'cx-seed-1',
    'u-comic-nana',
    'give',
    '○○の学生服（男子M・タグ付き・着用2回）',
    '中央公園 周辺',
    'サイズが合わなくなってしまったので、'
        '使ってくださる方にゆずります。イベント会場での受け渡しもOKです。',
    0.3,
    -0.6,
    Duration(hours: 2),
  ),
  _ExchangeSeedSpec(
    'cx-seed-2',
    'u-anime-rei',
    'wanted',
    '○○の戦闘服（女子L・フルセット）を探しています',
    '駅東側のイベント会場',
    '来月のイベントで着たいです。お譲りできる方に'
        '交換での対応も可能です。DMお待ちしています。',
    -0.2,
    0.8,
    Duration(hours: 5),
  ),
  _ExchangeSeedSpec(
    'cx-seed-3',
    'u-tokusatsu-sora',
    'trade',
    '特撮ヒーローのスーツ（自作・着用1回）と交換します',
    '河川敷リバーサイド公園 周辺',
    '別のキャラのスーツと交換希望です。状態は写真で'
        '送ります。場所はイベント会場が多いです。',
    -0.9,
    -0.3,
    Duration(hours: 26),
  ),
];

List<CostumeExchange> buildSeedCostumeExchanges(
    DateTime now, double anchorLat, double anchorLng) {
  final cos = (anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return [
    for (final s in _exchangeSeedSpecs)
      CostumeExchange(
        id: s.id,
        posterId: s.posterId,
        kind: s.kind,
        itemDescription: s.itemDescription,
        areaName: s.areaName,
        detail: s.detail,
        lat: anchorLat + s.northKm / _kmPerDegLat,
        lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
        createdAt: now.subtract(s.age),
      ),
  ];
}

/// モックの返信候補（デモの自動応答に使う。本開発では Supabase Realtime に置換）
const List<String> mockReplies = [
  'よろしくお願いします！',
  '撮影の写真、楽しみです。',
  '先に着いて場所を取っておきますね。',
  'この撮影スポットずっと気になっていました。',
];

/// モックの応募メッセージ
const List<String> mockApplyMessages = [
  '参加したいです！撮影仲間を探していました。',
  '同じ作品のコスをやっているので嬉しいです。',
  'この近くによく撮影に来ています。',
];
