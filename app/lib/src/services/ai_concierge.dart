import '../models.dart';

/// AI接客のデモ応答ロジック（プロトタイプ用のモック）。
/// 本開発では LLM API に置き換える。このロジックは店舗業態と
/// ユーザーの興味カテゴリからおすすめを案内する最低限のルールベース。
class AiConcierge {
  /// 最初の挨拶（店舗の口調 + ユーザーの興味を踏まえる）
  String greeting(AppUser me, BusinessUser store) {
    final interest = me.interestIds.isNotEmpty ? me.interestIds.first : null;
    final label = interest == null ? null : _categoryLabel(interest);
    final base = '${_opener(store)}'
        '${me.nickname}さん、${store.nickname}（${store.storeType}）のAI接客です。';
    if (label == null) {
      return '$base コスプレのことなら何でも聞いてください。';
    }
    return '$base $labelがお好みなんですね。'
        'うちの${_recommend(store)}がおすすめです。';
  }

  /// 店舗タイプごとの口調（本開発では LLM に店舗キャラ設定を渡して生成する）
  String _opener(BusinessUser store) {
    switch (store.storeType) {
      case 'フォトスタジオ':
        return 'いらっしゃい！場所取りもお任せください。';
      case 'イベント会場':
        return 'こんにちは。撮影会・小規模イベントの会館も案内できますよ。';
      case '衣装・ウィッグ店':
        return 'いらっしゃいませ。オーダーも店舗でお直しも丁寧に承ります。';
      case '撮影・レタッチ代行':
        return 'こんにちは。納期のご相談も気軽にどうぞ。';
      default:
        return 'いらっしゃいませ。';
    }
  }

  /// ユーザー発話への応答
  String reply(String input, AppUser me, BusinessUser store) {
    final text = input.replaceAll(RegExp(r'\s'), '');
    if (text.contains('予約') || text.contains('来店')) {
      return 'ありがとうございます。土日は混み合うため、'
          '平日の午前中でしたらゆっくりご案内できます。'
          'ご希望の時間をメモしておきますね。'
          '（デモのため実際の予約機能は本開発で提供します）';
    }
    if (text.contains('おすすめ') || text.contains('オススメ')) {
      return '今回は${_recommend(store)}がおすすめです。'
          '撮影の雰囲気など希望があれば教えてください。';
    }
    if (text.contains('衣装') || text.contains('ウィッグ') ||
        text.contains('レタッチ')) {
      return '初めての方も歓迎しています。'
          'ご希望のイメージに合わせて相談しながら進めます。';
    }
    if (text.contains('料金') || text.contains('いくら') ||
        text.contains('価格')) {
      return 'ご利用内容によって変わりますが、まずは一度お試しいただけます。'
          '詳しいプランは店舗ページをご確認ください（デモの固定値です）。';
    }
    if (text.contains('何時') || text.contains('営業時間')) {
      return '本日は10:00〜18:00で営業しております。'
          '混雑しやすいのは土曜午前です。（デモの固定値です）';
    }
    if (text.contains('水') || text.contains('トイレ')) {
      return '飲水場と水洗トイレを備えています。'
          '着替えスペースもご用意していますので、ご利用ください。';
    }
    return '承知しました。「おすすめ」「料金」「営業時間」「予約」「衣装」など、'
        '気になることを聞いていただければ答えます。';
  }

  String _recommend(BusinessUser store) {
    switch (store.storeType) {
      case 'フォトスタジオ':
        return '夜間のライティング撮影プラン';
      case 'イベント会場':
        return '小規模撮影会向けの貸切プラン';
      case '衣装・ウィッグ店':
        return 'イベント前の仕上げセット';
      case '撮影・レタッチ代行':
        return '撮影からレタッチまでのパック';
      default:
        return 'おすすめサービス';
    }
  }

  String _categoryLabel(String id) {
    const labels = {
      'anime': 'アニメ',
      'game': 'ゲーム',
      'comic': '漫画・ラノベ',
      'tokusatsu': '特撮',
      'vtuber': 'VTuber',
      'vocaloid': 'ボカロ・音楽',
      'photo': 'コスプレ撮影',
      'edit': '加工・動画編集',
      'event': 'イベント参加',
      'wigmaking': 'ウィッグ・衣装制作',
      'dance': 'ダンス・コラボ',
    };
    return labels[id] ?? 'コスプレのこと';
  }
}

/// グローバルインスタンス（本開発では DI / LLM API クライアントに置き換える）
final AiConcierge aiConcierge = AiConcierge();
