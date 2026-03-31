// TODO: add auto-eviction code to keep memory usage down
import 'dart:async';

abstract class Cache<T> {
  FutureOr<T?> get(String key);

  FutureOr<void> put(String key, T? data, [Duration? timeToLive]);

  FutureOr<void> evict(String key);

  FutureOr<void> evictExpired();

  FutureOr<void> evictAll();
}

class MemoryCache<T> implements Cache<T> {
  final Duration? _defaultTimeToLive;
  final _cache = <String, CachedItem<T>>{};

  MemoryCache([this._defaultTimeToLive]);

  @override
  T? get(String key) {
    final item = _cache[key];
    return (item != null && !item.expired) ? item.data : null;
  }

  @override
  void put(String key, T? data, [Duration? timeToLive]) {
    if (data != null) {
      _cache[key] = CachedItem<T>(data, timeToLive ?? _defaultTimeToLive);
    } else {
      evict(key);
    }
  }

  @override
  void evict(String key) {
    _cache.remove(key);
  }

  @override
  void evictExpired() {
    _cache.clear();
  }

  @override
  void evictAll() {
    _cache.clear();
  }
}

class CachedItem<T> {
  final T? data;
  final DateTime? expires;

  CachedItem(this.data, [Duration? timeToLive])
    : expires = timeToLive != null ? DateTime.now().add(timeToLive) : null;

  bool get expired => expires != null && expires!.compareTo(DateTime.now()) < 0;
}
