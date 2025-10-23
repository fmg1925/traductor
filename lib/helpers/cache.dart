import 'dart:async';

class _CacheEntry<T> {
  _CacheEntry(this.value, this.expiresAt);
  final T value;
  final DateTime? expiresAt;
  bool get isFresh => expiresAt == null ||
      DateTime.now().isBefore(expiresAt!);
}

class RequestLimiter {
  RequestLimiter({
    this.minGap = const Duration(milliseconds: 800),
    this.timeout = const Duration(seconds: 15),
    this.cacheTtl = const Duration(seconds: 10),
  });

  final Duration minGap;
  final Duration timeout;
  final Duration cacheTtl;

  final _inflight = <String, Future<dynamic>>{};
  final _lastHitPerKey = <String, DateTime>{};
  final _cache = <String, _CacheEntry<dynamic>>{};

  Future<T> run<T>(String key, Future<T> Function() op, {bool cache = false}) async {
    if (cache) {
      final c = _cache[key];
      if (c != null && c.isFresh) return c.value as T;
    }

    final existing = _inflight[key];
    if (existing != null) return existing as Future<T>;

    final last = _lastHitPerKey[key] ?? DateTime.fromMillisecondsSinceEpoch(0);
    final wait = last.add(minGap).difference(DateTime.now());
    if (wait.inMilliseconds > 0) {
      await Future.delayed(wait);
    }

    final future = op().timeout(timeout);
    _inflight[key] = future;

    try {
      final result = await future;
      if (cache) {
        final expiry = cacheTtl == Duration.zero
            ? null
            : DateTime.now().add(cacheTtl);
        _cache[key] = _CacheEntry<T>(result, expiry);
      }
      return result;
    } finally {
      _inflight.remove(key);
      _lastHitPerKey[key] = DateTime.now();
    }
  }
}
