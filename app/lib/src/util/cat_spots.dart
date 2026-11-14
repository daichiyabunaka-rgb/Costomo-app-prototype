import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'format.dart';

/// 「近くの撮影スポットを探す」機能のデータ層。
/// OpenStreetMap の Overpass API で現在地周辺の
/// **撮影に使える公共の場所・イベント会場**を取得する。
/// - 公園（leisure=park）: フリーで使える撮影ロケとして定番
/// - 神社・お寺（amenity=place_of_worship）: 和装・時代物の定番ロケ
///   ※境内での撮影は事前に社務所・管理者の許可を必ず確認すること
/// - イベント会場・ホール（amenity=events_venue / arts_centre /
///   exhibition_centre / theatre）
/// - フォトスタジオ（craft=photographer）は後日ヒット数を見てから
///   加味する（現在は対象外）
/// - nodes/waysのみ取得（relationsを含むbboxクエリは重すぎて各サーバーが
///   502/504を返すため）
/// - 取得には30〜60秒ほどかかることがあるため、同一場所なら
///   端末内キャッシュ（約100mグリッド・30分）を優先して返す
/// 取得結果は現在地からの距離の昇順に並べる。

/// Overpass サーバー（本家は混雑しやすいので、順にフォールバックする）
const List<String> overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

const int maxSpots = 100;
const double searchRadiusKm = 5.0;
/// 一覧の1画面あたりの表示件数（スクロールで「さらに表示」）
const int spotBatchSize = 50;
/// 本家サーバーの混雑時は応答まで30〜60秒かかる
const Duration spotFetchTimeout = Duration(seconds: 60);
const Duration spotCacheTtl = Duration(minutes: 30);

/// Overpass は既定の User-Agent を持つ要求を拒否（406）するため、
/// 必ずアプリ名入り UA を送る
Map<String, String> get spotHttpHeaders => {
      'User-Agent':
          'Costomo/1.0 (Android; photo spot search; +https://github.com/daichiyabunaka-rgb/Costomo-app-prototype)',
      'Accept': 'application/json',
    };

/// Overpass API に投げるクエリ（bbox は南,西,北,東の順）
String buildOverpassQuery(double lat, double lng, {double radiusKm = searchRadiusKm}) {
  final dLat = radiusKm / 111.32;
  final cosLat = (lat * 3.1415926535897932 / 180.0).abs().clamp(0.01, 1.0);
  final dLng = radiusKm / (111.32 * cosLat);
  final south = lat - dLat;
  final west = lng - dLng;
  final north = lat + dLat;
  final east = lat + dLng;
  final bbox = '$south,$west,$north,$east';
  return '[out:json][timeout:25];'
      '('
      'node["leisure"="park"]($bbox);'
      'way["leisure"="park"]($bbox);'
      'node["amenity"="place_of_worship"]($bbox);'
      'way["amenity"="place_of_worship"]($bbox);'
      'node["amenity"~"events_venue|arts_centre|exhibition_centre|theatre"]($bbox);'
      'way["amenity"~"events_venue|arts_centre|exhibition_centre|theatre"]($bbox);'
      ');'
      'out center tags;';
}

/// 現在地周辺の撮影スポットを取得する（距離昇順）。
/// 同一地点（約100mグリッド）で30分以内の取得結果があればキャッシュを返す。
/// Overpass のサーバーに順にフォールバックし、すべて失敗したら例外を投げる。
Future<List<CatSpot>> fetchCatSpotsNear(
  double lat,
  double lng, {
  http.Client? client,
  bool forceRefresh = false,
}) async {
  final key = _cacheKey(lat, lng);
  final now = DateTime.now();
  if (!forceRefresh) {
    if (_memSpots != null &&
        _memKey == key &&
        now.isBefore(_memAt.add(spotCacheTtl))) {
      return _memSpots!;
    }
    final disk = await _loadDiskCache(key, now);
    if (disk != null) {
      _memKey = key;
      _memAt = now;
      _memSpots = disk;
      return disk;
    }
  }
  final spots = await _fetchFromOverpass(lat, lng, client ?? http.Client(),
      clientProvided: client != null);
  _memKey = key;
  _memAt = DateTime.now();
  _memSpots = spots;
  await _saveDiskCache(key, spots, _memAt);
  return spots;
}

