import 'dart:convert';

import 'package:dio/dio.dart';
import '../models/post.dart';

class FediverseService {
  static final _dio = Dio();

  /// 使用 Mastodon API 或 WebFinger 查找账号。
  /// 输入格式：user@instance.com
  /// 如果找到，返回一个简单的 Map，包含 keys: instance, id, acct, display_name
  static Future<Map<String, dynamic>?> lookupAccount(String acct) async {
    final parts = acct.split('@');
    if (parts.length != 2) return null;
    final user = parts[0];
    final instance = parts[1];

    // 1) 尝试 Mastodon accounts lookup
    try {
      final url =
          Uri.https(instance, '/api/v1/accounts/lookup', {'acct': acct});
      final resp = await _dio.get(url.toString());
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        return {
          'type': 'mastodon',
          'instance': instance,
          'id': data['id']?.toString(),
          'acct': data['acct'] ?? acct,
          'display_name': data['display_name'] ?? data['username'] ?? acct,
          'raw': data,
        };
      }
    } catch (e) {
      // ignore and fallback to webfinger
    }

    // 2) 尝试 WebFinger (.well-known/webfinger)
    try {
      final url = Uri.https(
          instance, '/.well-known/webfinger', {'resource': 'acct:$acct'});
      final resp = await _dio.get(url.toString());
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        // 找到 actor URL
        String? actor;
        if (data['links'] is List) {
          for (final l in (data['links'] as List)) {
            if (l is Map &&
                l['rel'] == 'self' &&
                l['type'] == 'application/activity+json') {
              actor = l['href'];
              break;
            }
          }
        }
        return {
          'type': 'webfinger',
          'instance': instance,
          'acct': acct,
          'actor': actor,
          'raw': data,
        };
      }
    } catch (e) {
      // ignore
    }

    return null;
  }

  /// 对于 Mastodon 类型，尝试抓取账号的 statuses；对于 webfinger，尝试从 actor.outbox 抓取
  static Future<List<Post>> fetchAccountStatuses(
      Map<String, dynamic> accountInfo) async {
    final type = accountInfo['type'];
    if (type == 'mastodon') {
      final instance = accountInfo['instance'];
      final id = accountInfo['id'];
      if (instance == null || id == null) return [];
      final url =
          Uri.https(instance, '/api/v1/accounts/$id/statuses', {'limit': '40'});
      final resp = await _dio.get(url.toString());
      if (resp.statusCode == 200 && resp.data is List) {
        final List items = resp.data as List;
        return items.map((it) {
          final Map<String, dynamic> m = it as Map<String, dynamic>;
          return Post(
            id: m['id']?.toString() ??
                DateTime.now().microsecondsSinceEpoch.toString(),
            title: (m['content'] is String)
                ? _extractTitle(m['content'] as String)
                : '',
            body: _stripHtml(m['content'] as String? ?? ''),
            author: accountInfo['display_name'] ?? accountInfo['acct'] ?? '',
            authorId: accountInfo['acct'] ?? '',
            createdAt:
                DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
            isRemote: true,
            source: 'mastodon:${instance}',
          );
        }).toList();
      }
      return [];
    } else if (type == 'webfinger') {
      final actor = accountInfo['actor'];
      if (actor == null) return [];
      try {
        final resp = await _dio.get(actor,
            options: Options(headers: {'Accept': 'application/activity+json'}));
        if (resp.statusCode == 200) {
          final actorJson = resp.data as Map<String, dynamic>;
          final outbox = actorJson['outbox'];
          if (outbox != null) {
            final outResp = await _dio.get(outbox,
                options:
                    Options(headers: {'Accept': 'application/activity+json'}));
            if (outResp.statusCode == 200) {
              final feed = outResp.data as Map<String, dynamic>;
              final items = feed['orderedItems'] ?? feed['items'] ?? [];
              if (items is List) {
                return items.map((it) {
                  final m = it as Map<String, dynamic>;
                  final content = m['content'] is String
                      ? m['content'] as String
                      : jsonEncode(m['object'] ?? '');
                  return Post(
                    id: m['id']?.toString() ??
                        DateTime.now().microsecondsSinceEpoch.toString(),
                    title: _extractTitle(content),
                    body: _stripHtml(content),
                    author: actorJson['preferredUsername'] ??
                        accountInfo['acct'] ??
                        '',
                    authorId: actorJson['id'] ?? '',
                    createdAt: DateTime.tryParse(m['published'] ?? '') ??
                        DateTime.now(),
                    isRemote: true,
                    source: actor,
                  );
                }).toList();
              }
            }
          }
        }
      } catch (e) {
        // ignore
      }
      return [];
    }

    return [];
  }

  static String _stripHtml(String html) {
    // very simple html -> markdown-like plain text stripper for now
    return html
        .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static String _extractTitle(String content) {
    final text = _stripHtml(content).trim();
    if (text.length > 120) return text.substring(0, 120) + '...';
    return text.split('\n').first;
  }
}