Future<List<CatSpot>> _fetchFromOverpass(
    double lat, double lng, http.Client c,
    {required bool clientProvided}) async {
  try {
    Object? lastError;
    for (final endpoint in overpassEndpoints) {
      try {
        final res = await c
            .post(
              Uri.parse(endpoint),
              headers: spotHttpHeaders,
              body: {'data': buildOverpassQuery(lat, lng)},
            )
            .timeout(spotFetchTimeout);
        if (res.statusCode != 200) {
          throw SpotFetchException('Overpass API エラー: ${res.statusCode}');
        }
        return parseOverpassResponse(res.body, lat, lng);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? const SpotFetchException('撮影スポット情報を取得できませんでした');
  } finally {
    if (!clientProvided) c.close();
  }
}

// ------------------------------------------------------------ cache

String _cacheKey(double lat, double lng) =>
    'spots@${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

List<CatSpot>? _memSpots;
String? _memKey;
DateTime _memAt = DateTime.fromMillisecondsSinceEpoch(0);
const String _kDiskCache = 'costomo_spot_cache';

Map<String, dynamic> catSpotToMap(CatSpot s) => {
      'id': s.osmId,
      'name': s.name,
      'type': s.type,
      'lat': s.lat,
      'lng': s.lng,
      'km': s.distanceKm,
      'hours': s.openingHours,
    };

CatSpot catSpotFromMap(Map<String, dynamic> m) => CatSpot(
      osmId: m['id'] as String,
      name: m['name'] as String,
      type: m['type'] as String,
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      distanceKm: (m['km'] as num).toDouble(),
      openingHours: m['hours'] as String?,
    );

Future<List<CatSpot>?> _loadDiskCache(String key, DateTime now) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDiskCache);
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    if (m['key'] != key) return null;
    final at = DateTime.tryParse(m['at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (now.isAfter(at.add(spotCacheTtl))) return null;
    final list = (m['spots'] as List)
        .map((e) => catSpotFromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list.isEmpty ? null : list;
  } catch (_) {
    return null;
  }
}

Future<void> _saveDiskCache(String key, List<CatSpot> spots, DateTime at) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDiskCache, jsonEncode({
      'key': key,
      'at': at.toIso8601String(),
      'spots': spots.map(catSpotToMap).toList(),
    }));
  } catch (_) {
    // 保存失敗は無視（メモリキャッシュは有効）
  }
}

/// Overpass の JSON を CatSpot の一覧（距離昇順）に変換する。
/// 純関数として切り出してテストできるようにしている。
List<CatSpot> parseOverpassResponse(String body, double lat, double lng) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
    throw const SpotFetchException('不正なレスポンス形式です');
  }
  final spots = <CatSpot>[];
  for (final e in decoded['elements'] as List) {
    if (e is! Map<String, dynamic>) continue;
    final elementId = e['id'];
    if (elementId == null) continue;
    final osmType = (e['type'] as String?) ?? '';
    final tags = (e['tags'] as Map?)?.cast<String, String>() ?? const {};
    // スポット種別の判定（撮影に使える公共の場所・会場のみ）
    final rawName = tags['name'] ?? '';
    final String type;
    if (tags['leisure'] == 'park') {
      type = 'park';
    } else if (tags['amenity'] == 'place_of_worship') {
      type = 'shrine';
    } else if (tags['amenity'] == 'events_venue' ||
        tags['amenity'] == 'arts_centre' ||
        tags['amenity'] == 'exhibition_centre' ||
        tags['amenity'] == 'theatre') {
      type = 'venue';
    } else {
      continue;
    }
    // 位置: node は直接持つ。way / relation は out center で付く center を使う
    double? pLat = (e['lat'] as num?)?.toDouble();
    double? pLng = (e['lon'] as num?)?.toDouble();
    final center = e['center'];
    if (center is Map) {
      pLat = (center['lat'] as num?)?.toDouble() ?? pLat;
      pLng = (center['lon'] as num?)?.toDouble() ?? pLng;
    }
    if (pLat == null || pLng == null) continue;
    // 公園は名称が無くても表示する。それ以外は要名称
    final String? name;
    if (rawName.isNotEmpty) {
      name = rawName;
    } else if (type == 'park') {
      name = '名称未登録の公園';
    } else {
      continue;
    }
    spots.add(CatSpot(
      osmId: '$osmType/$elementId',
      name: name,
      type: type,
      lat: pLat,
      lng: pLng,
      distanceKm: haversineKm(lat, lng, pLat, pLng),
      openingHours: tags['opening_hours'],
    ));
  }
  spots.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return spots.take(maxSpots).toList(growable: false);
}

class SpotFetchException implements Exception {
  final String message;
  const SpotFetchException(this.message);
  @override
  String toString() => message;
}

/// 撮影スポットの「Googleマップで開く」URL（座標指定。迷わず正確な位置が開く）
String googleMapsUrlForSpot(CatSpot spot) {
  return 'https://www.google.com/maps/search/?api=1&query=${spot.lat},${spot.lng}';
}
